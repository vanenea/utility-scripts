# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A personal collection of Docker Compose deployments and utility scripts, synced across machines (the working tree also contains live, untracked runtime data: databases, certificates, `.env` files, cookies). There is no build, lint, or test infrastructure — everything is configuration and standalone scripts. Comments in files are mostly in Chinese; follow that convention when editing existing files.

## Commands

Each directory containing a `docker-compose.yml` is an independent compose project. Run from that directory:

```bash
docker compose up -d          # start services
docker compose ps             # check status
docker compose logs -f        # follow logs
docker compose restart        # restart
docker compose down           # stop and remove
docker compose config         # validate/preview the merged YAML (no containers needed)
```

- `dockerLean/sub2api-deploy/`: requires `.env` (copy `.env.example`); `POSTGRES_PASSWORD` is mandatory (`:?` interpolation fails without it). Uses local-directory volumes (`./data`, `./postgres_data`, `./redis_data`) so the whole deployment migrates by copying the folder.
- `docker/3x-ui/setup-linux.sh` (Debian/Ubuntu + RHEL-family) and `setup-debian.sh` (Debian-only): server bootstrap scripts that install Docker, open firewall ports (443/2096/2053), generate a compose file, and start 3x-ui. Must run as root on the target server.
- `script/setup-dev.ps1`: Windows dev-machine bootstrap (Chocolatey, git, jdk8, nvm 1.1.12 + Node 14.17.4, Docker Desktop, WSL/Debian). Must run in an elevated PowerShell.

## Repository layout

- **`docker/`** — the "full" deployment set. Top-level `docker-compose.yml` currently runs 3xui + caddy (caddy terminates TLS on port 20106 and reverse-proxies to `3xui:2053`). Each subdirectory is a self-contained service stack with its own compose file and config mounted via relative paths (`./config.json:/etc/...`):
  - Proxy/panel stacks: `3x-ui`, `Xray`, `v2ray`, `sing-box`, `s-ui`, `clash`, `subconverter` (sing-box/Xray expose 7890 HTTP / 7891 SOCKS)
  - Infrastructure: `caddy`, `gitea` (web 3000, SSH 222), `syncthing`, `hermes` (Hermes agent, 8642/9119)
  - Media: `metube` (yt-dlp; routes through `socks5h://host.docker.internal:10808`)
- **`dockerLean/`** — the lightweight variant. Top-level compose currently runs only `hermes-personal`; most services (mysql, redis, gitea, dufs, minio, trend-radar, prometheus/grafana/loki/promtail) exist but are commented out. Also holds the self-contained `sub2api-deploy/` (sub2api + postgres + redis with healthchecks) and `trendRadar/` (own `.env`), plus `prometheus.yml`/`promtail-config.yml` for monitoring Spring Boot apps on the host via `host.docker.internal`.
- **`dockerTemp/`** — reference/temporary compose files (Spring Boot template, Halo blog, WordPress+nginx+mariadb), not part of the running fleet.
- **`script/`** — standalone scripts not tied to a compose project. `clash verge.js` is a Clash Verge extension script: its `main(config)` prepends the `prependRule` array (domain rules routing CN sites to the "龙猫云 - TotoroCloud" proxy group) ahead of the subscription's rules. Edit the `prependRule` array to add/remove routing rules.

## Conventions and gotchas

- **Git whitelist**: `.gitignore` only tracks `*.yaml`, `*.yml`, `*.conf`, `*.json`, `*.sh` under `docker/`, `dockerLean/`, `dockerTemp/`. New files with other extensions in those trees (e.g. `.env`, `.md`, `.toml`, `.txt`) are silently **not** committed — say so explicitly if the user expects one to be. `script/` is unrestricted.
- Runtime data dirs (`docker/metube/.metube/`, `docker/sing-box/.claude/`, `dockerLean/gitea/`, `dockerLean/minio/.minio.sys/`) are excluded after the whitelist; databases, keys, and cookies on disk are live data — never commit, print, or copy their contents elsewhere.
- **Commented-out services are intentional**: compose files act as a catalog where services are enabled on demand. Don't delete or "clean up" commented blocks, and enable/disable services by (un)commenting rather than restructuring.
- Volumes always use paths relative to the compose file, keeping each service directory portable/copyable to another host.
- `TZ=Asia/Shanghai` is the standard timezone env var across services.
- Files named `*.sync-conflict-*` are Syncthing conflict copies of live data — leave them alone.
- Some directories (`docker/dufs`, caddy data dirs, parts of `docker/hermes`) are root-owned or unreadable; permission errors when listing/reading them are expected, not a bug to fix.
