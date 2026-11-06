# Route 53 Nameserver Setup for Any Domain

1. Create a hosted zone in AWS Route 53.
2. Copy all 4 NS values (without the trailing dot `.`).
3. Paste them in the Nameserver settings of the registrar where the domain was bought.
4. Create an **A record** in Route 53 pointing to the EC2 IP (or the Load Balancer if one is used).
5. NS changes take ~4-5 minutes to update.
6. Verify NS and A record on https://dnschecker.org/

---

# Use Domain on a Single EC2

## 1. Install nginx

```bash
sudo apt update -y
sudo apt install nginx -y
```

## 2. Edit the default config

```bash
sudo nano /etc/nginx/sites-available/default
```

## 3. Set `server_name` under `server`

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name cloudhatt.com app.cloudhatt.com;

    # ... rest of root and location config blocks
}
```

## 4. Change the domain name next to `server_name`, save, and reload

```bash
sudo nginx -t && sudo systemctl reload nginx
```

> This works for HTTP only. HTTPS is below.

---

# HTTPS Setup (Certbot)

## 1. Install certbot

```bash
sudo apt update
sudo apt install snapd -y
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

## 2. Run certbot for every domain/subdomain listed in `server_name` (`-d` = domain)

```bash
sudo certbot --nginx -d cloudhatt.com -d app.cloudhatt.com
```

## 3. Follow the certbot prompts. It configures nginx (SSL) automatically.

---

# Subdomain Setup

1. In Route 53 → hosted zone → **Create record**.
2. Record name: `app` (becomes `app.cloudhatt.com`), type **A**, value = EC2 IP / LB IP.
   - Or use a wildcard record `*` to cover all subdomains.
3. Add the subdomain to `server_name` in nginx:
   ```nginx
   server_name cloudhatt.com app.cloudhatt.com;
   ```
4. Reload nginx:
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```
5. Issue the certificate for it:
   ```bash
   sudo certbot --nginx -d app.cloudhatt.com
   ```
6. Check on https://dnschecker.org/

> Different app per subdomain: create a separate `server` block per subdomain, each with its own `server_name` and `proxy_pass` / `root`.
