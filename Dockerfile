FROM alpine:latest

# Install base packages and dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    tzdata \
    ca-certificates \
    supervisor \
    # Dependencies for building 3proxy
    gcc \
    make \
    musl-dev \
    libressl-dev \
    # For shadowsocks-libev
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

# Install 3proxy from source
RUN cd /tmp && \
    curl -OL https://github.com/3proxy/3proxy/archive/refs/tags/0.9.4.tar.gz && \
    tar -xvf 0.9.4.tar.gz && \
    cd 3proxy-0.9.4 && \
    make -f Makefile.Linux && \
    mkdir -p /usr/local/3proxy/bin && \
    cp bin/3proxy /usr/local/3proxy/bin/ && \
    cp bin/mycrypt /usr/local/3proxy/bin/ && \
    cp bin/dighosts /usr/local/3proxy/bin/ && \
    cp bin/ftppr /usr/local/3proxy/bin/ && \
    ln -s /usr/local/3proxy/bin/3proxy /usr/bin/3proxy && \
    cd .. && \
    rm -rf 3proxy-0.9.4 0.9.4.tar.gz

# Create directories
RUN mkdir -p /etc/shadowsocks-libev /etc/3proxy /var/log/3proxy /var/log/supervisor

# Copy configuration files
COPY ./config/shadowsocks-libev.json /etc/shadowsocks-libev/config.json
COPY ./config/3proxy.conf /etc/3proxy/3proxy.conf
COPY ./config/supervisord.conf /etc/supervisord.conf
COPY ./config/start.sh /start.sh

# Make script executable
RUN chmod +x /start.sh

# Expose ports
# Shadowsocks local port
EXPOSE 1080
# HTTP proxy port
EXPOSE 8080
# HTTPS proxy port 
EXPOSE 8443
# SOCKS5 proxy port
EXPOSE 1081

# Set entrypoint
ENTRYPOINT ["/start.sh"]