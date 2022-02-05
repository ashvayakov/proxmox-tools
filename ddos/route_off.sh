# ip route add blackhole 202.54.5.2/29
# ip route add blackhole from 202.54.1.2
# ip rule add blackhole to 10.18.16.1/29
# ip route


iptables -A INPUT 1 -s IPADRESS -j DROP/REJECT

