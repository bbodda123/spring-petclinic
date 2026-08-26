# Spring App — Ansible Deployment Plan

**Goal:** Deploy a Spring Boot app (pulled from Docker Hub) to a VPS/EC2 using Ansible roles, with security hardening baked in from the start (lesson learned from the earlier EC2 crypto-mining compromise).

Status legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Repo Layout

```
ansible/
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── all/
│       ├── vars.yml
│       └── vault.yml        # encrypted: docker hub token, db creds
├── roles/
│   ├── common/
│   ├── docker/
│   ├── nginx_ssl/
│   ├── deploy_app/
│   └── security_hardening/
├── site.yml
└── ansible.cfg
```

---

## Role 1 — `common` (base system)
- [ ] APT update/upgrade
- [ ] Set timezone / NTP sync
- [ ] Install essentials: curl, git, ufw, fail2ban, unzip
- [ ] Create non-root deploy user, sudo + SSH key auth only
- [ ] Disable root SSH login
- [ ] Disable SSH password auth

## Role 2 — `docker` (engine setup)
- [ ] Install Docker CE + docker-compose-plugin from **official Docker repo** (not distro package)
- [ ] Add deploy user to `docker` group
- [ ] Configure `/etc/docker/daemon.json`:
  - [ ] Log rotation (`max-size`, `max-file`) to prevent disk fill
  - [ ] `live-restore: true`
- [ ] Enable + start docker service

## Role 3 — `nginx_ssl` (reverse proxy + certs)
- [ ] Install nginx
- [ ] Template reverse-proxy vhost → `localhost:<spring_port>`
- [ ] Certbot install + issue cert for domain
- [ ] Auto-renewal (cron or systemd timer)
- [ ] Force HTTPS redirect
- [ ] HSTS header

## Role 4 — `deploy_app`
- [ ] Template `docker-compose.yml` with image tag as a variable (`app_version`)
- [ ] `docker login` via vault-encrypted token (no plaintext creds)
- [ ] `docker compose pull && docker compose up -d`
- [ ] Healthcheck wait before marking play successful
- [ ] Bind Spring container to `127.0.0.1:8080:8080` — **never expose app port publicly**, nginx is the only public entry point

## Role 5 — `security_hardening`
- [ ] UFW: default deny incoming, allow only 22 / 80 / 443
- [ ] fail2ban for SSH
- [ ] Run Spring container as **non-root user** in the image
- [ ] `read_only: true` + drop capabilities in compose where possible
- [ ] Container resource limits (`mem_limit`, `cpus`)
- [ ] Enable AWS GuardDuty (if on AWS — not Ansible-managed, but document/verify step)
- [ ] Unattended-upgrades for OS security patches

## Role 6 — `monitoring` (optional)
- [ ] Node exporter or `docker stats`-based check
- [ ] Alert via Telegram bot (reuse pattern from AWS cost-management bot) if CPU stays abnormally high for N minutes

---

## Open Questions / To Decide
- [ ] VPS provider for this deployment (same AWS setup or new host?)
- [ ] Domain name to use for SSL cert
- [ ] Spring app internal port
- [ ] DB: containerized alongside app, or external managed DB?
- [ ] Backup strategy for DB/volumes

---

## Notes
_(add findings, gotchas, and decisions here as you go)_

-
