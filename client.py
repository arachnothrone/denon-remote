"""
Usage: python3 client.py <cmd_code>

example:
python3 client.py 99

"""

import sys
import socket

cmd_code = sys.argv[1]

s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

s.sendto(b'CMD' + cmd_code.encode() + b'_cmdTail', ("192.168.2.101", 19001))
resp = s.recvfrom(128)
print(resp)



