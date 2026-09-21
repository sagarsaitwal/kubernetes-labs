# Completed Topics

Author: Sagar Saitwal

A topic appears here **only** after theory was understood, the lab was run, and
verification output was actually seen. Nothing is added optimistically.

---

## Kubernetes

| Date | Day | Module | Topic | Lab | Verification |
|---|:--:|---|---|---|---|
| 2026-09-16 | 00 | 01 | What is Kubernetes; reconciliation loop; control plane vs nodes | — | Theory understood; carried into Day 01 by reading live cluster output |
| 2026-09-16 | 01 | 01 | Cluster creation, node anatomy, static Pods, DaemonSets, node failure detection (heartbeat/Lease/taints) | LAB 01 (full, incl. challenge) | 3 nodes `Ready`, 12 `kube-system` Pods `Running`, client/server both v1.37.0; challenge: predicted ~40s, observed 44s to `NotReady`, `node-controller` confirmed via Events, DaemonSet Pods confirmed never evicted, full recovery observed |
| 2026-09-16 / 2026-09-18 | 02 | 01 | Control plane vs worker node — node-failure mechanism (Nero); static Pod manifests, stateless vs stateful test, two HA mechanisms, CoreDNS placement (IT-SAGARS) | Self-directed inspection of live cluster, no formal lab file | All 4 static manifests confirmed on disk; 3 read in full with flags matched against theory; CoreDNS gap found and root-caused with corroborating restart-count evidence |
| 2026-09-18 | 03 | 01 | Architecture and the request flow — applied a real Deployment, traced steps 6-14 (+ partial 4) of the request-flow theory live | Self-directed trace exercise, no formal lab file | `kubectl get rs`/`get pods`/`describe pod` evidence for ReplicaSet creation, scheduling (`default-scheduler` named), image pull/create/start timing (10s total), and auto-injected tolerations proving admission ran; control-plane taint and CoreDNS's toleration for it both confirmed directly |
| 2026-09-21 | 04 | 01 | kubectl core verbs and output formats — `-o yaml`, `-o jsonpath`, `--dry-run=server`, `-o custom-columns` + `--sort-by`, `logs`, `exec` | Self-directed exercise against `nginx-trace`, no formal lab file | All 6 commands run and interpreted against a live Deployment; found `--dry-run=server` only previews admission on the submitted object, not on objects a controller creates afterward; recovered a stopped node container; diagnosed and fixed a real `ErrImagePull` (Zscaler TLS interception) via `describe pod` Events |

### Findings recorded, fix deliberately deferred

| Item | Where recorded | Fix scheduled |
|---|---|---|
| Both CoreDNS replicas on one node (`k8s-lab-control-plane`) — verified real single point of failure, and now explained (explicit toleration for the control-plane taint) | `journal/daily/day-02-control-plane-and-nodes.md`, `day-03-architecture-request-flow.md` | Day 34 (`required` anti-affinity) / Day 36 (topology spread) |

### Not yet complete

| Item | Why it is not marked complete |
|---|---|
| Request-flow steps 1-3, 5 (auth, authz, etcd write) | No tooling yet to observe directly — deferred to Day 39-41, 45, 65/80 |
| Day 05 — Namespaces, labels, selectors, annotations | Not yet started |

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
