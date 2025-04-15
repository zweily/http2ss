#!/bin/bash
set -e

echo "Starting HTTP/HTTPS/SOCKS proxy with Shadowsocks client..."

# Ensure folders exist
mkdir -p /var/log/privoxy /var/log/supervisor

# Enable more verbose debugging
echo "Setting up configurations..."

# Verify required environment variables
if [ -z "$SS_SERVER" ]; then
    echo "ERROR: SS_SERVER environment variable not set. Shadowsocks will fail to connect."
    echo "Please set SS_SERVER to your Shadowsocks server IP or hostname."
    export SS_SERVER="your_ss_server_ip"
    echo "Using placeholder value for now, this will not work correctly."
fi

if [ -z "$SS_PORT" ]; then
    echo "WARNING: SS_PORT environment variable not set. Using default port 8388."
    export SS_PORT="8388"
fi

if [ -z "$SS_PASSWORD" ]; then
    echo "ERROR: SS_PASSWORD environment variable not set. Shadowsocks will fail to connect."
    echo "Please set SS_PASSWORD to your Shadowsocks server password."
    export SS_PASSWORD="your_password"
    echo "Using placeholder value for now, this will not work correctly."
fi

if [ -z "$SS_METHOD" ]; then
    echo "INFO: SS_METHOD not specified. Using AES-256-GCM as the default encryption method."
    export SS_METHOD="AES-256-GCM"
else
    echo "Using $SS_METHOD encryption method"
    # Convert to uppercase for go-shadowsocks2 compatibility
    export SS_METHOD=$(echo "$SS_METHOD" | tr '[:lower:]' '[:upper:]')
fi

# Display configuration (without leaking password)
echo "Shadowsocks configuration:"
echo "  Server: $SS_SERVER"
echo "  Port: $SS_PORT"
echo "  Method: $SS_METHOD"

# Start supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf