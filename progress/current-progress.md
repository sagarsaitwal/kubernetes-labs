# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-16

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 02**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## ⚠️ Read this first if you are on a different machine

The last session ended on **Machine 1 (IT-SAGARS)** with a running cluster.

**Clusters do not travel between machines.** On a different device the cluster
will not exist, and that is expected — not a failure. Recreate it:

```bash
cd /mnt/d/Kubernetes && git pull
bash scripts/utilities/check-dependencies.sh

cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

Nothing has been deployed into the cluster yet, so nothing else needs
reinstalling. See `progress/dependencies.md`.

---

## Current Module

Module 01 — Kubernetes Fundamentals

## Current Topic

Day 01 complete. Next: Day 02 — Control Plane vs Worker Node

## Current Subtopic

Inspecting control plane components on a live cluster

## Learning Status

🟡 IN PROGRESS

Day 00 and Day 01 are done apart from one outstanding item: the LAB 01 challenge
(deliberately stopping a worker node) has **not** been attempted.

## Last Completed Lab

**LAB 01 — Set up the Kubernetes learning environment.** Partially completed.

Cluster created and fully verified. The break/fix challenge is outstanding.

## Last Commands Practiced

```bash
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
kubectl version                       # client AND server — skew is ±1 minor
kubectl get nodes -o wide             # -o wide exposes kernel, OS, runtime
kubectl get pods -n kube-system       # -n required; default namespace is 'default'
kubectl config current-context        # which cluster am I about to affect?
kubectl cluster-info                  # API endpoint
docker ps                             # the layer underneath the nodes
```

## Last YAML Practiced

`fundamentals/labs/kind-cluster-config.yaml` — 3-node kind cluster
(1 control-plane + 2 workers).

## What I Learned

- **A node is a container, not a machine.** Nodes report Debian 13 while the host
  is Fedora, and all three share the host's WSL2 kernel — the same shared-kernel
  model proven during the Docker phase.
- **A Pod's name reveals what created it.** Node-name suffix = static Pod;
  one random suffix = DaemonSet; two suffixes = Deployment (ReplicaSet hash, then
  Pod hash).
- **Static Pods solve the bootstrap problem.** The kubelet starts Pods directly
  from `/etc/kubernetes/manifests/` with no API server involved, which is how
  `etcd` and `kube-apiserver` start before the cluster exists. Their visible
  `kubectl` entries are read-only *mirror Pods*.
- **DaemonSets exist for node-local work.** `kube-proxy` writes iptables rules
  into its own node's kernel; `kindnet` configures its own node's network.
  Neither can be done remotely.
- **Replica count is not redundancy.** Two CoreDNS Pods on one node is a single
  node failure away from total cluster DNS loss. Separate failure domains are
  what matter.
- **`created` is not `healthy`.** Cluster state is confirmed by querying it,
  never by trusting a success message.

## What I Broke

Nothing yet. No failure has been induced, which is exactly why the LAB 01
challenge is still outstanding.

## Errors Encountered

None affecting the cluster.

## Root Cause

N/A

## How It Was Fixed

N/A

## Mistakes Made

- Typed `kubctl`, then tried `sudo kubctl`. **`command not found` is never a
  permissions problem** — the shell resolves the name against `$PATH` before
  permissions are ever checked. `command not found` means wrong name or wrong
  `$PATH`; `Permission denied` means the file was found but is not executable.

## Important Lessons

- Verify a downloaded binary's checksum before installing it as root. Note the
  limit: it proves integrity, not authenticity — the binary and its hash came
  from the same host. Real authenticity needs signature verification (Day 107).
- `kubectl` sends every command to whatever context is current. Check
  `kubectl config current-context` before anything destructive, and always after
  switching machines.

## Unresolved Issues

1. **LAB 01 challenge not attempted** — stop a worker node, predict the outcome
   *before* observing, then compare.
2. Two containers from the Docker phase (`day14-api-1`, `day14-redis-1`) are
   still running on Machine 1, consuming memory against a 7.6 GiB budget.

## Next Topic

Day 02 — Control Plane vs Worker Node, inspected on the live cluster.

## Next Lab

LAB 02 — Inspect the control plane components running inside the kind cluster.

Before that, three things carried over from Day 01:

```bash
# 1. The LAB 01 challenge — write predictions BEFORE running kubectl
docker stop k8s-lab-worker2

# 2. See static Pod manifests directly on disk
docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/

# 3. Did both CoreDNS replicas land on the same node?
kubectl get pods -n kube-system -o wide | grep coredns
```

## Overall Progress

Day 01 of 130 complete. 0 of 30 modules completed, 1 in progress.
0 of 10 projects.

```text
[                              ] 1%
```

Full day-by-day plan: `progress/daily-plan.md`
