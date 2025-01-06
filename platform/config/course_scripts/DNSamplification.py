import sys
from scapy.all import *

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python script_name.py <qname> <dns_server_ip>")
        sys.exit(1)

    # Assign arguments to variables
    qname = sys.argv[1]
    dns_server_ip = sys.argv[2]

    # Get the computer's IP address
    local_ip = get_if_addr(conf.iface)

    # Construct the DNS query
    dns_query = DNS(rd=1, qd=DNSQR(qname=qname, qtype=255), ar=DNSRROPT(rclass=4096))
    udp_packet = UDP(sport=12345, dport=53)
    ip_packet = IP(src=local_ip, dst=dns_server_ip)

    # Combine into a single packet
    packet = ip_packet / udp_packet / dns_query

    # Send the packet
    print(f"Sending DNS amplification packet with qname: {qname} to DNS server: {dns_server_ip} from local IP: {local_ip}")
    send(packet)

if __name__ == "__main__":
    main()

