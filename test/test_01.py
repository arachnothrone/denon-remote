import test_platform as tp
import concurrent.futures
import time
import pytest


def test_SERVER_START_STOP():
    '''
    Start server and wait for shutdown command
    '''

    # Perform cleanup in case of anything running
    out, err = tp.cleanup_environment(["rpi_ag.out", "client.py"])
    tp.log_output(None, None, out, err)
    time.sleep(2)

    server_command = ["../rpi_ag.out"]
    server_args = ["-h 19", "-m 20", "-s 22", "-v -42"]

    client_command = ["python3", "../client.py"]
    cliargs = ["CMD88SHUTDOWN", "127.0.0.1", "19001"]

    # Create a ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        # Submit the task to run the process
        future1 = executor.submit(tp.run_command, server_command, server_args)
        future2 = executor.submit(tp.run_command, client_command, cliargs, delay=3)

        # Wait for all tasks to complete
        concurrent.futures.wait([future1, future2], timeout=60, return_when='ALL_COMPLETED')

        # Get the result from the future
        stdout1, stderr1 = future1.result()
        stdout2, stderr2 = future2.result()

    for stdout, stderr in [(stdout1, stderr1), (stdout2, stderr2)]:
        tp.log_output(None, None, stdout, stderr)

    assert "Starting IR server" in stdout1.decode()
    assert "Response sent: 0,-42,0,2,0,0,1" in stdout1.decode()

    # Check client received response from server
    assert "0,-42,0,2,0,0,1" in stdout2.decode()

# @pytest.mark.skip(reason="Not implemented")
def test_SERVER_START_AFTER_APO_TIME_WITH_APO_ENABLED():
    '''
    Start the server with APO time past current time,
    send POWERON command and check if power is being switched OFF
    '''

    # Cleanup
    out, err = tp.cleanup_environment(["rpi_ag.out", "client.py"])
    tp.log_output(None, None, out, err)
    time.sleep(2)

    # get local environment time
    hours, _, _ = tp.get_local_time()

    # Start 1 hour past APO time
    server_command = ["../rpi_ag.out"]
    server_args = [f"-h {hours - 1}", "-m 20", "-s 22", "-v -42"]

    client_command = ["python3", "../client.py"]
    cliargs_a = ["CMD04POWERON", "127.0.0.1", "19001"]
    cliargs_b = ["CMD88SHUTDOWN", "127.0.0.1", "19001"]

    # First thread for server, second for client command "CMD04POWERON", 3rd - client with "CMD88SHUTDOWN"
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        # Submit the task to run the process
        future1 = executor.submit(tp.run_command, server_command, server_args)
        future2 = executor.submit(tp.run_command, client_command, cliargs_a, delay=3)
        future3 = executor.submit(tp.run_command, client_command, cliargs_b, delay=12)

        # Wait for all tasks to complete
        concurrent.futures.wait([future1, future2, future3], timeout=60, return_when='ALL_COMPLETED')

        # Get the result from the future
        stdout1, stderr1 = future1.result()
        stdout2, stderr2 = future2.result()
        stdout3, stderr3 = future3.result()

    for stdout, stderr in [(stdout1, stderr1), (stdout2, stderr2), (stdout3, stderr3)]:
        tp.log_output(None, None, stdout, stderr)

    # Current time in shutdown string, check hours only
    assert f"Automatic Switch Off ({hours}-" in stdout1.decode()

    # Power On request
    assert "Response sent: 1,-42,0,2,0,0,1" in stdout1.decode()

    # Shutdown request
    assert "Response sent: 0,-42,0,2,0,0,1" in stdout1.decode()

    # Check client thread 'CMD04POWERON' received response from server
    assert "1,-42,0,2,0,0,1" in stdout2.decode()

    # Check client 'CMD88SHUTDOWN' received response from server
    assert "0,-42,0,2,0,0,1" in stdout3.decode()


@pytest.mark.skip(reason="Not implemented")
def test_SERVER_START_BEFORE_APO_TIME_WITH_APO_DISABLED():
    '''
    Start the server with APO time before current time,
    send POWERON command and check if the power is ON
    '''
    pass