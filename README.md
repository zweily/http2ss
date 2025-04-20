# HTTP2SS - HTTP/HTTPS/SOCKS Proxy with Shadowsocks Client

This Docker container combines HTTP proxy (using Privoxy) and SOCKS5 proxy (using go-shadowsocks2) with a Shadowsocks client. It allows you to:

1. Connect to the container using standard HTTP or SOCKS proxy protocols from your local network
2. Forward all traffic through a remote Shadowsocks server

## Exposed Ports

- **8080**: HTTP proxy (Privoxy) - **Use this for both HTTP and HTTPS traffic**
- **1080**: SOCKS5 proxy (go-shadowsocks2)

## How to Use

### Step 1: Configure your Shadowsocks settings

Edit the `docker-compose.yml` file and update the following environment variables with your Shadowsocks server details:

```yaml
environment:
  - SS_SERVER=your_ss_server_ip
  - SS_PORT=8388
  - SS_PASSWORD=your_password
  - SS_METHOD=aes-256-gcm
```

### Step 2: Build and run the container

#### Option 1: Using Docker Compose (recommended)

With Docker Compose, you don't need to manually build the image first. The Docker Compose command will automatically build the image based on the Dockerfile:

**Docker Compose V2 (Recommended):**
```bash
# Build and start the container
docker compose up -d

# Rebuild the image if needed
docker compose up -d --build
```

**Docker Compose V1 (Legacy):**
```bash
# Build and start the container
docker-compose up -d

# Rebuild the image if needed
docker-compose up -d --build
```

#### Option 2: Using Dockerfile directly

If you prefer to build and run using the Dockerfile directly:

1. Build the Docker image:
```bash
docker build -t http2ss .
```

2. Run the container:
```bash
docker run -d --name http2ss \
  -p 8080:8080 -p 1080:1080 \
  -e SS_SERVER=your_ss_server_ip \
  -e SS_PORT=8388 \
  -e SS_PASSWORD=your_password \
  -e SS_METHOD=aes-256-gcm \
  -v $(pwd)/logs:/var/log \
  http2ss
```

### Step 3: Configure your devices to use the proxy

Configure your applications or devices to use one of the following proxies:

- **HTTP Proxy**: `http://<your-docker-host-ip>:8080`  
  _Use this for both HTTP and HTTPS traffic. Modern clients automatically use the CONNECT method for HTTPS sites._
- **SOCKS5 Proxy**: `socks5://<your-docker-host-ip>:1080`

## Important Note About HTTPS Traffic

When configuring clients to use this proxy:

1. **For browsing HTTPS websites**: Use port 8080 (HTTP proxy) for all traffic, including HTTPS. 
   Modern browsers and clients automatically use the HTTP CONNECT method to tunnel HTTPS connections
   through an HTTP proxy.

2. **Privoxy doesn't act as a true HTTPS proxy** with SSL termination. The port 8443 in Privoxy's
   configuration is just listening for HTTP requests on that port, not for HTTPS connections.

## Technical Implementation

This container uses:
- **go-shadowsocks2**: SOCKS5 proxy client that connects to your remote Shadowsocks server (port 1080)
- **Privoxy**: HTTP proxy server that forwards traffic to Shadowsocks (port 8080)

## Adding Authentication (Optional)

To add authentication to your HTTP proxy:

1. Edit the `config/privoxy.conf` file and add authentication configuration
2. Rebuild the container:
   ```bash
   docker compose up -d --build
   ```

## Advanced Configuration

### Custom Shadowsocks Settings

The Shadowsocks settings are configured via environment variables in docker-compose.yml. Make sure to set:
- SS_SERVER: Your Shadowsocks server IP or hostname
- SS_PORT: Your Shadowsocks server port
- SS_PASSWORD: Your Shadowsocks password
- SS_METHOD: Your encryption method (default is aes-256-gcm)

### Custom Privoxy Settings

Modify `config/privoxy.conf` to customize the HTTP proxy behavior.

## High Availability (HA) Support for Shadowsocks Servers

### How It Works

This project now supports high availability for Shadowsocks servers. Instead of configuring a single server, you can provide a list of servers in `config/ss_servers.json`. The container will:

- Periodically check the health of the current Shadowsocks server.
- If the server becomes unreachable, automatically switch to the next available server in the list.
- Continue to monitor and switch as needed, ensuring proxy service remains available as long as at least one server is up.

### Configuring Multiple Servers

1. **Edit `config/ss_servers.json`**

   Example format:
   ```json
   [
     {
       "server": "<your_server_ip>",
       "port": <your_port>,
       "password": "<your_password>",
       "method": "aes-256-gcm"
     },
     {
       "server": "<another_server_ip>",
       "port": <another_port>,
       "password": "<another_password>",
       "method": "aes-256-gcm"
     }
   ]
   ```
   You can add as many servers as you want to this list.

2. **Update `docker-compose.yml`**

   - Remove any `SS_SERVER`, `SS_PORT`, `SS_PASSWORD`, and `SS_METHOD` environment variables.
   - Mount the `ss_servers.json` file as a read-only volume:
     ```yaml
     volumes:
       - ./logs:/var/log
       - ./config/ss_servers.json:/config/ss_servers.json:ro
     ```

3. **Build and run as usual**

   The container will automatically handle server failover.

### How the Health Check and Switch Works

- The `start.sh` script reads the list of servers from `ss_servers.json`.
- It checks each server's reachability (using a TCP connection to the server's port).
- If the current server is down, it kills the running Shadowsocks process and starts a new one with the next available server.
- This check runs in a loop, so the system will always try to use the first available server in the list.
- All switching and health checks are automatic; no manual intervention is needed.

### Logs

- Shadowsocks and failover logs are available in `logs/supervisor/shadowsocks-stdout.log`.
- You can monitor these logs to see when a server switch occurs.

## Future Enhancements

### True HTTPS Proxy Support

For true HTTPS proxy functionality (with SSL termination), a future enhancement could include adding a component like Stunnel or HAProxy to handle the SSL connections. This would work as follows:

1. Stunnel/HAProxy would listen on port 8443 and handle SSL termination
2. It would then forward the decrypted traffic to Privoxy
3. Privoxy would forward the traffic to Shadowsocks

This enhancement would be useful for clients that specifically require an HTTPS proxy with SSL termination.

## Troubleshooting

Check the logs for any issues:

```bash
docker compose logs
```

For more detailed logs:

```bash
docker exec -it http2ss cat /var/log/supervisor/shadowsocks-stdout.log
docker exec -it http2ss cat /var/log/privoxy/privoxy.log
```

### Common Issues

If you encounter connection problems:

1. **Verify your Shadowsocks server details** are correct in docker-compose.yml
2. **Check that your Shadowsocks server supports the encryption method** specified in SS_METHOD
3. **For HTTPS sites**, make sure you're using the HTTP proxy (port 8080) and not trying to use port 8443 as an HTTPS proxy