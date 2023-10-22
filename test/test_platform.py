import subprocess
import os
import signal
import time


def run_command(command, args, delay=0):
    '''
    Waits until the process finishes and returns the output and error messages
    '''
    time.sleep(delay)

    # Invoke the process with arguments
    process = subprocess.Popen(command + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    # Wait for the process to finish, get the output and error messages
    stdout, stderr = process.communicate(timeout=30)

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
        return None

    return process

def cleanup_environment(proc_names):
    process = subprocess.Popen(["./kill_servers.sh"] + proc_names, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate(timeout=60)
    return stdout, stderr

def log_output(command, response, stdout, stderr):
    cmd_clause = ""
    resp_clause = ""
    main_clause = "No output"

    if command:
        cmd_clause = f"Command: {command}, "
    if response:
        resp_clause = f"expected response: {response}, "    
    if stdout:
        main_clause = f"Process Output: {stdout}"
    if stderr:
        main_clause = f"Process Error: {stderr}"

    print(f"{cmd_clause}{resp_clause}{main_clause}")
