import subprocess
import os
import signal
import time


def run_command(command, args, delay=0):
    '''
    Waits until the process finishes and returns the output and error messages
    '''
    time.sleep(delay)

    try:
        # Invoke the process with arguments
        process = subprocess.Popen(command + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Wait for the process to finish, get the output and error messages
        stdout, stderr = process.communicate()

    except Exception as e:
        print("Error:", str(e))
        return str(e), ''

    return stdout, stderr


def run_process(command, args, delay=0):
    '''
    Returns a process object
    '''
    time.sleep(delay)

    try:
        # Invoke the process with arguments
        process = subprocess.Popen(command + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    except Exception as e:
        print("Error:", str(e))
        return str(e), ''

    return process