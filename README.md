# miso

Local-first OpenTofu playground with Atlantis PR automation, exposed to GitHub
through Cloudflare Tunnel.

## Overview

`miso` is a small GitOps demo environment:

- OpenTofu manages the infrastructure code in `infra/`
- Atlantis reacts to pull requests and PR comments like `atlantis plan`
- Cloudflare Tunnel exposes the local Atlantis server without opening an inbound
  firewall port
- Docker Compose runs Atlantis and `cloudflared` together on the local machine

This repository is designed to prove the Atlantis workflow end to end with a
safe `null_resource` demo, so no cloud credentials are required for the first
plan and apply cycle.

## Stack

| Layer | Technology |
| --- | --- |
| IaC | OpenTofu 1.9.x |
| PR automation | Atlantis 0.42.x |
| Tunnel | Cloudflare Tunnel |
| Container runtime | Docker Compose v2 |
| Base image | UBI9 `ubi-micro` |
| Build helper | GNU Make |

## Architecture

```text
GitHub PR / PR comment
        |
        v
GitHub webhook POST /events
        |
        v
Cloudflare Tunnel
        |
        v
cloudflared container
        |
        v
Atlantis container
        |
        v
OpenTofu plan/apply in infra/
        |
        v
Atlantis comment back on the PR
```

## Repository Layout

```text
miso/
|- Dockerfile
|- docker-compose.yml
|- Makefile
|- atlantis.yaml
|- repos.yaml
|- .env.example
`- infra/
   |- versions.tf
   |- main.tf
   |- variables.tf
   |- outputs.tf
   `- terraform.tfvars.example
```

## Prerequisites

- Docker with Compose v2
- A named Cloudflare Tunnel
- A GitHub token for Atlantis
- `tofu` installed locally if you want to run `make validate`

## Environment

Copy the template and fill in your real values:

```bash
cp .env.example .env
```

Required variables:

```bash
ATLANTIS_GH_USER=your-github-user
ATLANTIS_GH_TOKEN=ghp_xxx
ATLANTIS_GH_WEBHOOK_SECRET=replace-with-random-secret
CF_TUNNEL_TOKEN=replace-with-cloudflare-tunnel-token
```

## Quick Start

Build the Atlantis image:

```bash
make build
```

Start Atlantis and Cloudflare Tunnel:

```bash
make up
```

Check the logs:

```bash
make logs
make tunnel-logs
```

Validate the demo OpenTofu module locally:

```bash
make validate
```

## Webhook Setup

Configure the GitHub repository webhook with:

- Payload URL: `https://miso-atlantis.adevsh.com/events`
- Content type: `application/json`
- Secret: same value as `ATLANTIS_GH_WEBHOOK_SECRET`
- Events: `Pull requests`, `Pushes`, `Issue comments`, `Pull request reviews`

The current public tunnel hostname is:

- `https://miso-atlantis.adevsh.com/`

## Atlantis Configuration

Two Atlantis config layers are used:

- `atlantis.yaml`: repo-side project mapping for the `infra/` directory
- `repos.yaml`: server-side policy that enforces `apply_requirements` for the
  public repository

This split matters because `apply_requirements` should stay server-side, so a
pull request cannot weaken apply protections.

Current demo policy:

- Solo testing currently uses `mergeable` only in `repos.yaml`
- Team or organization deployments should restore `approved` alongside
  `mergeable` so a second reviewer is required before `atlantis apply`
- `atlantis.yaml` enables `automerge: true`, so Atlantis can merge a PR after a
  successful apply when GitHub still considers that PR mergeable

Automerge expectations:

- Atlantis apply and merge are still separate checks internally
- A successful apply does not override GitHub branch protection
- If required checks, reviews, or merge settings are not satisfied, Atlantis
  will apply successfully and leave the PR open

## Demo Infrastructure

The `infra/` module currently uses the `hashicorp/null` provider and a
`null_resource` with a `run_id` trigger.

This keeps the demo:

- safe to apply locally
- free of cloud credentials
- easy to review in Atlantis comments because changing `run_id` forces a clear
  replacement diff

## Current Status

Working now:

- Docker image builds successfully
- Atlantis and `cloudflared` start through Compose
- Cloudflare Tunnel is reachable at `miso-atlantis.adevsh.com`
- `make validate` passes
- Atlantis repo-side and server-side config files are present
- Atlantis apply succeeds against the demo `null_resource`

Still to finish:

- fuller end-to-end apply verification in PR comments
- GitHub Actions CI workflow
- richer README polish such as badges and screenshots

## Notes

- State is currently local to Atlantis because no remote backend is configured
  yet
- `repos.yaml` intentionally relaxes apply requirements for solo testing; for a
  shared repository, restore `approved` in addition to `mergeable`
- `automerge: true` is enabled, but actual PR merge still depends on GitHub
  mergeability and repository protection rules
- The production container intentionally has no shell because it uses
  `ubi-micro`
- The `shell` Make target is only for temporary debug images, not the final
  runtime image
