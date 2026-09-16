# Day 00 — Setup and What Is Kubernetes

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-16 |
| **Day** | 00 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Repository setup, environment verification, Lesson 01 |
| **Status** | PARTIALLY COMPLETED |
| **Cluster** | None — does not exist yet |

---

## Today's Objective

Establish the learning repository, verify that this machine can actually run a
Kubernetes cluster, and work through Module 01 Lesson 01 — what Kubernetes is
and why it exists.

Day 1 of the Kubernetes phase, immediately following completion of a 14-day
Docker phase.

## Module

Module 01 — Kubernetes Fundamentals

## Section

Repository setup and environment verification

## Topic

Lesson 01 — What is Kubernetes and why do we need it?

## Subtopic

Lab environment feasibility check

---

## Theory Learned

Lesson 01 is written to `fundamentals/01-what-is-kubernetes.md`, covering:

- Kubernetes as a reconciliation loop: desired state vs current state
- Declarative vs imperative, and why `restart: always` was a tiny version of it
- What Kubernetes solves that Docker Compose does not — and when Compose is
  still the correct answer
- Kubernetes vs Docker vs Docker Compose, including what the dockershim removal
  in v1.24 actually meant
- Control plane and node components, and the hub-and-spoke design where every
  component watches the API server rather than commanding each other
- The full path of `kubectl apply -f deployment.yaml` through the system
- Why a Pod is not a container

Not yet discussed or tested, so **not marked as understood**. The knowledge
check in section 11 of the lesson is unanswered.

## Why It Matters

The Docker phase ended at Docker Compose — a single host, manually started, with
no rescheduling if that host dies. Every limitation reached there is a problem
Kubernetes exists to solve.

Starting Kubernetes without first naming those limitations produces command
memorisation instead of understanding. The point of Lesson 01 is to arrive at
Pods and Deployments already knowing *what problem they are the answer to*.

---

## Commands Used

No Kubernetes commands were run today — no cluster exists and `kubectl` is not
installed. Today's commands were environment verification only.

### `wsl --list --verbose`

Run from Windows PowerShell.

- **What it does:** lists installed WSL distributions with their run state and
  WSL version (1 or 2).
- **Why used:** kind requires WSL2. WSL1 has no real Linux kernel and cannot run
  a container-based Kubernetes node.
- **Result:** `FedoraLinux-44`, `Stopped`, version `2`. Suitable.

### `uname -r`

- **What it does:** prints the running kernel release.
- **Why used:** the kernel is shared with every container, and therefore with
  every kind node. Kubernetes features depend on kernel capability.
- **Result:** `6.18.33.2-microsoft-standard-WSL2`.

### `stat -fc %T /sys/fs/cgroup`

- **What it does:** prints the filesystem type mounted at `/sys/fs/cgroup`.
- **Why used:** this is the single most important pre-flight check for kind on
  WSL2. kind runs each Kubernetes node as a container, and the kubelet inside it
  needs a writable cgroup hierarchy to enforce Pod resource limits.
- **Result:** `cgroup2fs` — unified cgroup v2. Clean. `tmpfs` would have
  indicated the older hybrid v1 layout, which historically broke kind nodes at
  kubelet startup.

### `docker version --format '{{.Server.Version}}'`

- **What it does:** queries the Docker daemon for its server version.
- **Why used:** kind runs each Kubernetes node as a Docker container. If the
  daemon is unreachable, kind cannot create anything.
- **Result:** `29.7.2`, client and server, reachable without `sudo`.

### `nproc` and `free -h`

- **Why used:** cluster size is bounded by these. A kind control-plane node idles
  around 500-700 MiB; each worker around 300 MiB.
- **Result:** 8 CPUs, 7.6 GiB total memory, 7.0 GiB available.

### `command -v kubectl kind minikube helm k3d kubeadm`

- **What it does:** resolves each name to a path, or returns nothing.
- **Why used:** establish the true starting point rather than assume it from the
  Docker phase summary.
- **Result:** all six NOT INSTALLED. Starting from zero.

---

## YAML / Configuration

One file created: `fundamentals/labs/kind-cluster-config.yaml`

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: k8s-lab
nodes:
- role: control-plane
- role: worker
- role: worker
```

**Topology chosen: 1 control-plane + 2 workers.**

Reasoning, recorded so it can be challenged later:

- Kubernetes' central job is deciding *which* machine runs a workload. On a
  single-node cluster that decision has one possible answer, so the scheduler
  can never be observed doing anything.
- A single node makes `nodeSelector`, node affinity, pod anti-affinity, and
  topology spread constraints unobservable, and makes a DaemonSet
  indistinguishable from a Deployment.
- Most importantly, a single node makes **node failure and rescheduling
  impossible to demonstrate** — killing the node kills the cluster. Surviving a
  node failure is the clearest answer to "why not just use Compose?", so being
  unable to watch it happen would undercut the whole point.
- Cost: ~1.2 GiB of 7.0 GiB available, and ~60-90s startup instead of ~30s.
  Module 17 adds Prometheus and Grafana to this same cluster and still fits.
- Two workers rather than three: two is the minimum that makes "spread across
  nodes" a real outcome rather than a tautology.

Reversible — `kind delete cluster` and rebuild takes about a minute. To be
revisited after Module 11, when there is enough scheduling knowledge to disagree
with the reasoning above.

Note on the file itself: it carries `apiVersion` and `kind` fields and looks
exactly like a Kubernetes manifest, but it is read by the kind CLI on this
machine and never reaches an API server. Kubernetes' YAML conventions were
borrowed by its whole tooling ecosystem — "looks like a manifest" is not the
same as "is a manifest".

---

## Lab Performed

None. LAB 01 is defined in `fundamentals/labs/lab-01-lab-environment-setup.md`
but has **not** been performed.

---

## Environment

| Item | Value |
|---|---|
| Host OS | Windows 11 Pro 10.0.26200 |
| Linux | WSL2, FedoraLinux-44 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| systemd | active |
| Container runtime | Docker Engine 29.7.2 (in-distro, not Docker Desktop) |
| CPU | 8 |
| Memory | 7.6 GiB total / 7.0 GiB available |
| Disk free | 952 GiB |
| Kubernetes version | None — no cluster exists |
| Node count | 0 |
| CNI | None yet |
| Cluster type | None yet |

---

## Expected Result

A repository skeleton, verified environment facts, and Lesson 01 written.

## Actual Result

Matched. Repository structure created (105 directories), all core documentation
files in place, environment verified end to end, Lesson 01 and LAB 01 written.

---

## What Worked

- The environment was verified directly rather than assumed from the Docker
  phase summary — worth doing, since WSL had been restarted since then.
- The machine turned out to be unusually well suited to kind: cgroup v2 unified,
  systemd active, Docker Engine reachable without `sudo`, 952 GiB free disk.
- Running Docker Engine in-distro rather than Docker Desktop means there is no
  bundled single-node Kubernetes to inherit. Every cluster from here is created
  explicitly, so every setting is visible rather than preconfigured.

## What Failed

Nothing. No lab was run, so there was nothing to fail yet.

---

## What I Broke

Nothing yet. There is no cluster to break.

---

## Error Message

None.

---

## Investigation

Not applicable today.

---

## Root Cause

Not applicable today.

---

## Solution

Not applicable today.

---

## Verification

Environment facts were each confirmed by a command whose output is recorded
above, rather than carried forward from `Reference/DockerSummary.md`. The
critical one — `stat -fc %T /sys/fs/cgroup` returning `cgroup2fs` — is what
makes LAB 01 viable at all.

---

## Mistake

None recorded today.

---

## Lesson Learned

**The `apply` boundary.** Tracing `kubectl apply -f deployment.yaml` through the
system, the command returns `created` at step 6 of 14 — the moment the API
server stores the object in etcd. Everything after that (ReplicaSet creation,
Pod creation, scheduling, image pull, container start) happens asynchronously
and can fail independently.

So `created` means *the API server accepted and stored the object*. It says
nothing about whether anything is running, scheduled, pullable, or healthy.

This is the Kubernetes form of a lesson already proven during the Docker phase:
*a hardcoded log string is not proof of runtime state*.

---

## Troubleshooting Knowledge

**Symptom:** a command reports success, but the application is not working.

**Principle:** confirm state by querying the system, never by trusting the
message that a write succeeded.

The Docker diagnostic sequence maps directly onto Kubernetes:

| Docker phase | Kubernetes equivalent |
|---|---|
| `docker ps -a` | `kubectl get <object>` — what state is it in? |
| `docker inspect` | `kubectl describe <object>` — why? Events are at the bottom |
| `docker logs` | `kubectl logs <pod>` — what did the application itself say? |
| `docker events` | `kubectl get events --sort-by=.lastTimestamp` |

---

## Interview Questions

1. Why is Kubernetes needed when Docker Compose already runs multi-container
   applications?
2. What does Kubernetes actually do that a container runtime does not?
3. What is the difference between desired state and current state, and what
   closes the gap?
4. Why does kind require WSL2 rather than WSL1?
5. `kubectl apply` printed `created`. Name three things that could still go
   wrong afterwards, and the component responsible for each.

*Answers not recorded — these are to be answered from understanding, not lookup.*

---

## Challenge

From the Docker phase, project `01-node-postgres` used
`depends_on: condition: service_healthy` to fix a real startup race.

> If the host running that Compose stack rebooted, what would restore the
> application — and what would it **not** restore?

The gap in that answer is the reason Kubernetes exists.

Attempted: not yet.

---

## End-of-Day Status

PARTIALLY COMPLETED

| Item | State |
|---|---|
| Repository structure | Done |
| Core documentation files | Done |
| Environment verification | Done |
| Lesson 01 theory | Written, not yet tested |
| Lesson 01 knowledge check | Not attempted |
| LAB 01 | Defined, not performed |
| Cluster | Does not exist |

---

## Next Session

Next journal file: `journal/daily/day-01-cluster-setup.md`

1. Perform LAB 01 — install `kubectl` and `kind`, create the 3-node cluster,
   verify with `kubectl get nodes`, answer the four verification questions.
2. Attempt the LAB 01 challenge: predict what happens when a worker node is
   stopped, *before* observing it.
3. Record real output — not expected output.
4. Proceed to Lesson 02 — Control Plane vs Worker Node, inspected on the real
   cluster.
