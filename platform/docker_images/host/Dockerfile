# Use the Alpine base image
FROM d_base:latest

# Install system dependencies
RUN apk add --no-cache \
        openssh-server \
        iptables \
        gcompat \
        iproute2 \
        netcat-openbsd 
        
# Configure SSH
RUN ssh-keygen -A \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config \
    && sed -i s/root:!/"root:*"/g /etc/shadow \
    && mkdir -p /var/run/sshd /root/.ssh \
    && chmod 0755 /var/run/sshd

# Expose SSH port
EXPOSE 22

# Default command
CMD ["/usr/sbin/sshd", "-D", "-e"]

