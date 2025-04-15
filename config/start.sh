#!/bin/bash
set -e

echo "Starting HTTP/HTTPS/SOCKS proxy with Shadowsocks client..."

# Ensure folders exist
mkdir -p /var/log/privoxy /var/log/supervisor

# Enable more verbose debugging
echo "Setting up configurations..."

# Check if environment variables are set and update Shadowsocks config if they are
if [ ! -z "$SS_SERVER" ]; then
    echo "Setting Shadowsocks server to $SS_SERVER"
    sed -i "s/\"server\": \".*\"/\"server\": \"$SS_SERVER\"/" /etc/shadowsocks-libev/config.json
else
    echo "ERROR: SS_SERVER environment variable not set. Shadowsocks will fail to connect."
    echo "Please set SS_SERVER to your Shadowsocks server IP or hostname."
fi

if [ ! -z "$SS_PORT" ]; then
    echo "Setting Shadowsocks port to $SS_PORT"
    sed -i "s/\"server_port\": [0-9]*/\"server_port\": $SS_PORT/" /etc/shadowsocks-libev/config.json
else
    echo "WARNING: SS_PORT environment variable not set. Using default port from config."
fi

if [ ! -z "$SS_PASSWORD" ]; then
    echo "Setting Shadowsocks password"
    sed -i "s/\"password\": \".*\"/\"password\": \"$SS_PASSWORD\"/" /etc/shadowsocks-libev/config.json
else
    echo "ERROR: SS_PASSWORD environment variable not set. Shadowsocks will fail to connect."
    echo "Please set SS_PASSWORD to your Shadowsocks server password."
fi

if [ ! -z "$SS_METHOD" ]; then
    echo "Setting Shadowsocks encryption method to $SS_METHOD"
    sed -i "s/\"method\": \".*\"/\"method\": \"$SS_METHOD\"/" /etc/shadowsocks-libev/config.json
else
    echo "Using aes-256-gcm encryption method from config"
    # The default method is already aes-256-gcm in the config file
fi

# Ensure all optimization settings are applied for AEAD ciphers
echo "Applying optimizations for AEAD cipher..."
if ! grep -q "no_delay" /etc/shadowsocks-libev/config.json; then
    sed -i 's/"mode": ".*"/"mode": "tcp_only",\n    "no_delay": true/' /etc/shadowsocks-libev/config.json
fi

# Force TCP only mode to avoid UDP-related issues
echo "Setting TCP-only mode to avoid potential UDP relay issues"
sed -i 's/"mode": ".*"/"mode": "tcp_only"/' /etc/shadowsocks-libev/config.json

# Dump final shadowsocks config (without password) for debugging
echo "Final Shadowsocks configuration:"
grep -v password /etc/shadowsocks-libev/config.json

# Check that microsocks exists
if [ ! -f /usr/local/bin/microsocks ]; then
    echo "ERROR: microsocks not found at /usr/local/bin/microsocks"
    echo "This could be due to a build failure."
fi

# Start supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf