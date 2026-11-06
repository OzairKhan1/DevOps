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
### Make Sure all Domains should be accessible from Internet before requesting the Certificate. If any one is not accessible the Cert Process will fail  

```bash
sudo certbot --nginx -d cloudhatt.com -d app.cloudhatt.com
```

## 3. Follow the certbot prompts. It configures nginx (SSL) automatically.

---

# Subdomain Setup (separate site per domain/subdomain)

Each domain/subdomain gets its own web root folder and its own nginx config file. Example below: `cloudhatt.com` (main) and `app.cloudhatt.com` (sub).

## 1. Create the DNS record

In Route 53 → hosted zone → **Create record**:
- Record name: `app` (becomes `app.cloudhatt.com`), type **A**, value = EC2 IP / LB IP.
- Or a wildcard record `*` to cover all subdomains (DNS only; certbot `--nginx` cannot issue a wildcard cert, so list each subdomain with `-d`).

## 2. Create one folder per domain in `/var/www`

One folder per domain/subdomain, named exactly after it:

```bash
sudo mkdir -p /var/www/cloudhatt.com
sudo mkdir -p /var/www/app.cloudhatt.com
```

## 3. Set ownership

```bash
sudo chown -R $USER:$USER /var/www/cloudhatt.com
sudo chown -R $USER:$USER /var/www/app.cloudhatt.com
```

## 4. Create the nginx config for each domain

Main domain:

```bash
sudo nano /etc/nginx/sites-available/cloudhatt.com
```

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name cloudhatt.com;

    root /var/www/cloudhatt.com;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Subdomain:

```bash
sudo nano /etc/nginx/sites-available/app.cloudhatt.com
```

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name app.cloudhatt.com;

    root /var/www/app.cloudhatt.com;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

> One config file per domain. For another subdomain, repeat steps 2-4 with the new name.

## 5. Add an `index.html` in each directory

```bash
cat > /var/www/cloudhatt.com/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>cloudhatt.com</title></head>
<body><h1>Main site - cloudhatt.com</h1></body>
</html>
EOF

cat > /var/www/app.cloudhatt.com/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>app.cloudhatt.com</title></head>
<body><h1>Subdomain - app.cloudhatt.com</h1></body>
</html>
EOF
```

## 6. Enable the sites (symlinks)

```bash
# Link the main site config
sudo ln -s /etc/nginx/sites-available/cloudhatt.com /etc/nginx/sites-enabled/

# Link the subdomain config
sudo ln -s /etc/nginx/sites-available/app.cloudhatt.com /etc/nginx/sites-enabled/
```

## 7. Remove the old default site

```bash
sudo rm /etc/nginx/sites-enabled/default
```

> This only removes the symlink; `/etc/nginx/sites-available/default` stays as a backup. Requests with an unknown Host header now go to the first server block alphabetically (`app.cloudhatt.com`). To control this, add `default_server` to the `listen` line of the one you want as fallback.

## 8. Test and reload nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 9. Verify HTTP before running certbot

```bash
curl -I http://cloudhatt.com
curl -I http://app.cloudhatt.com
```

Both must return `200 OK` (also check on https://dnschecker.org/ that both names resolve to the server). Certbot fails if either name is unreachable on port 80.

## 10. Re-create the certificates

Certbot needs the `server_name` in each file to match the `-d` names. Because these are new server blocks, re-run it:

```bash
sudo certbot --nginx -d cloudhatt.com -d app.cloudhatt.com
```

- If certbot says a certificate already exists, choose **Expand** (or **Reinstall**), or add `--expand`. To discard the old cert and issue a fresh one: `sudo certbot delete --cert-name cloudhatt.com`, then run the command again.
- Certbot adds the `listen 443 ssl` blocks and the HTTP→HTTPS redirect to each file automatically.
- Alternatively, one cert per site: `sudo certbot --nginx -d cloudhatt.com` and `sudo certbot --nginx -d app.cloudhatt.com`.
- Test auto-renewal: `sudo certbot renew --dry-run`

## 11. Final check

```bash
sudo nginx -t && sudo systemctl reload nginx
curl -I https://cloudhatt.com
curl -I https://app.cloudhatt.com
```

> Different app per subdomain: keep the separate `server` block per subdomain, and replace `root` / `try_files` with `proxy_pass http://127.0.0.1:<port>;` inside `location /`.
