import pathlib
import subprocess
import time
import pytest

HERE = pathlib.Path(__file__).parent


def fly(cmd, **kwargs):
    """
    - Execute the `fly` utility with command `cmd` and with each keyword argument in `kwargs`
      transformed in options of the form `--key==value`.
    - In case the option to pass to fly contains an hyphen (eg `concourse-url`), you need
      to replace it by an underscore (eg `concourse_url`), since Python keywords cannot
      contain hyphens. The code will transform the underscore back to an hyphen.
    - In case the option is a flag (key only, not value), pass it as `flag=True`. Note that
      `flag=False` doesn't mean anything and will raise.
    - In case `value` is a list, tranform  the list in the form
      `--key=value1` ... `--key=valueN`, always with the same `key`.
    - The reserved key `_timeout_`, if present, is passed as the `timeout` value to
      `subprocess.run()`.

    For example,

        fly('execute', config='task.yml', input='an-input=.')

    will be executed with a command-line of:

        fly --target=ci-automatic-target execute --config=task.yml --input=an-input=.

    Return True if the execution of `fly` has been successful, False otherwise.

    We use a custom fly target (`ci-automatic-target`) to be sure that running the tests
    doesn't have an impact on the user interactions with this Concourse installation, since
    fly stores login state per user.
    """
    args = ['fly', '--target=ci-automatic-target', cmd]
    timeout = 60
    for k, v in kwargs.items():
        if k == '_timeout_':
            timeout = v
        else:
            k = k.replace('_', '-')
            if isinstance(v, (list, tuple)):
                for v2 in v:
                    args.append('--{}={}'.format(k, v2))
            else:
                if v is True:
                    args.append('--{}'.format(k))
                elif v is False:
                    raise ValueError('option cannot be False ({} {})'.format(k, v))
                else:
                    args.append('--{}={}'.format(k, v))
    return subprocess.run(args, timeout=timeout).returncode == 0


@pytest.fixture(scope='module')
def fly_login(host):
    """
    Login into Concourse at setup and logout at teardown.
    """
    assert fly('logout')
    addr = concourse_url(host)
    user_k = 'concourse:lookup:web_auth_basic_username'
    password_k = 'concourse:lookup:web_auth_basic_password'
    creds = host.salt('pillar.item', [user_k, password_k])
    username = creds[user_k]
    password = creds[password_k]
    assert fly('login', concourse_url=addr, username=username, password=password)
    yield
    assert fly('logout')


def test_concourse_web_is_running_and_enabled(host):
    concourse = host.service("concourse-web")
    assert concourse.is_running
    assert concourse.is_enabled


def test_concourse_worker_is_running_and_enabled(host):
    concourse = host.service("concourse-worker")
    assert concourse.is_running
    assert concourse.is_enabled


def concourse_url(host):
    # FIXME INT-1419
    for addr in host.salt("network.ip_addrs"):
        if not addr.startswith('10.'):
            return 'http://{}:8080'.format(addr)
    return None


def test_can_get_valid_concourse_url(host):
    assert concourse_url(host)


def test_fly_can_execute_task_with_input(fly_login):
    assert fly('execute', config='{}/task.yml'.format(HERE), input='an-input={}'.format(HERE))


# TODO move in fixture
def test_fly_can_set_and_unpause_simple_pipeline(fly_login):
    pl = 'pipeline-1'
    assert fly('set-pipeline', non_interactive=True, pipeline=pl, config='{}.yml'.format(HERE/pl))
    assert fly('unpause-pipeline', pipeline=pl)


def test_fly_can_trigger_job_in_simple_pipeline(fly_login):
    pl = 'pipeline-1'
    assert fly('trigger-job', job='{}/job-hello-world'.format(pl), watch=True)


def host_minio_put(host, bucket, fname, contents):
    endpoint = 'minio'
    cmd = 'echo "{}" | /opt/minio/mc pipe {}/{}/{}'.format(contents, endpoint, bucket, fname)
    return host.run(cmd).rc == 0


def host_minio_get(host, bucket, fname):
    endpoint = 'minio'
    cmd = '/opt/minio/mc cp {}/{}/{} /tmp/'.format(endpoint, bucket, fname)
    return host.run(cmd).rc == 0


def test_can_put_and_get_file_in_minio_s3(host):
    fname = 'test-{}'.format(time.strftime('%Y%m%d%H%M%S'))
    bucket = 'test'
    assert host_minio_put(host, bucket, fname, 'hello!')
    assert host_minio_get(host, bucket, fname)


# TODO move in fixture
def test_fly_prepare_pipeline_2(fly_login):
    pl = 'pipeline-2'
    assert fly('set-pipeline', non_interactive=True,
               pipeline=pl, config='{}.yml'.format(HERE/pl),
               var=('s3-access-key-id=CHANGEME-b8e46114a7f64561',
                    's3-secret-access-key=CHANGEME-05ba7d7c95362608',
                    'minio-endpoint=http://192.168.50.4:9000'))
    assert fly('unpause-pipeline', pipeline=pl)


def test_file_uploaded_to_minio_s3_triggers_pipeline(host, fly_login):
    ts = time.strftime('%Y%m%d%H%M%S')
    ping = '{}-ping'.format(ts)
    pong = '{}-pong'.format(ts)
    bucket = 'channel'
    assert host_minio_put(host, bucket, ping, ts)
    # Force immediate checking of the resource to speed up
    assert fly('check-resource', resource='pipeline-2/ping.s3')
    max_wait = 30
    poll_interval = 2
    for i in range(max_wait // poll_interval):
        if host_minio_get(host, bucket, pong):
            break
        time.sleep(poll_interval)
    assert host_minio_get(host, bucket, pong)
