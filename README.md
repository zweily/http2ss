# HTTP2SS - HTTP/HTTPS/SOCKS Proxy with Shadowsocks Client

This Docker container combines HTTP/HTTPS proxy (using Privoxy) and SOCKS5 proxy (using go-shadowsocks2) with a Shadowsocks client. It allows you to:

1. Connect to the container using standard HTTP, HTTPS, or SOCKS proxy protocols from your local network
2. Forward all traffic through a remote Shadowsocks server

## Exposed Ports

- **8080**: HTTP proxy (Privoxy)
- **8443**: HTTPS proxy (Privoxy)
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
  -p 8080:8080 -p 8443:8443 -p 1080:1080 \
  -e SS_SERVER=your_ss_server_ip \
  -e SS_PORT=8388 \
  -e SS_PASSWORD=your_password \
  -e SS_METHOD=aes-256-gcm \
  -v $(pwd)/logs:/var/log \
  http2ss
```

### Step 3: Configure your devices to use the proxy

Configure your applications or devices to use one of the following proxies:

- HTTP Proxy: `http://<your-docker-host-ip>:8080`
- HTTPS Proxy: `https://<your-docker-host-ip>:8443`
- SOCKS5 Proxy: `socks5://<your-docker-host-ip>:1080`

## Technical Implementation

This container uses:
- **go-shadowsocks2**: SOCKS5 proxy client that connects to your remote Shadowsocks server (port 1080)
- **Privoxy**: HTTP/HTTPS proxy server that forwards traffic to Shadowsocks (ports 8080, 8443)

## Adding Authentication (Optional)

To add authentication to your HTTP/HTTPS proxy:

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

Modify `config/privoxy.conf` to customize the HTTP/HTTPS proxy behavior.

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