---
name: cicd-containers
description: "Pluggable stack profile for Dockerfiles, container runtimes, shell automation, and CI/CD pipelines across GitHub Actions, GitLab CI, Jenkins, Azure Pipelines, and Cloud Build."
applyTo: "**/{Dockerfile*,*pipeline*,*.yml,*.yaml,*.sh,Jenkinsfile}"
---

# Stack Profile: CI/CD Pipelines, Containers & Shell Automation

## 1. Multi-Stage Rootless Container Builds
- **Multi-Stage Isolation**: Separate build/compile stages (SDKs, compilers, package managers, devDependencies) from minimal runtime stages (`distroless`, slim, or hardened minimal base images) so compilers, shells, and test artifacts never ship in production images.
- **Pinned Base Images**: Pin base images to explicit version tags and/or immutable SHA256 digests (`node:22.11.0-bookworm-slim@sha256:...`). Mutable `:latest` base tags are prohibited.
- **Non-Root Execution**: Declare an explicit unprivileged `USER` (`UID >= 10001`) before `ENTRYPOINT` / `CMD`. Running application containers as `root` is prohibited.
- **Layer & Context Hygiene**: Maintain a strict `.dockerignore` excluding `.git`, `.env*`, `.aigile/receipts`, local credentials, and build caches. Never pass secrets via `ARG` or `ENV` baked into image layers (use BuildKit `--mount=type=secret` when build-time auth is needed).

## 2. Universal CI/CD Pipeline Hardening (GitHub Actions, GitLab CI, Jenkins, Cloud Build, Azure)
- **Zero Embedded Secrets**: Never commit API keys, cloud service-account JSONs, registry passwords, or signing keys in `.yml`, `.yaml`, `Jenkinsfile`, or shell scripts. Inject secrets exclusively from managed vaults/OIDC workload identity (`GitHub OIDC`, `GitLab Vault`, `Cloud Secret Manager`, `Jenkins Credentials Binding`) and mask outputs.
- **Explicit Timeouts**: Define job-level and step-level timeouts (e.g., `timeout-minutes: 15`, `timeout: 600s`) so hung tests or network stalls never block runners indefinitely.
- **Pinned Actions & Immutable Artifact Tags**: Pin third-party CI actions/templates to full commit SHAs or verified immutable versions, and tag built container images with the immutable `$GIT_COMMIT_SHA` (never `:latest` alone).
- **Least-Privilege Permissions**: Declare minimal token scopes (`permissions: contents: read` by default in GitHub Actions) and require protected environment gates before production deployment stages.

## 3. Automated Quality, Security & Receipt Gates
- Execute deterministic verification stages in fail-fast order:
  1. Secret & dependency vulnerability scan (`./aigile secret-scan`, lockfile audit).
  2. Static analysis, typecheck, and harness sync verification (`./aigile harness check`).
  3. Unit, contract, and integration test suites with deterministic exit codes.
  4. Container build and non-root / image scan verification.

## 4. Safe POSIX / Bash Automation Standards
- Begin executable `.sh` scripts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote variable expansions (`"${var}"`), validate required inputs early, avoid `eval`, and clean up temporary directories via `trap cleanup EXIT`.

## Gate G3 Profile Checklist
- [ ] Dockerfiles use multi-stage builds, pinned base images, `.dockerignore`, and non-root `USER` directives.
- [ ] CI/CD configs contain zero plaintext secrets, set explicit step timeouts, tag artifacts by commit SHA, and use least-privilege permissions.
- [ ] Shell scripts enforce `set -euo pipefail`, quote expansions safely, and pass `./aigile secret-scan`.
