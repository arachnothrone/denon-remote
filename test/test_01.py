import test_platform as tp
import concurrent.futures
import time
import datetime
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


def test_SERVER_START_AFTER_APO_TIME_WITH_APO_ENABLED():
    '''
    Start the server with APO time past current time,
    send POWERON command and check if power is being switched OFF
    Test 3 tims with minutes offset -1, 0, 1 (one min before/no diff/after)
    '''

    # Cleanup
    out, err = tp.cleanup_environment(["rpi_ag.out", "client.py"])
    tp.log_output(None, None, out, err)
    time.sleep(2)

    # Start 1 hour past APO time
    server_command = ["../rpi_ag.out"]

    client_command = ["python3", "../client.py"]
    cliargs_a = ["CMD04POWERON", "127.0.0.1", "19001"]
    cliargs_b = ["CMD88SHUTDOWN", "127.0.0.1", "19001"]

    for m_offset in [-1, 0, 1]:
        hours, minutes, seconds = tp.get_local_time()
    
        # Adjust to the next minute if too far into the current
        if seconds > 25:
            time.sleep(60 - seconds)
            minutes += 1
    
        server_args = [f"-h {hours - 1}", f"-m {minutes + m_offset}", "-s 11", "-v -42"]

        print(datetime.datetime.now(), f"Testing with minutes offset = {m_offset} (APO time: {hours - 1}:{minutes + m_offset}:11)")

        # First thread for server, second for client command "CMD04POWERON", 3rd - client with "CMD88SHUTDOWN"
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            # Submit the task to run the process
            future1 = executor.submit(tp.run_command, server_command, server_args)
            future2 = executor.submit(tp.run_command, client_command, cliargs_a, delay=3)
            future3 = executor.submit(tp.run_command, client_command, cliargs_b, delay=6)

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

        print(datetime.datetime.now(), "-" * 53)


# @pytest.mark.skip(reason="Not implemented")
def test_SERVER_START_AFTER_APO_TIME_WITH_APO_DISABLED():
    '''
    Start the server with APO past current time, send APO disable (CMD41AUTOPWROFF0)
    then POWERON command and check if the power is still ON (server should ignore APO time)
    '''

    # Cleanup
    out, err = tp.cleanup_environment(["rpi_ag.out", "client.py"])
    tp.log_output(None, None, out, err)
    time.sleep(2)

    # Start 1 hour past APO time
    server_command = ["../rpi_ag.out"]

    client_command = ["python3", "../client.py"]
    cliargs_a = ["CMD41AUTOPWROFF0", "127.0.0.1", "19001"]
    cliargs_b = ["CMD04POWERON", "127.0.0.1", "19001"]
    cliargs_c = ["CMD88SHUTDOWN", "127.0.0.1", "19001"]

    for m_offset in [-1, 0, 1]:
        hours, minutes, seconds = tp.get_local_time()

        # Adjust to the next minute if too far into the current
        if seconds > 25:
            time.sleep(60 - seconds)
            minutes += 1
    
        server_args = [f"-h {hours - 1}", f"-m {minutes + m_offset}", "-s 11", "-v -42"]

        print(datetime.datetime.now(), f"Testing with minutes offset = {m_offset} (APO time: {hours - 1}:{minutes + m_offset}:11)")

        # First thread for server, 2 - "CMD41AUTOPWROFF0" command, 3 - "CMD04POWERON", 4 - "CMD88SHUTDOWN"
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            # Submit the task to run the process
            future1 = executor.submit(tp.run_command, server_command, server_args)
            future2 = executor.submit(tp.run_command, client_command, cliargs_a, delay=3)
            future3 = executor.submit(tp.run_command, client_command, cliargs_b, delay=6)
            future4 = executor.submit(tp.run_command, client_command, cliargs_c, delay=9)

            # Wait for all tasks to complete
            concurrent.futures.wait([future1, future2, future3, future4], timeout=60, return_when='ALL_COMPLETED')

            # Get the result from the future
            stdout1, stderr1 = future1.result()
            stdout2, stderr2 = future2.result()
            stdout3, stderr3 = future3.result()
            stdout4, stderr4 = future4.result()

        for stdout, stderr in [(stdout1, stderr1), (stdout2, stderr2), (stdout3, stderr3), (stdout4, stderr4)]:
            tp.log_output(None, None, stdout, stderr)

        # Server didn't try to turn off the power
        assert f"Automatic Switch Off" not in stdout1.decode()

        # Server received CMD41AUTOPWROFF0 request
        assert "Response sent: 0,-42,0,2,0,0,0" in stdout1.decode()

        # Server received CMD04POWERON requiest
        assert "Response sent: 1,-42,0,2,0,0,0" in stdout1.decode()

        # Server received CMD88SHUTDOWN request
        assert "Response sent: 1,-42,0,2,0,0,0" in stdout1.decode()

        # Check client thread 'CMD41AUTOPWROFF0' received response from server
        assert "0,-42,0,2,0,0,0" in stdout2.decode()

        # Check client thread 'CMD04POWERON' received response from server
        assert "1,-42,0,2,0,0,0" in stdout3.decode()

        # Check client 'CMD88SHUTDOWN' received response from server
        assert "1,-42,0,2,0,0,0" in stdout4.decode()

        print(datetime.datetime.now(), "-" * 53)
