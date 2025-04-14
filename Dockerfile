FROM alpine:latest

# Install required packages
RUN apk update && apk add --no-cache \
    shadowsocks-libev \
    3proxy \
    bash \
    curl \
    tzdata \
    ca-certificates \
    supervisor

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