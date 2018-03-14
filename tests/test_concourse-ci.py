import subprocess
import pytest


# We use a custom fly target to be sure that running the tests doesn't have
# an impact on the user interactions with this Concourse installation.
def fly(args, timeout=5):
    return subprocess.run(['fly', '-t', 'ci-automatic-target'] + args, timeout)


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


@pytest.fixture
def fly_login(host):
    assert fly(['logout']).returncode == 0
    addr = concourse_url(host)
    user_k = "concourse:lookup:web_auth_basic_username"
    password_k = "concourse:lookup:web_auth_basic_password"
    creds = host.salt("pillar.item", [user_k, password_k])
    user = creds[user_k]
    password = creds[password_k]
    assert fly(['login', '-c', addr, '-u', user, '-p', password]).returncode == 0
    yield
    assert fly(['logout']).returncode == 0


def test_fly_can_login_and_logout(host, fly_login):
    # test is empty because we are testing the fly_login fixture
    pass


def test_fly_can_execute_task_with_input(host, fly_login):
    # timeout is longer here because it could require download of a Docker image
    assert fly(['execute', '-c', 'task.yml', '-i', 'an-input=.'], timeout=30).returncode == 0
