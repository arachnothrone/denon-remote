import subprocess
import os
import signal

def start_environment(binary_path, args):
    try:
        # Start server
        server_process = subprocess.Popen([binary_path] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Wait for the server to shutdown, get the output and error messages
        stdout, stderr = server_process.communicate()
        return stdout, stderr

    except Exception as e:
        print("Error:", str(e))
        return str(e), ''
    
    return stdout, stderr
