import test_platform as tp
import concurrent.futures

def test_SERVER_START_STOP():
    '''
    Start server and wait for shutdown command
    '''

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
        concurrent.futures.wait([future1, future2], timeout=None, return_when='ALL_COMPLETED')

        # Get the result from the future
        stdout1, stderr1 = future1.result()
        stdout2, stderr2 = future2.result()

    for stdout, stderr in [(stdout1, stderr1), (stdout2, stderr2)]:
        # Print the output
        if stdout:
            print("Process Output:", stdout)
        if stderr:
            print("Process Error:", stderr)

    assert "Starting IR server" in stdout1.decode()
    assert "Response sent: 0,-42,0,2,0,0,1" in stdout1.decode()

    # Check client received response from server
    assert "0,-42,0,2,0,0,1" in stdout2.decode()
    