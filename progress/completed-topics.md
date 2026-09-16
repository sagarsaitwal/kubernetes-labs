# Completed Topics

Author: Sagar Saitwal

A topic appears here **only** after theory was understood, the lab was run, and
verification output was actually seen. Nothing is added optimistically.

---

## Kubernetes

| Date | Day | Module | Topic | Lab | Verification |
|---|:--:|---|---|---|---|
| 2026-09-16 | 00 | 01 | What is Kubernetes; reconciliation loop; control plane vs nodes | — | Theory understood; carried into Day 01 by reading live cluster output |
| 2026-09-16 | 01 | 01 | Cluster creation, node anatomy, static Pods, DaemonSets | LAB 01 (partial) | 3 nodes `Ready`, 12 `kube-system` Pods `Running`, client and server both v1.37.0 |

### Not yet complete

| Item | Why it is not marked complete |
|---|---|
| LAB 01 challenge | Stopping a worker node and predicting the outcome has not been attempted |

---

## Prerequisite phase (Docker) — completed before this repository

Completed 2026-09-16. Full detail in `Reference/DockerSummary.md`.
Source repository: https://github.com/sagarsaitwal/docker-labs

| Days | Topic | Status |
|---|---|---|
| 0 | Engine install, daemon, socket permissions, docker group | COMPLETED |
| 1 | Container lifecycle, exit codes, signals | COMPLETED |
| 2 | Runtime configuration, env vars, restart policies | COMPLETED |
| 3 | Images, tags vs digests, manifest lists, registries | COMPLETED |
| 4 | First Dockerfile, PID 1, signal handling, --init | COMPLETED |
| 5 | Layer caching, cache invalidation, .dockerignore | COMPLETED |
| 6 | Named volumes, data persistence lifecycles | COMPLETED |
| 7 | Bind mounts, UID mismatches, live reload | COMPLETED |
| 8 | Container networking, embedded DNS | COMPLETED |
| 9 | Docker Compose, implicit network, down vs down -v | COMPLETED |
| 10 | Multi-service stack, depends_on service_healthy | COMPLETED |
| 11 | Debugging flow: logs, inspect, diff, events | COMPLETED |
| 12 | Multi-stage builds, image size reduction | COMPLETED |
| 13 | Publishing to Docker Hub, content verification | COMPLETED |
| 14 | Production hardening, non-root, limits, healthchecks, CVE scanning | COMPLETED |

### Docker knowledge that carries directly into Kubernetes

This table is the reason the Kubernetes phase does not restart from container
basics. Each row is a concept already proven by hand during the Docker phase.

| Docker concept already verified | Kubernetes concept it unlocks |
|---|---|
| Container is not a VM; kernel shared, userland is not | Why containers in one Pod can share a network namespace |
| Image layers, tags vs digests, digest pinning | Image pull policy, ImagePullBackOff, supply-chain security |
| Named volume outlives its container | PersistentVolume / PersistentVolumeClaim reclaim policies |
| Bind mount does no UID translation | securityContext runAsUser / fsGroup, hostPath volumes |
| Only a user-defined network gets DNS | CoreDNS, Service discovery, why a ClusterIP name resolves |
| depends_on waits for started, not ready | Readiness probes and init containers |
| A HEALTHCHECK only proves what its own command tests | Liveness vs readiness probe design mistakes |
| Exit 137 alone does not mean OOM; inspect confirms it | Diagnosing OOMKilled containers inside a Pod |
| PID 1 ignores unhandled SIGTERM | terminationGracePeriodSeconds, preStop hooks |
| Environment is fixed at container creation | Why changing a ConfigMap does not restart Pods by itself |
| Environment variables are not secrets | Why Kubernetes Secrets are only base64, not encrypted at rest by default |

### Open items carried over from the Docker phase

These were never resolved and are recorded so they are not silently forgotten.
They belong to the `docker-labs` repository, not this one.

1. `01-node-postgres` image is 255MB against a 200MB target. The multi-stage
   technique that fixed project 03 was never carried back.
2. The `.dockerignore`-protects-a-broken-cache scenario was reasoned through
   but never actually run.
3. A `"Mode":"z"` label appeared on a plain named-volume mount despite SELinux
   being disabled. Unexplained.
