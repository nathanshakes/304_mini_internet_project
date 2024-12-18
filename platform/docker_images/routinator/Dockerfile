# -- stage 1: build static routinator with musl libc for alpine
FROM d_base:latest as build

# Specify what version of routinator should be built.
ARG ROUTINATOR_VERSION=0.13.2

# Install necessary dependencies, including rustup
RUN apk add --no-cache \
    wget \
    openssl-dev \
    build-base \
    rust \
    cargo \
    musl-dev \
    libffi-dev \
    ca-certificates \
    zlib-dev 


# Set working directory
WORKDIR /tmp/routinator

# Download and extract the Routinator source code
RUN wget "https://github.com/NLnetLabs/routinator/archive/refs/tags/v${ROUTINATOR_VERSION}.tar.gz" -O - | tar -xz --strip-components=1


RUN cargo build \
    --target x86_64-alpine-linux-musl \
    --features socks,native-tls \
    --release \
    --locked

# -- stage 2: create image with the static routinator executable
FROM d_base_supervisor:latest
COPY --from=build /tmp/routinator/target/x86_64-alpine-linux-musl/release/routinator /usr/local/bin/

# Install rsync and ca-certificates as routinator depends on it
# Use Tini to ensure that Routinator responds to CTRL-C when run in the
# foreground without the Docker argument "--init" (which is actually another
# way of activating Tini, but cannot be enabled from inside the Docker image).
RUN apk add --no-cache curl rsync libgcc ca-certificates openssl openssh-server \
	openssh-server \
        iptables \
        gcompat \
        iproute2 \
        netcat-openbsd \
        python3 \
        py3-pip \
        py3-cryptography \
        build-base \
        libffi-dev \
        py3-cffi \
        libpcap-dev
        
# Install tools from testing repository
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        hping3 \
        masscan \
        zmap
        
# Create a Python virtual environment and install Scapy
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir scapy \
    && deactivate

RUN ssh-keygen -A \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config \
    # Unlocks the root user so that ssh login is allowed.
    && sed -i s/root:!/"root:*"/g /etc/shadow \
    && mkdir -p /var/run/sshd /root/.ssh \
    && chmod 0755 /var/run/sshd

# Create the repository and TAL directories
RUN mkdir -p /root/.rpki-cache/repository /root/.rpki-cache/tals

EXPOSE 3323/tcp
EXPOSE 9556/tcp
EXPOSE 22/tcp

COPY routinator.conf /root/.routinator.conf
COPY supervisord.conf /etc/supervisor/conf.d/processes.conf

# Add startup script and set it as entrypoint
COPY docker-start /docker-start
RUN chmod +x /docker-start

ENTRYPOINT [ "/docker-start" ]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
