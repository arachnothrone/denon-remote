"""
Usage: python3 client.py <cmd_code> [destination_address destination_port]

example:
python3 client.py 99
python3 client.py 99 127.0.0.1 55000
"""

import sys
import socket

cmd_code = int(sys.argv[1])
if len(sys.argv) >= 2:
    dest_addr = sys.argv[2]
    dest_port = int(sys.argv[3])
else:
    dest_addr = "192.168.2.101"
    dest_port = 19001

s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
for i in range(18):
    s.sendto(b'CMD' + "{:02d}".format(cmd_code).encode() + b'Description', (dest_addr, dest_port))
    resp = s.recvfrom(1280)
    print(resp)
    cmd_code += 1

