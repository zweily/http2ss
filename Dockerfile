FROM alpine:latest

# Install base packages and dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    tzdata \
    ca-certificates \
    supervisor \
    # For HTTP/HTTPS proxy (replacing 3proxy)
    privoxy \
    # For shadowsocks-libev build
    gcc \
    make \
    musl-dev \
    libev-dev \
    libsodium-dev \
    mbedtls-dev \
    pcre-dev \
    c-ares-dev \
    autoconf \
    automake \
    build-base \
    libtool \
    linux-headers \
    git

# Install shadowsocks-libev from source
RUN cd /tmp && \
    git clone https://github.com/shadowsocks/shadowsocks-libev.git && \
    cd shadowsocks-libev && \
    git submodule update --init --recursive && \
    ./autogen.sh && \
    ./configure --prefix=/usr --disable-documentation && \
    make && \
    make install && \
    cd .. && \
    rm -rf shadowsocks-libev

# Install microsocks (SOCKS5 proxy) from source
RUN cd /tmp && \
    git clone https://github.com/rofl0r/microsocks.git && \
    cd microsocks && \
    make && \
    install -m755 microsocks /usr/local/bin/ && \
    cd .. && \
    rm -rf microsocks

# Create directories for config and logs
RUN mkdir -p /etc/shadowsocks-libev /etc/privoxy /var/log/privoxy /var/log/supervisor

# Copy configuration files
COPY ./config/shadowsocks-libev.json /etc/shadowsocks-libev/config.json
COPY ./config/privoxy.conf /etc/privoxy/config
COPY ./config/supervisord.conf /etc/supervisord.conf
COPY ./config/start.sh /start.sh

# Make script executable
RUN chmod +x /start.sh

# Expose ports
# Shadowsocks local port
EXPOSE 1080
# HTTP proxy port (Privoxy)
EXPOSE 8080
# HTTPS proxy port (Privoxy)
EXPOSE 8443
# SOCKS5 proxy port (microsocks)
EXPOSE 1081

# Set entrypoint
ENTRYPOINT ["/start.sh"]