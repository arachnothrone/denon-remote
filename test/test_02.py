import threading
import time
import test_platform as tp


def test_POWER_ON_OFF():
    # start server
    server_command = ["../rpi_ag.out"]
    server_args = ["-h 19", "-m 20", "-s 22", "-v -42"]
    server_thread = threading.Thread(target=tp.run_process, args=(server_command, server_args))

    server_thread.start()

    client_command = ["python3", "../client.py"]
    client_args = ["127.0.0.1", "19001"]
    test_commands = ["CMD00GETSTATE", "CMD04POWERON", "CMD00GETSTATE", "CMD05POWEROFF", "CMD00GETSTATE", "CMD88SHUTDOWN"]

    # Server response: Power, Volume, Mute, StereoMode, Input, Dimmer, APOEnable
    test_responses = ["0,-42,0,2,0,0,1", "1,-42,0,2,0,0,1", "1,-42,0,2,0,0,1", "0,-42,0,2,0,0,1", "0,-42,0,2,0,0,1", "0,-42,0,2,0,0,1"]
    
    for command, response in zip(test_commands, test_responses):
        cmd_cliargs = [command] + client_args
        stdout, stderr = tp.run_command(client_command, cmd_cliargs, delay=1)

        if stdout:
            print("Process Output:", stdout)
        if stderr:
            print("Process Error:", stderr)

        assert command in stdout.decode()
        assert response in stdout.decode()

    server_thread.join()
    time.sleep(2)


def test_MUTE_TOGGLE():
    # start server
    server_command = ["../rpi_ag.out"]
    server_args = ["-h 19", "-m 20", "-s 22", "-v -42"]
    server_thread = threading.Thread(target=tp.run_process, args=(server_command, server_args))

    server_thread.start()

    client_command = ["python3", "../client.py"]
    client_args = ["127.0.0.1", "19001"]
    test_commands = ["CMD04POWERON", "CMD06MUTE", "CMD06MUTE", "CMD88SHUTDOWN"]
    test_responses = ["1,-42,0,2,0,0,1", "1,-42,1,2,0,0,1", "1,-42,0,2,0,0,1", "1,-42,0,2,0,0,1"]

    for command, response in zip(test_commands, test_responses):
        cmd_cliargs = [command] + client_args
        stdout, stderr = tp.run_command(client_command, cmd_cliargs, delay=1)

        if stdout:
            print("Process Output:", stdout)
        if stderr:
            print("Process Error:", stderr)

        assert command in stdout.decode()
        assert response in stdout.decode()

    server_thread.join()
    time.sleep(2)
    
