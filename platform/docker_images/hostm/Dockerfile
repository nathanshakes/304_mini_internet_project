FROM debian:stretch

# Update sources.list to use the Debian archive for Stretch and security updates
RUN echo "deb http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list && \
    echo "deb-src http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list && \
    echo "deb-src http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y rsyslog locales iputils-ping traceroute \
    openssh-server vim tcpdump net-tools dnsutils iperf3 build-essential smcroute git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add startup script and set it as entrypoint
ADD docker-start /usr/sbin/docker-start
RUN chmod +x /usr/sbin/docker-start

# Clone mtools repository
RUN git clone https://github.com/troglobit/mtools.git

# Set the entrypoint to the startup script
ENTRYPOINT ["/usr/sbin/docker-start"]

