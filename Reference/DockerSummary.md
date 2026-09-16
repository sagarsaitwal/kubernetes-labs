# Docker Learning Summary

Reference document summarizing a 14-day, hands-on Docker learning project.
Source repo: https://github.com/sagarsaitwal/docker-labs
Generated: 16 Sep 2026, after the full 14-day plan completed.

Everything below was actually run and verified on the environment described,
not copied from documentation. Numbers are real measurements from that
environment.

---

## 1. Environment

```text
Host        Windows 11 Pro
WSL         WSL2, distro FedoraLinux-44
Docker      Engine 29.7.2 (client + server), Compose v5.5.0
            Installed inside Fedora directly - NOT Docker Desktop
SELinux     Disabled
```

Docker runs against a normal Linux daemon and socket, the same shape as a
real Linux server - not the Docker Desktop VM-based setup common on Windows.

---

## 2. What was covered (14 days)

| Days | Topic |
|:--:|---|
| 0 | Engine install, daemon, socket permissions, the docker group |
| 1 | Container lifecycle: run, inspect, exec, destroy; exit codes; signals |
| 2 | Runtime configuration: env vars, --env-file, restart policies, docker update |
| 3 | Images, tags vs. digests, manifest lists, registries, disk accounting |
| 4 | Writing a first Dockerfile; PID 1 and signal handling; --init |
| 5 | Layer caching, cache invalidation, .dockerignore, --no-cache vs --pull |
| 6 | Named volumes and data persistence lifecycles |
| 7 | Bind mounts, UID mismatches, live-reload |
| 8 | Container networking, embedded DNS, network connect/disconnect |
| 9 | Docker Compose: the implicit network, down vs down -v |
| 10 | Multi-service stack, depends_on: condition: service_healthy |
| 11 | Debugging flow: logs -> inspect -> diff -> events; three deliberate breaks |
| 12 | Multi-stage builds and image size reduction |
| 13 | Publishing to Docker Hub; proving pushed/pulled content matches |
| 14 | Production hardening: non-root, resource limits, healthchecks, CVE scanning |

---

## 3. Projects built

1. **01-node-postgres** - Node/Express API + Postgres via Compose, with
   depends_on: condition: service_healthy fixing a real startup race.
   Image landed at 255MB against a 200MB target (left open - see below).
2. **02-python-redis** - Flask API + Redis, built against a full
   production-hardening checklist: non-root user, Gunicorn instead of
   Flask's dev server, a memory limit with a genuine OOM kill diagnosed and
   fixed, a digest-pinned base image, and a Trivy CVE scan with a real fix
   applied and re-verified.
3. **03-react-multistage** - React (Vite) app, multi-stage build:
   353MB build stage -> 74MB final image (79% reduction), served by nginx.

---

## 4. Core mental models

**A container is not a lightweight VM.** The kernel is shared with the
host; the userland is not. Verified: host is Fedora, "cat /etc/os-release"
inside an nginx container reports Debian - the image ships its own
userland on top of the shared host kernel.

**Three kinds of storage, three different lifecycles.**
- Writable layer: belongs to the container object. Survives
  stop/start/restart; destroyed only by docker rm.
- Named volume: belongs to nothing but itself. Survives docker rm -f
  entirely; destroyed only by docker volume rm.
- Bind mount: zero indirection - the container and host open the literal
  same host path. No UID translation: a container process writing as root
  produces files owned by real UID 0 on the host.

**Only a user-defined network gets DNS.** The default bridge network
predates Docker's embedded DNS resolver and never got one - two containers
on it cannot resolve each other by name. docker network create (or
letting Compose create its own project network) gets real container-name
resolution. localhost inside a container never means a sibling container -
every container has its own private loopback.

**depends_on alone waits for "started," not "ready."** Postgres (and
similar) processes take a few seconds to actually accept connections even
after the process starts. depends_on: condition: service_healthy is what
actually closes that race - not the process starting.

**A HEALTHCHECK only proves what its own command tests, nothing more.**
It runs via docker exec, inside the container's own network namespace -
so a check that never touches the real dependency (DB, correct bind
address) can stay green while the app is actually broken from the outside.

**A multi-stage build's second FROM is a genuinely independent
filesystem.** Nothing from an earlier stage exists in a later one unless
explicitly pulled across with COPY --from=<stage>. Measured: 353MB build
stage -> 74MB final image; the only layer contributed by the project's own
Dockerfile was a 319KB COPY of compiled output.

**Exit codes need docker inspect, not just the number.** 137 means
"force-killed by a signal" - it does NOT by itself mean out-of-memory.
docker inspect's .State.OOMKilled is what actually confirms a
memory-limit kill; docker stats --no-stream can miss a crash loop
entirely if it's caught between restarts.

**PID 1 does not get normal signal defaults.** An unhandled SIGTERM is
ignored for PID 1 specifically, not fatal. Measured: same app, same CMD,
took the full ~10s grace period and was force-killed without --init; with
--init (tini becomes PID 1 and forwards signals properly), stop dropped to
0.4s with a clean signal-terminated exit.

**A digest-pinned base image can't self-patch - deliberate tradeoff, not a
bug.** Fixing a found CVE meant patching OS packages at build time
(apt-get upgrade), independent of the base image's own release schedule.
Also: fixing one CVE on a package doesn't make that package clean forever -
rescanning after a fix surfaced different, unrelated CVEs on the same
packages.

---

## 5. Verified findings, by topic

### Images, layers, registries
- A tag is a pointer, not a thing - docker tag costs no disk; docker image
  rm prints "Untagged:" until the last reference goes, then "Deleted:".
- docker image ls bills shared layers to every image that uses them -
  measured 705.5MB apparent vs. 426.7MB actual disk for two related images.
  docker system df -v (SHARED/UNIQUE) is the trustworthy number.
