import test_platform as tp
import concurrent.futures

def test_01_start_stop_server():
    '''
    Start server and wait for shutdown command
    '''

    binpath = "../rpi_ag.out"
    args = ["-h 19", "-m 20", "-s 22", "-v 42"]
    command = ["../rpi_ag.out", "-h 19", "-m 20", "-s 22", "-v 42"]

    # Create a ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        # Submit the task to run the process
        future = executor.submit(tp.start_environment, binpath, args)

        # Wait for the task to complete
        concurrent.futures.wait([future])

        # Get the result from the future
        stdout, stderr = future.result()

    # Print the output
    if stdout:
        print("Process Output:", stdout)
    if stderr:
        print("Process Error:", stderr)

    assert "Starting IR server" in stdout.decode()
    assert "Response sent: 0,42,0,2,0,0,1" in stdout.decode()
