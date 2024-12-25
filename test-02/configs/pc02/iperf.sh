# Start iperf3 server in the background
# with 8 parallel tcp streams, each 200 Kbit/s == 1.6Mbit/s
# using ipv6 interfaces
iperf3 -c 192.168.1.1 -t 10000 -i 1 -p 5201 -B 172.16.2.1 -P 8 -b 200K -M 1460 &