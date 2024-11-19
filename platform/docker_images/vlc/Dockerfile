FROM debian:stretch

# Fix the sources for Debian Stretch (use the archived repositories)
RUN echo "deb http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list && \
    echo "deb-src http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list && \
    echo "deb-src http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get -y --no-install-recommends install \
        rsyslog locales iputils-ping traceroute openssh-server vim tcpdump \
        net-tools dnsutils iperf3 build-essential smcroute vlc git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Clone mtools repository
RUN git clone https://github.com/troglobit/mtools.git

# Expose SSH port
EXPOSE 22/tcp

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D", "-e"]

