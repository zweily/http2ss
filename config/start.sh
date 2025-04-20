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

# Function to check if a Shadowsocks server is reachable
check_server() {
    local server_ip=$1
    local server_port=$2
    timeout 3 bash -c "/dev/tcp/$server_ip/$server_port" &>/dev/null
    return $?
}

# Read server list from JSON
SS_SERVERS_FILE="/etc/ss_servers.json"
if [ ! -f "$SS_SERVERS_FILE" ]; then
    SS_SERVERS_FILE="/config/ss_servers.json"
fi

if [ ! -f "$SS_SERVERS_FILE" ]; then
    echo "ERROR: No ss_servers.json found! Exiting."
    exit 1
fi

# Copy config to /etc if needed
cp "$SS_SERVERS_FILE" /etc/ss_servers.json

# Parse server list
servers_count=$(jq length /etc/ss_servers.json)
if [ "$servers_count" -eq 0 ]; then
    echo "ERROR: No servers found in ss_servers.json! Exiting."
    exit 1
fi

current_index=0

start_shadowsocks() {
    local idx=$1
    server=$(jq -r ".[$idx].server" /etc/ss_servers.json)
    port=$(jq -r ".[$idx].port" /etc/ss_servers.json)
    password=$(jq -r ".[$idx].password" /etc/ss_servers.json)
    method=$(jq -r ".[$idx].method" /etc/ss_servers.json)
    echo "Starting Shadowsocks with $server:$port ($method)"
    # Kill any running go-shadowsocks2
    pkill -f go-shadowsocks2 || true
    # Start in background
    nohup go-shadowsocks2 -s "$server:$port" -p "$password" -m "$method" -verbose -u -b :1080 &> /var/log/supervisor/shadowsocks-stdout.log &
}

# Main loop for HA
while true; do
    for ((i=0; i<servers_count; i++)); do
        server=$(jq -r ".[$i].server" /etc/ss_servers.json)
        port=$(jq -r ".[$i].port" /etc/ss_servers.json)
        echo "Checking Shadowsocks server $server:$port..."
        if check_server "$server" "$port"; then
            echo "Server $server:$port is reachable."
            if [ "$current_index" -ne "$i" ]; then
                echo "Switching to server $server:$port."
                current_index=$i
                start_shadowsocks $i
            fi
            break
        else
            echo "Server $server:$port is unreachable."
        fi
    done
    sleep 30
    # Re-check current server
    server=$(jq -r ".[$current_index].server" /etc/ss_servers.json)
    port=$(jq -r ".[$current_index].port" /etc/ss_servers.json)
    if ! check_server "$server" "$port"; then
        echo "Current server $server:$port is down. Will try next server."
        current_index=$(( (current_index + 1) % servers_count ))
        start_shadowsocks $current_index
    fi
    sleep 30
done

# Start supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf