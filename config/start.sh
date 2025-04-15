#!/bin/bash
set -e

echo "Starting HTTP/HTTPS/SOCKS proxy with Shadowsocks client..."

# Ensure folders exist
mkdir -p /var/log/privoxy /var/log/supervisor

# Check if environment variables are set and update Shadowsocks config if they are
if [ ! -z "$SS_SERVER" ]; then
    sed -i "s/\"server\": \".*\"/\"server\": \"$SS_SERVER\"/" /etc/shadowsocks-libev/config.json
fi

if [ ! -z "$SS_PORT" ]; then
    sed -i "s/\"server_port\": [0-9]*/\"server_port\": $SS_PORT/" /etc/shadowsocks-libev/config.json
fi

if [ ! -z "$SS_PASSWORD" ]; then
    sed -i "s/\"password\": \".*\"/\"password\": \"$SS_PASSWORD\"/" /etc/shadowsocks-libev/config.json
fi

if [ ! -z "$SS_METHOD" ]; then
    sed -i "s/\"method\": \".*\"/\"method\": \"$SS_METHOD\"/" /etc/shadowsocks-libev/config.json
fi

# Start supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf