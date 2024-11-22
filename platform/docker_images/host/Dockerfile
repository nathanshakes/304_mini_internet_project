# Use d_base Alpine image
FROM d_base:latest

# Install dependencies
RUN apk add --no-cache \
        openssh-server \
        iptables \
        gcompat \
        iproute2 \
        netcat-openbsd 

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        hping3 \
        masscan \
        zmap

# Configure SSH
RUN ssh-keygen -A \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config \
    && sed -i s/root:!/"root:*"/g /etc/shadow \
    && mkdir -p /var/run/sshd /root/.ssh \
    && chmod 0755 /var/run/sshd

# Expose SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]

