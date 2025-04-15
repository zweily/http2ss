FROM alpine:latest

# Install base packages and dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    tzdata \
    ca-certificates \
    supervisor \
    # For HTTP/HTTPS proxy
    privoxy \
    # For Go and go-shadowsocks2 build
    git \
    go \
    # For microsocks build
    gcc \
    make \
    musl-dev

# Install go-shadowsocks2 (alternative implementation to shadowsocks-libev)
RUN go install github.com/shadowsocks/go-shadowsocks2@latest && \
    cp /root/go/bin/go-shadowsocks2 /usr/local/bin/

# Install microsocks (SOCKS5 proxy) from source
RUN cd /tmp && \
    git clone https://github.com/rofl0r/microsocks.git && \
    cd microsocks && \
    make && \
    install -m755 microsocks /usr/local/bin/ && \
    cd .. && \
    rm -rf microsocks

# Create directories for config and logs
RUN mkdir -p /etc/shadowsocks /etc/privoxy /var/log/privoxy /var/log/supervisor

# Copy configuration files
COPY ./config/shadowsocks-libev.json /etc/shadowsocks/config.json
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