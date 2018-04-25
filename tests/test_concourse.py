import pathlib
import pytest
import subprocess
import time

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

    Return a `subprocess.CompletedProcess` class, representing a process that has finished.

    Examples:

    Assert that execution was successful:

        assert fly(...).returncode == 0

    Assert that execution was successful and that stdout contains something specific:

        status = fly(...)
        assert status.returncode == 0
        assert status.stdout == 'something specific'

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
                elif v in (False, None):
                    raise ValueError('option can only be True ({}={})'.format(k, v))
                else:
                    args.append('--{}={}'.format(k, v))
    return subprocess.run(args, stdout=subprocess.PIPE, timeout=timeout)


#
# Tests without `fly`
#


def test_concourse_web_is_running_and_enabled(host):
    concourse = host.service("concourse-web")
    assert concourse.is_running
    assert concourse.is_enabled


def test_concourse_worker_is_running_and_enabled(host):
    concourse = host.service("concourse-worker")
    assert concourse.is_running
    assert concourse.is_enabled


def test_minio_is_running_and_enabled(host):
    minio = host.service("minio")
    assert minio.is_running
    assert minio.is_enabled


def vm_usable_address(host):
    return host.salt('network.interface_ip', ['eth0'])


def concourse_url(host):
    return "http://localhost:8080"


def minio_url(host):
    return 'http://{}:9000'.format(vm_usable_address(host))


#
# Tests with `fly`
#


@pytest.fixture(scope='module')
def fly_login(host):
    """
    Login into Concourse at setup and logout at teardown.
    """
    assert fly('logout').returncode == 0
    user_k = 'concourse:lookup:web_auth_basic_username'
    password_k = 'concourse:lookup:web_auth_basic_password'
    creds = host.salt('pillar.item', [user_k, password_k])
    username = creds[user_k]
    password = creds[password_k]
    assert fly('login', concourse_url=concourse_url(host),
               username=username, password=password).returncode == 0
    yield
    assert fly('logout').returncode == 0


def test_fly_can_login_and_logout(fly_login):
    # test is empty because we are testing the fly_login fixture
    pass


def test_at_least_one_worker_is_available(fly_login):
    status = fly('workers')
    assert status.returncode == 0
    assert b'running' in status.stdout


def test_fly_can_execute_task_without_input(fly_login):
    assert fly('execute', config=HERE/'task-without-input.yml').returncode == 0


def test_fly_can_execute_task_with_input(fly_login):
    assert fly('execute', config=HERE/'task-with-input.yml', input='an-input=.').returncode == 0


@pytest.mark.incremental
class TestSimplePipeline(object):
    """
    The @pytest.mark.incremental means that the first failing method in this class makes all
    the remaining method fail with reason xfail.
    See https://docs.pytest.org/en/latest/example/simple.html#incremental-testing-test-steps
    """

    def test_fly_can_set_and_unpause_simple_pipeline(self, fly_login):
        pl = 'pipeline-simple'
        assert fly('set-pipeline', non_interactive=True, pipeline=pl,
                   config='{}.yml'.format(HERE/pl)).returncode == 0
        assert fly('unpause-pipeline', pipeline=pl).returncode == 0

    def test_fly_can_trigger_job_in_simple_pipeline(self, fly_login):
        pl = 'pipeline-simple'
        assert fly('trigger-job', job='{}/job-hello-world'.format(pl), watch=True).returncode == 0


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


@pytest.mark.incremental
class TestS3Pipeline(object):
    """
    The @pytest.mark.incremental means that the first failing method in this class makes all
    the remaining method fail with reason xfail.
    See https://docs.pytest.org/en/latest/example/simple.html#incremental-testing-test-steps
    """

    def test_fly_prepare_pipeline_s3(self, host, fly_login):
        pl = 'pipeline-s3'
        assert fly('set-pipeline', non_interactive=True,
                   pipeline=pl, config='{}.yml'.format(HERE/pl),
                   load_vars_from='credentials.yml').returncode == 0
        assert fly('unpause-pipeline', pipeline=pl).returncode == 0

    def test_file_uploaded_to_minio_s3_triggers_pipeline(self, host, fly_login):
        ts = time.strftime('%Y%m%d%H%M%S')
        ping = '{}-ping'.format(ts)
        pong = '{}-pong'.format(ts)
        bucket = 'channel'
        assert host_minio_put(host, bucket, ping, ts)
        # Force immediate checking of the resource to speed up the test
        assert fly('check-resource', resource='pipeline-s3/ping.s3').returncode == 0
        max_wait = 30
        poll_interval = 2
        for i in range(max_wait // poll_interval):
            if host_minio_get(host, bucket, pong):
                break
            time.sleep(poll_interval)
        assert host_minio_get(host, bucket, pong)
