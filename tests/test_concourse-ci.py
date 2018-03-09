# vagrant ssh-config > ssh-config.tmp
# py.test --verbose --hosts=concourse-formula --ssh-config=ssh-config.tmp

import subprocess as proc
import shlex
import pytest

# We use a custom fly target to be sure that running the tests doesn't have
# an impact on the user interactions with this Concourse installation.
FLY = 'fly -t ci-automatic-target'


def test_concourse_web_is_running_and_enabled(host):
    concourse = host.service("concourse-web")
    assert concourse.is_running
    assert concourse.is_enabled


def test_concourse_worker_is_running_and_enabled(host):
    concourse = host.service("concourse-worker")
    assert concourse.is_running
    assert concourse.is_enabled


def concourse_url(host):
    # FIXME Ugly I know
    for addr in host.salt("network.ip_addrs"):
        if not addr.startswith('10.'):
            return 'http://{}:8080'.format(addr)
    return None


def test_can_get_valid_concourse_url(host):
    assert concourse_url(host)


@pytest.fixture
def fly_login(host):
    assert proc.run(shlex.split("{} logout".format(FLY)), timeout=5).returncode == 0
    addr = concourse_url(host)
    # FIXME I would like to get the credentials from map.jija/pillars but I don't know how
    assert proc.run(shlex.split("{} login -c {} -u concourse -p concourse".format(FLY, addr)),
                    timeout=5).returncode == 0
    yield
    assert proc.run(shlex.split("{} logout".format(FLY)), timeout=5).returncode == 0


def test_fly_can_login_and_logout(host, fly_login):
    # test is empty because we are testing the fly_login fixture
    pass


def test_fly_can_execute_task_with_input(host, fly_login):
    # timeout is longer here because it could require download of a Docker image
    assert proc.run(shlex.split("{} execute -c task.yml -i an-input=.".format(FLY)),
                    timeout=30).returncode == 0