- A tag like nginx:1.27 is often a manifest list indexing multiple
  architectures; Docker matches host arch automatically. unknown/unknown
  entries in a manifest list are attestation manifests (provenance/SBOM),
  not broken platforms.
- Registry layer dedup is scoped per repository, not global. A brand-new
  repo's first push re-uploads every layer of even a very common base
  image; the same content pushed again under a second tag to the same repo
  reuses every layer.
- A tag pushed to a registry is exactly as movable as a local one - only a
  pull by digest can never resolve to different content later.
- On a containerd-backed engine, the image ID is the manifest digest; on
  the older graphdriver storage they differ - don't assume one holds
  universally.

### Containers, config, lifecycle
- Environment is fixed at container creation - changing config means
  replacing the container, not reconfiguring it. docker update is the
  narrow exception (restart policy + resource limits only).
- --env-file is not a shell script - no quote stripping, no $VAR
  expansion, no export. Precedence: image ENV < --env-file < -e.
- always vs unless-stopped differ in exactly one case: a container stopped
  by hand before a daemon restart - always restarts it anyway.
- Restart backoff caps at roughly 60 seconds after a fast initial doubling
  (finishes in ~10 attempts).
- Environment variables are not secrets - visible via docker inspect,
  docker exec env, /proc/1/environ regardless of --env-file use.
- The docker group is root-equivalent on the host (socket is root:docker,
  mode srw-rw----).

### Build & cache
- .dockerignore's effect depends entirely on how broad COPY is - invisible
  with a narrow COPY app.py ., dramatic (52MB -> 254B) with COPY . .
- A cache miss cascades forward - one changed layer invalidates every
  layer after it even if their own inputs never changed. Ordering
  dependency manifests before application source avoids unnecessary
  reinstalls (measured 1.1s->4.8s vs. 1.1s->1.5s for the same edit).
- The build cache lives in the daemon, not the shell - clearing bash
  history does nothing to it.
- --no-cache (rerun everything, ignore base image state) and --pull (only
  recheck the registry for a newer base image) solve different problems -
  measured 7.1s vs. 0.7s for the same Dockerfile.

### Storage
- A named volume outlives the container that mounts it; only docker
  volume rm on the volume itself destroys the data.
- A typo'd volume name fails silently - Docker creates a fresh empty
  volume under the misspelled name with no error at all.
- docker exec runs as the image's default user unless -u is given -
  always pass -U/-d explicitly for tools like psql.

### Networking
- localhost inside a container never means a sibling container - every
  container has its own private network namespace/loopback.
- Network membership is live-editable - docker network
  connect/disconnect change a running container's DNS resolvability with
  zero recreation.
- Compose creates its own project-scoped network automatically - no
  networks: block needed for services to resolve each other by name.
- A Compose project is named after its directory's basename only, not
  full path - two unrelated directories sharing a name collide on
  containers/networks/orphan detection.
- Alpine's /etc/hosts maps localhost to both IPv4 and IPv6 - an app bound
  only to the IPv4 wildcard can silently fail an internal healthcheck that
  happens to try IPv6 first, while the host's dual-stack-published port is
  unaffected.

### Debugging
- The reliable diagnostic sequence: docker ps -a -> docker logs -> docker
  inspect -> docker diff -> docker events. Diagnosed three unrelated
  deliberate failures (wrong password, wrong bind address, typo'd CMD)
  with this same flow, without rebuilding and hoping.
- A base image's own entrypoint script can rewrite a broken CMD before it
  reaches the OS (confirmed in node:22-alpine) - a typo can produce a
  completely different failure mode (MODULE_NOT_FOUND, exit 1) than the
  "command not found" (exit 127) you'd expect.
- RestartCount only tracks restart-policy-triggered relaunches - a
  daemon/WSL restart relaunching a container does not increment it.
- A hardcoded log string is not proof of runtime state - verify against
  docker inspect or actual behavior, never a literal log line.

### Production hardening & security
- OOMKilled: true (from docker inspect) is the actual confirmation of a
  memory-kill - exit 137 alone only means "force-killed by some signal."
- docker stats --no-stream can completely miss a crash loop if sampled
  between restarts - docker inspect is the ground truth.
- A digest-pinned base image is a deliberate tradeoff: it can't
  self-patch. The real fix for an OS-level CVE is patching packages at
  build time, independent of the base image's own release cadence.
- Fixing a CVE doesn't make a package clean forever - re-scan after every
  change; a fix can surface different, unrelated, lower-severity CVEs on
  the same package.
- docker scout requires Docker Desktop; Trivy (container-based, no
  install needed) is the equivalent for an Engine-only setup.

---

## 6. Open items (never fully resolved)

- 01-node-postgres's image is 255MB against a 200MB target - the
  multi-stage technique that fixed this for project 03 was never carried
  back to project 01.
- The .dockerignore-protects-a-broken-cache scenario (an untracked file
  breaking a broad-COPY build's cache, then .dockerignore fixing it) was
  reasoned through but never actually run.
- A "Mode":"z" label appeared on a plain named-volume mount despite
  SELinux being disabled on this machine - unexplained.

---

## 7. Repo layout (for context)

```text
docker-labs/
- cheatsheets/       Reference notes (concepts, commands, quick reference)
- daily-summary/     Long-form notes, one file per day (7 fixed sections each)
- examples/          Minimal working stacks (nginx+Postgres, first Dockerfile)
- projects/          01-node-postgres, 02-python-redis, 03-react-multistage
- .github/workflows/ CI: hadolint, Compose validation, image builds
- JOURNAL.md         Narrative log, one entry per day
- README.md          Public front page, progress table, mental-model diagrams
```

Full repo: https://github.com/sagarsaitwal/docker-labs
