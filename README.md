# HTTP2SS - HTTP/HTTPS/SOCKS Proxy with Shadowsocks Client

This Docker container combines HTTP/HTTPS proxy (using Privoxy) and SOCKS proxy (using microsocks) with a Shadowsocks client. It allows you to:

1. Connect to the container using standard HTTP, HTTPS, or SOCKS proxy protocols from your local network
2. Forward all traffic through a remote Shadowsocks server

## Exposed Ports

- **8080**: HTTP proxy
- **8443**: HTTPS proxy
- **1081**: SOCKS5 proxy

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
  -p 8080:8080 -p 8443:8443 -p 1081:1081 \
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
- SOCKS5 Proxy: `socks5://<your-docker-host-ip>:1081`

## Adding Authentication (Optional)

To add authentication to your HTTP/HTTPS proxy:

1. Edit the `config/privoxy.conf` file and add authentication configuration
2. Rebuild the container:
   ```bash
   docker compose up -d --build
   ```

## Advanced Configuration

### Custom Shadowsocks Settings

You can directly edit the `config/shadowsocks-libev.json` file for more advanced Shadowsocks client configurations.

### Custom Privoxy Settings

Modify `config/privoxy.conf` to customize the HTTP/HTTPS proxy behavior.

### Custom microsocks Settings

The microsocks settings can be adjusted in the `config/supervisord.conf` file by modifying the command-line parameters.

## Troubleshooting

Check the logs for any issues:

```bash
docker compose logs
```

For more detailed logs:

```bash
docker exec -it http2ss cat /var/log/privoxy/privoxy.log
docker exec -it http2ss cat /var/log/supervisor/shadowsocks-stderr.log
docker exec -it http2ss cat /var/log/supervisor/microsocks-stderr.log
```