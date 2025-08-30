#!/bin/bash
set -e

echo "Starting HTTP/HTTPS/SOCKS proxy with Shadowsocks client..."

mkdir -p /var/log/privoxy /var/log/supervisor

echo "Setting up configurations..."

check_server() {
    local idx=$1
    local server=$(jq -r ".[${idx}].server" /etc/ss_servers.json)
    local port=$(jq -r ".[${idx}].port" /etc/ss_servers.json)
    local password=$(jq -r ".[${idx}].password" /etc/ss_servers.json)
    local method=$(jq -r ".[${idx}].method" /etc/ss_servers.json)
    local socks_port=1080

    pkill -f go-shadowsocks2 || true
    nohup go-shadowsocks2 -c "$server:$port" -password "$password" -cipher "$method" -socks ":$socks_port" -u -verbose &> /var/log/supervisor/shadowsocks-stdout.log &
    local ss_pid=$!
    sleep 2

    curl --socks5-hostname 127.0.0.1:$socks_port --max-time 8 -s https://www.google.com -o /dev/null
    local result=$?
    if [ $result -eq 0 ]; then
        echo "SOCKS5 proxy through $server:$port is working."
        return 0
    else
        echo "SOCKS5 proxy through $server:$port failed. Killing process."
        pkill -f go-shadowsocks2 || true
        return 1
    fi
}

SS_SERVERS_FILE="/etc/ss_servers.json"
if [ ! -f "$SS_SERVERS_FILE" ]; then
    SS_SERVERS_FILE="/config/ss_servers.json"
fi
if [ ! -f "$SS_SERVERS_FILE" ]; then
    echo "ERROR: No ss_servers.json found! Exiting."
    exit 1
fi
cp "$SS_SERVERS_FILE" /etc/ss_servers.json
servers_count=$(jq length /etc/ss_servers.json)
if [ "$servers_count" -eq 0 ]; then
    echo "ERROR: No servers found in ss_servers.json! Exiting."
    exit 1
fi
current_index=0

( while true; do
    found_working=0
    for ((i=0; i<servers_count; i++)); do
        echo "Testing Shadowsocks server index $i..."
        if check_server $i; then
            current_index=$i
            found_working=1
            break
        fi
    done
    if [ $found_working -eq 0 ]; then
        echo "No working Shadowsocks server found. Retrying in 30 seconds..."
        sleep 30
        continue
    fi
    while true; do
        sleep 30
        echo "Rechecking current Shadowsocks server index $current_index..."
        if ! check_server $current_index; then
            echo "Current server failed. Will try next available server."
            break
        fi
    done
    sleep 2
done ) &

echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
