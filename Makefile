# Makefile
#
# Standard local workflow commands for miso.
# Keep these targets thin wrappers around docker compose and tofu so the repo
# has one predictable entry point for build, runtime, and validation tasks.

.PHONY: build up down logs tunnel-logs restart shell validate

# Rebuild without cache so version bumps in the Dockerfile are always picked up.
build:
	docker compose build --no-cache

# Start Atlantis and cloudflared in the background.
up:
	docker compose up -d

# Stop and remove the compose stack.
down:
	docker compose down

# Tail Atlantis logs for webhook and plan/apply troubleshooting.
logs:
	docker compose logs -f atlantis

# Tail cloudflared logs to confirm the tunnel is connected and stable.
tunnel-logs:
	docker compose logs -f cloudflared

# Restart Atlantis alone after repo config changes.
restart:
	docker compose restart atlantis

# Production image has no shell; this target is only for temporary debug images.
shell:
	docker compose exec atlantis /bin/sh

# Local OpenTofu validation for the demo root module.
validate:
	tofu -chdir=infra init -backend=false
	tofu -chdir=infra validate
	tofu -chdir=infra fmt -check -recursive
