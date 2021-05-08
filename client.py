import socket

s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

s.sendto(b'requesting stuff', ("192.168.2.101", 19001))
resp = s.recvfrom(128)
print(resp)



