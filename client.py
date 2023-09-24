"""
Usage: python3 client.py <cmd_code> [destination_address destination_port]
"""

import sys
import socket

USAGE = "USAGE:   python3 client.py <cmdCode> [<serverAddr> <serverPort>]\n" \
        "example: python3 client.py CMD04_PWR_ON 127.0.0.1 55000\n" \
        "         python3 client.py CMD04_PWR_ON\n" \
        "         python3 client.py CMD18INCREASEVOL05 127.0.0.1 19001\n"

if len(sys.argv) < 2:
    sys.exit(USAGE)

cmd_code = sys.argv[1]   # int(sys.argv[1])

if len(sys.argv) >= 2:
    dest_addr = sys.argv[2]
    dest_port = int(sys.argv[3])
else:
    dest_addr = "192.168.2.101"
    dest_port = 19001

s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
for i in range(1):
    s.sendto("{}".format(cmd_code).encode(), (dest_addr, dest_port))
    resp = s.recvfrom(1280)
    print(resp)

