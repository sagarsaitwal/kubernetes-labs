# LAB 01 — Set Up the Kubernetes Learning Environment

Author: Sagar Saitwal

Status: NOT STARTED

---

## Objective

Install `kubectl` and `kind`, create a working multi-node Kubernetes cluster
inside WSL2, and verify it is genuinely healthy — not merely "created".

By the end you should be able to answer: *how do I prove a cluster is working,
rather than assume it?*

---

## Prerequisites

Confirmed present on this machine (verified 2026-09-16):

| Requirement | Status |
|---|---|
| WSL2 (not WSL1) | FedoraLinux-44, version 2 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| cgroup v2 unified | `cgroup2fs` |
| Docker daemon reachable without sudo | Engine 29.7.2 |
| Free memory | 7.0 GiB available |
| Free disk | 952 GiB |
| Architecture | x86_64 |

Re-verify before starting, since WSL was restarted:

```bash
stat -fc %T /sys/fs/cgroup    # expect: cgroup2fs
docker info >/dev/null && echo "docker OK"
free -h | awk '/Mem:/ {print $7 " available"}'
```

---

## Why kind, and not the alternatives

| Option | Verdict for this lab |
|---|---|
| **kind** — nodes are Docker containers | **Chosen.** Reuses the Docker Engine already installed and proven. Multi-node in seconds. Cluster creation is fast enough to destroy and rebuild freely — which matters when the curriculum deliberately breaks things |
| **minikube** | Works, but its default driver wants a VM or its own Docker layer. More moving parts for no extra learning here |
| **k3s** | Excellent and lightweight, but it *differs* from upstream Kubernetes (Traefik built in, SQLite instead of etcd by default). Wrong choice while learning what stock Kubernetes does |
| **kubeadm** | The most instructive, and deliberately deferred to Module 22. Building a cluster by hand before knowing what the components do teaches sequence, not understanding |
| **EKS / AKS / GKE** | Costs money, slower feedback loop, and hides the control plane — the exact thing being studied. Modules 23-24 |

### What kind actually does

```text
    Your WSL2 Fedora host
    +---------------------------------------------------+
    |  Docker Engine 29.7.2                             |
    |                                                   |
    |  +---------------------+  +--------------------+  |
    |  | container:          |  | container:         |  |
    |  | k8s-control-plane   |  | k8s-worker         |  |
    |  |                     |  |                    |  |
    |  |  containerd         |  |  containerd        |  |
    |  |   +-- kube-apiserver|  |   +-- your Pods    |  |
    |  |   +-- etcd          |  |                    |  |
    |  |   +-- scheduler     |  |  kubelet           |  |
    |  |   +-- controller-mgr|  |  kube-proxy        |  |
    |  |  kubelet            |  |                    |  |
    |  +---------------------+  +--------------------+  |
    |            |                       |              |
    |            +------ docker network -+              |
    +---------------------------------------------------+
```

A Kubernetes "node" here is a Docker container running containerd, which in turn
runs your Pods' containers. **Containers inside containers.** This is worth
holding onto, because it explains several kind-specific behaviours later —
notably why `NodePort` needs explicit port mapping and why images must be loaded
into the cluster rather than just existing in your local Docker.

---

## Architecture you are building

```text
                         kubectl (on WSL host)
                                  |
                                  v
    +-------------------------------------------------------+
    |  k8s-lab-control-plane                                |
    |  kube-apiserver, etcd, scheduler, controller-manager  |
    +-------------------------------------------------------+
                    |                     |
            +-------+-------+     +-------+-------+
            | k8s-lab-worker|     | k8s-lab-worker2|
            | kubelet       |     | kubelet        |
            | kube-proxy    |     | kube-proxy     |
            +---------------+     +----------------+
```

---

## Task 1 — Install kubectl

`kubectl` is the CLI that talks to the kube-apiserver. Nothing else in this
curriculum works without it.

```bash
cd /tmp

# Resolve the current stable Kubernetes version
KVER=$(curl -Ls https://dl.k8s.io/release/stable.txt)
echo "installing kubectl ${KVER}"

# Download the binary and its checksum
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl.sha256"

# Verify integrity BEFORE installing
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```

**Command breakdown:**

| Part | Meaning |
|---|---|
| `curl -Ls .../stable.txt` | `-L` follow redirects, `-s` silent. Returns the current stable version string, e.g. `v1.34.1` |
| `curl -LO <url>` | `-O` save using the remote filename |
| `sha256sum --check` | Confirms the downloaded binary matches the published hash |

**The checksum step is not optional ceremony.** During the Docker phase you
pinned a base image by digest and ran Trivy scans — this is the same supply-chain
reasoning applied to a binary you are about to run with your own privileges. A
silently corrupted or substituted `kubectl` would be an excellent thing for an
attacker to own.

