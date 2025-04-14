# HTTP2SS - HTTP/HTTPS/SOCKS Proxy with Shadowsocks Client

This Docker container combines an HTTP/HTTPS/SOCKS proxy server (using 3proxy) with a Shadowsocks client. It allows you to:

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

```bash
docker-compose up -d
```

### Step 3: Configure your devices to use the proxy

Configure your applications or devices to use one of the following proxies:

- HTTP Proxy: `http://<your-docker-host-ip>:8080`
- HTTPS Proxy: `https://<your-docker-host-ip>:8443`
- SOCKS5 Proxy: `socks5://<your-docker-host-ip>:1081`

## Adding Authentication (Optional)

To add authentication to your proxy server:

1. Edit the `config/3proxy.conf` file
2. Uncomment and modify the `users` line with your desired username and password:
   ```
   users username:CL:password
   ```
3. Rebuild the container:
   ```bash
   docker-compose up -d --build
   ```

## Advanced Configuration

### Custom Shadowsocks Settings

You can directly edit the `config/shadowsocks-libev.json` file for more advanced Shadowsocks client configurations.

### Custom 3proxy Settings

Modify `config/3proxy.conf` to customize the HTTP/HTTPS/SOCKS proxy behavior.

## Troubleshooting

Check the logs for any issues:

```bash
docker-compose logs
```

For more detailed logs:

```bash
docker exec -it http2ss cat /var/log/3proxy/3proxy.log
docker exec -it http2ss cat /var/log/supervisor/shadowsocks-stderr.log
```