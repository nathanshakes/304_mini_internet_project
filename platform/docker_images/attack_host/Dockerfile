# Use d_base Alpine image
FROM d_base:latest

# Install base dependencies
RUN apk add --no-cache \
        openssh-server \
        iptables \
        gcompat \
        iproute2 \
        netcat-openbsd \
        python3 \
        py3-pip \
        build-base \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        openssl-dev \
        cargo

# Install additional tools from the edge repository
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        hping3 \
        masscan \
        zmap 

# Create a virtual environment and install Scrapy
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir scrapy \
    && deactivate

# Add the virtual environment to PATH for all users
ENV PATH="/opt/venv/bin:$PATH"

# Configure SSH
RUN ssh-keygen -A \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config \
    && sed -i s/root:!/"root:*"/g /etc/shadow \
    && mkdir -p /var/run/sshd /root/.ssh \
    && chmod 0755 /var/run/sshd

# Expose SSH port
EXPOSE 22

# Command to start SSH daemon
CMD ["/usr/sbin/sshd", "-D", "-e"]

