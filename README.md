# n8n Docker Compose (local + ngrok)

Run n8n locally with Docker and keep your data. This setup is built for local machines that can’t open inbound ports, so it uses an ngrok tunnel for public webhooks. There’s also a Traefik example for production, but it’s not the default.

> Heads up: The default `compose.yaml` is meant for local use behind ngrok. `compose.yaml.bkp` shows a Traefik + HTTPS example for real servers.

## What’s included
- `compose.yaml` – Local setup. UI binds to `127.0.0.1:5678`.
- `compose.yaml.bkp` – Example Traefik setup with automatic TLS (ACME). Optional.
- `local-files/` – Mounted at `/files` inside n8n for easy import/export.

## Requirements
- Docker and Docker Compose
- ngrok (for public webhooks while developing)

## Quick start (local with ngrok)
1) Start an ngrok tunnel and copy the HTTPS URL:
```bash
ngrok http 5678
```

2) Tell n8n about that URL. Edit `compose.yaml` and set both lines:
```yaml
N8N_HOST=https://your-ngrok-subdomain.ngrok-free.app
WEBHOOK_URL=https://your-ngrok-subdomain.ngrok-free.app/
```

3) (Optional) Set your timezone:
```bash
cp env.example .env
# then edit .env and change GENERIC_TIMEZONE if you like
```

4) Start n8n and open the UI:
```bash
make up
open http://127.0.0.1:5678
```

Whenever your ngrok URL changes, update `compose.yaml` and run `make restart`.

## Useful commands
```bash
# Start / Stop / Restart
make up
make down
make restart

# Logs and status
make logs
make ps

# Shell into the container (bash or sh)
make shell

# Copy a file into the container
make copy SRC=./local-files/sample.json DEST=/files/

# Backup / Restore the n8n data volume
make backup
make restore FILE=n8n_data_YYYY-mm-dd_HHMMSS.tar.gz
```

## Environment and config
- `GENERIC_TIMEZONE` sets the container timezone (used by Cron and scheduling).
- `N8N_HOST` and `WEBHOOK_URL` must point to your public URL (the ngrok URL for local use). Set them directly in `compose.yaml` or export them before `docker compose up`.

Traefik example (optional): If you have a domain and a real server, fill out `DOMAIN_NAME`, `SUBDOMAIN`, and `SSL_EMAIL` in `.env`, then run with the Traefik compose file:
```bash
docker compose -f compose.yaml.bkp --env-file .env up -d
```

## Troubleshooting
- Webhooks return 404 or don’t trigger: make sure `WEBHOOK_URL` matches your ngrok URL and the tunnel is running.
- TLS issues (Traefik example): check DNS for `SUBDOMAIN.DOMAIN_NAME` and that ports 80/443 are reachable.
- Permissions: this setup enforces secure settings file permissions with `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`.

## Credits
- Based on the official docs: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/
- Handy article for local/ngrok: https://medium.com/@mister.funable/running-n8n-locally-with-ngrok-734af69e1530