If and only if the check prints `kubectl: OK`:

```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

**Expected output** (version will differ):

```text
Client Version: v1.34.1
Kustomize Version: v5.x.x
```

> `kubectl version` without `--client` will try to reach a cluster and report an
> error. That is correct — no cluster exists yet.

---

## Task 2 — Install kind

```bash
cd /tmp

# Pick the current kind release explicitly rather than 'latest'
KIND_VER=$(curl -Ls https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
           | grep -oP '"tag_name": "\K[^"]+')
echo "installing kind ${KIND_VER}"

curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
```

**Expected output:**

```text
kind vX.Y.Z go1.xx.x linux/amd64
```

---

## Task 3 — Understand the cluster configuration

The file is already written: `fundamentals/labs/kind-cluster-config.yaml`

You do not need to change it. You *do* need to understand why it says what it
says, because this is the first real Kubernetes design decision in the course and
the reasoning pattern repeats constantly afterwards.

### What the file declares

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: k8s-lab
nodes:
- role: control-plane
- role: worker
- role: worker
```

Three list entries, therefore three nodes, therefore three Docker containers:

```text
k8s-lab-control-plane    kube-apiserver, etcd, scheduler, controller-manager
k8s-lab-worker           kubelet, kube-proxy — runs your Pods
k8s-lab-worker2          kubelet, kube-proxy — runs your Pods
```

### Why three nodes and not one

kind will happily build a single-node cluster with no config at all
(`kind create cluster`), where one node is both control plane and worker. That
is a legitimate setup and many tutorials use it.

It was rejected here for one reason: **Kubernetes' central job is deciding which
machine runs a workload.** With one node, that decision has exactly one possible
answer. The scheduler still runs, but you can never watch it do anything.

These stop being observable:

| Feature | On 1 node | On 3 nodes |
|---|---|---|
| `nodeSelector`, node affinity | Always picks the only node | Actually selects |
| Pod anti-affinity | Silently unsatisfiable | Visibly spreads replicas |
| Topology spread constraints | No-op | Real distribution |
| DaemonSet — "one Pod per node" | Indistinguishable from a Deployment | Obviously different |
| **Node failure and rescheduling** | **Impossible** — killing the node kills the cluster | `docker stop` a worker and watch |

The last row decides it. Surviving a node failure is the single most important
thing Kubernetes does, and the clearest answer to "why not just use Compose?".
On one node it can only be read about.

### What it costs

| Item | Cost |
|---|---|
| control-plane node | ~600 MiB |
| each worker node | ~300 MiB |
| **total** | **~1.2 GiB of 7.0 GiB available** |
| startup time | ~60-90s instead of ~30s |

Module 17 later adds Prometheus and Grafana to this same cluster. It still fits.

### Why two workers and not three

Two is the minimum that makes "spread across nodes" a real outcome rather than a
tautology. A third worker costs memory without demonstrating anything new yet.

### This is reversible

`kind delete cluster --name k8s-lab` destroys it; recreating takes about a
minute. Nothing here is a commitment. **Revisit this choice after Module 11**,
when you will have enough scheduling knowledge to disagree with the reasoning
above — and disagreeing with it at that point would itself be a good sign.

---

## Task 4 — Create the cluster

```bash
kind create cluster --name k8s-lab \
  --config "$KLAB/fundamentals/labs/kind-cluster-config.yaml"
```

| Flag | Meaning |
|---|---|
| `--name k8s-lab` | Names the cluster. Without it you get `kind`, and the kubeconfig context becomes `kind-k8s-lab` |
| `--config <file>` | Uses the declared 3-node topology instead of the single-node default |

> **`$KLAB` is the repository root on this machine.** It is set in `~/.bashrc` by
> `scripts/utilities/setup-machine.sh`. The repository sits at a different
> absolute path on each machine, so no lab in this repository ever hard-codes
> one. If `echo $KLAB` prints nothing, run `source ~/.bashrc`, or re-run the
> setup script. See `progress/environments.md`.

**Expected output shape:**

```text
Creating cluster "k8s-lab" ...
 ✓ Ensuring node image (kindest/node:vX.Y.Z)
 ✓ Preparing nodes
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
 ✓ Joining worker nodes
Set kubectl context to "kind-k8s-lab"
```

> Note the line **`Installing CNI`**. kind installs `kindnet` — a minimal
> Container Network Interface plugin — because a Kubernetes cluster has **no pod
> networking at all** until a CNI is installed. Nodes would sit `NotReady`
> forever. This is worth remembering: it is the single most common reason a
> hand-built (`kubeadm`) cluster appears broken, and you will meet it again in
> Module 22.

---

## Verification

**Do not skip to the next lesson after `create cluster` succeeds.** "Created"
is not "healthy" — this is the same lesson as `kubectl apply` printing
`created`.

Run each of these and record the real output:

```bash
# 1. Is the API server reachable, and do versions match?
kubectl version

# 2. Do all nodes exist and report Ready?
kubectl get nodes -o wide

# 3. Are the control plane components actually running?
kubectl get pods -n kube-system

# 4. What does kubectl consider the current cluster?
kubectl config current-context

# 5. What does the cluster say about itself?
kubectl cluster-info

# 6. What does Docker see? (the layer underneath)
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

### What "healthy" looks like

- Every node in `kubectl get nodes` shows `Ready`. Not `NotReady`, not
  `SchedulingDisabled`.
- In `kube-system`, every Pod is `Running` or `Completed` — expect `etcd`,
  `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `coredns` (x2),
  `kube-proxy` (one per node), `kindnet` (one per node).
- `docker ps` shows one container per node you declared.

### Questions to answer from that output

Answer these before moving on — they are the actual point of the lab:

1. `kubectl get pods -n kube-system` — **why is there one `kube-proxy` and one
   `kindnet` Pod per node, but only one `etcd`?** What kind of object creates
   the per-node ones?
2. Compare `kubectl get nodes` to `docker ps`. **What is the relationship
   between a row in one and a row in the other?**
3. `coredns` shows 2 replicas. **Why two, and what breaks if both are on the
   same node and that node dies?**
4. On the control-plane node, the components run as Pods — but **who starts
   them, given the API server is itself one of them?** (This is a genuine
   chicken-and-egg problem with a specific name. Find it.)

---

## Troubleshooting

Consult only if something fails.

| Symptom | Likely cause | Check |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker not started after WSL restart | `sudo systemctl start docker` |
| `permission denied ... docker.sock` | User not in `docker` group, or group not applied to this shell | `groups`, then re-login |
| Node stuck `NotReady` | CNI failed to install | `kubectl describe node <name>`, look at `Conditions` |
| `failed to create cluster: ... cgroup` | cgroup v1 or read-only cgroup mount | `stat -fc %T /sys/fs/cgroup` must be `cgroup2fs` |
| Cluster creation hangs at `Starting control-plane` | Insufficient memory | `free -h`, reduce node count |
| `kubectl` connects to the wrong cluster | Multiple contexts in kubeconfig | `kubectl config get-contexts` |
| Image pull is very slow | First run downloads the `kindest/node` image (~1 GB) | Expected once; cached after |

### Diagnostic escalation order

Apply the same discipline as the Docker phase (`ps -a` → `logs` → `inspect` →
`diff` → `events`). The Kubernetes equivalent:

```text
kubectl get <object>          what state is it in?
kubectl describe <object>     why? (Events are at the bottom -- read them)
kubectl logs <pod>            what did the application itself say?
kubectl get events --sort-by=.lastTimestamp    what happened cluster-wide?
```

For kind specifically, one layer deeper:

```bash
docker logs k8s-lab-control-plane     # the node container's own logs
docker exec -it k8s-lab-control-plane crictl ps   # containerd's view, inside the node
```

---

## Cleanup

Not needed now — this cluster is used for every subsequent module. Recorded for
completeness:

```bash
kind delete cluster --name k8s-lab     # destroys the cluster entirely
kind get clusters                      # confirm it is gone
```

**This is destructive and irreversible.** Everything in the cluster is lost.
Since all state will live in YAML in this repository, recreating is cheap — which
is precisely why kind was chosen.

---

## Challenge

After the cluster is `Ready`:

> Run `docker stop k8s-lab-worker2` (or whichever worker you declared last).
>
> **Before** running any `kubectl` command, write down your prediction:
> 1. How long until `kubectl get nodes` shows it as `NotReady`?
> 2. What, specifically, notices? Name the component.
> 3. If Pods had been running on it, what would happen to them, how quickly, and
>    which component would act?
>
> Then observe what actually happens and compare against the prediction.
>
> Restore with `docker start k8s-lab-worker2`.

Record the prediction **and** the outcome in the journal, including the parts
you got wrong. A wrong prediction that you then understand is worth more than a
right one you guessed.

---

## On completion

This lab is `COMPLETED` only when:

- [ ] `kubectl version` returns both client and server versions
- [ ] All three nodes report `Ready`
- [ ] All `kube-system` Pods are `Running`
- [ ] The four verification questions are answered
- [ ] The challenge prediction was written down, tested, and recorded

Then update:

- `progress/current-progress.md`
- `progress/completed-topics.md`
- `journal/daily/day-01-cluster-setup.md` — with **real** output, not
  expected output
- `journal/learning-journal.md`
- `journal/mistakes-and-lessons.md` if anything broke
