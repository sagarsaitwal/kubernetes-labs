# Day 01 — Cluster Setup

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-16 |
| **Day** | 01 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | LAB 01 — set up the Kubernetes learning environment |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 |

---

## Today's Objective

Install `kubectl` and `kind`, create a working 3-node Kubernetes cluster inside
WSL2, and verify it is genuinely healthy rather than merely "created".

## Module

Module 01 — Kubernetes Fundamentals

## Section

Lab environment

## Topic

LAB 01 — cluster creation and verification

## Subtopic

Reading cluster state: nodes, control plane components, contexts

---

## Theory Learned

### The node is a container, not a machine

`kubectl get nodes -o wide` showed the clearest possible confirmation:

```text
OS-IMAGE         Debian GNU/Linux 13 (trixie)
KERNEL-VERSION   6.18.33.2-microsoft-standard-WSL2
```

The host is **Fedora**. Each node reports **Debian**. The kernel is the *same*
WSL2 kernel on all three, and it is the host's kernel.

This is the exact finding proven during the Docker phase — a container ships its
own userland on top of the shared host kernel. Three "nodes" here means three
containers sharing one kernel.

### A Pod's name reveals what created it

| Pattern | Created by | Example from this cluster |
|---|---|---|
| `<name>-<node-name>` | Static Pod, started by the kubelet from disk | `kube-apiserver-k8s-lab-control-plane` |
| `<name>-<5 chars>` | DaemonSet | `kube-proxy-h92d4` |
| `<name>-<10 chars>-<5 chars>` | Deployment (ReplicaSet hash + Pod hash) | `coredns-559f6c778d-7dpbm` |

The origin of a Pod can be read from its name alone.

### Static Pods solve the bootstrap problem

`kube-apiserver` is itself a Pod, but Pods are normally created *through* the API
server. The resolution:

```text
Normal Pod:   kubectl -> API server -> etcd -> scheduler -> kubelet -> container
Static Pod:   file on disk -------------------------------> kubelet -> container
```

The kubelet watches `/etc/kubernetes/manifests/` on local disk and starts any Pod
manifest it finds there directly — no API server, no scheduler, no controller.
That is how `etcd` and `kube-apiserver` start before the cluster exists.

Once the API server is running, the kubelet registers a read-only **mirror Pod**
for each static Pod so it is visible to `kubectl`, with the node name appended
for uniqueness.

**Consequence:** deleting a static Pod with `kubectl delete pod` appears to
succeed and the Pod immediately returns. Only the mirror was deleted; the kubelet
still sees the file. Stopping one means moving the file out of the manifests
directory.

### DaemonSet vs control-plane component

`kube-proxy` and `kindnet` run once per node because their work is node-local and
cannot be performed remotely — `kube-proxy` writes iptables rules into *that*
node's kernel, `kindnet` configures *that* node's pod network. A DaemonSet means
"exactly one copy on every node", so adding a node adds a copy automatically.

`etcd` is not a DaemonSet. It runs on control-plane nodes only — one here,
because this cluster has one control plane. Production runs 3 or 5 for quorum.

### Two replicas is not automatically redundancy

CoreDNS runs 2 replicas because it resolves every Service name in the cluster,
and one replica would be a single point of failure for all service discovery.

But if both replicas land on the same node and that node dies, cluster DNS stops
entirely — a **correlated failure**, where two replicas gave the appearance of
redundancy while sharing one failure domain. Pod anti-affinity (Day 34) and
topology spread constraints (Day 36) are the mechanisms that prevent it.

---

## Why It Matters

Every later module runs against this cluster. More importantly, the verification
step established the habit the whole course depends on: **"created" is not
"healthy"**, and cluster state is confirmed by querying it, never by trusting the
message that a write succeeded.

---

## Commands Used

### `kind create cluster --name k8s-lab --config kind-cluster-config.yaml`

- **What it does:** creates a Kubernetes cluster where each node is a Docker
  container.
- **`--name k8s-lab`:** names the cluster. Without it the name is `kind`, and the
  kubeconfig context becomes `kind-k8s-lab`.
- **`--config <file>`:** uses the declared 3-node topology instead of the
  single-node default.
- **Result:** succeeded. Node image `kindest/node:v1.37.0`.

### `kubectl version`

- **What it does:** reports two independent versions — the local CLI, and the API
  server it is pointed at.
- **Why it matters:** Kubernetes supports a skew of only **±1 minor version**
  between client and server. A wider gap can fail silently on newer fields.
- **When to use it:** first command against any unfamiliar cluster, and the first
  check when a manifest works on one machine but not another.

### `kubectl get nodes -o wide`

- **What it does:** lists the machines in the cluster.
- **`-o wide`:** adds INTERNAL-IP, OS-IMAGE, KERNEL-VERSION and CONTAINER-RUNTIME,
  which the default view hides. Those columns are where the interesting
  information is.
- **When to use it:** the first answer to "is the cluster healthy?". A `NotReady`
  node explains a large class of downstream failures.

### `kubectl get pods -n kube-system`

- **What it does:** lists Pods in the namespace where Kubernetes runs its own
  components.
- **Why `-n` is required:** `kubectl` defaults to the `default` namespace.
  Namespaces partition the cluster, keeping system workloads separate from
  application workloads.
- **When to use it:** whenever the cluster itself misbehaves — DNS failures,
  broken networking, stuck scheduling. A crashing `coredns` here explains many
  confusing application symptoms.

### `kubectl config current-context`

- **What it does:** shows which cluster `kubectl` is currently talking to.
- **Why it matters:** `~/.kube/config` can hold many clusters, and **every**
  command goes to whichever context is current. This is how people delete things
  in production believing they are in dev.
- **When to use it:** before any destructive command, and always after switching
  machines. `kind create cluster` silently switched the context.

### `kubectl cluster-info`

- **What it does:** prints the API server endpoint and key cluster services.
- **Interpretation:** `https://127.0.0.1:44941` — the API server listens on 6443
  *inside* the control-plane container; kind publishes it to a random free port
  on the host. The port changes if the cluster is recreated, and `127.0.0.1`
  means the cluster is reachable only from this machine.

### `docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'`

- **What it does:** shows the layer Kubernetes is sitting on.
- **Why use it here:** confirms the one-to-one relationship between Kubernetes
  nodes and Docker containers.

---

## YAML / Configuration

`fundamentals/labs/kind-cluster-config.yaml` — unchanged from Day 00:

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: k8s-lab
nodes:
- role: control-plane
- role: worker
- role: worker
```

---

## Lab Performed

LAB 01 — `fundamentals/labs/lab-01-lab-environment-setup.md`

1. Downloaded `kubectl` v1.37.0 and verified its SHA-256 checksum before
   installing.
2. Installed it with `sudo install -o root -g root -m 0755`.
3. Downloaded and installed `kind` v0.33.0.
4. Created the 3-node cluster from the committed config.
5. Ran six verification commands and interpreted the output.

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | v1.37.0 (client and server) |
| Node count | 3 — 1 control-plane, 2 workers |
| OS (host) | Windows 11 Pro / WSL2 FedoraLinux-44 |
| OS (nodes) | Debian GNU/Linux 13 (trixie) |
| Kernel (all) | 6.18.33.2-microsoft-standard-WSL2 |
| Container runtime (nodes) | containerd 2.3.4 |
| Container runtime (host) | Docker Engine 29.7.2 |
| CNI | kindnet |
| Cluster type | kind v0.33.0, node image `kindest/node:v1.37.0` |
| API endpoint | `https://127.0.0.1:44941` |
| Node IPs | 172.19.0.2, .3, .4 |

---

## Expected Result

A 3-node cluster with all nodes `Ready` and all control plane components running.

## Actual Result

Matched exactly.

```text
Creating cluster "k8s-lab" ...
 ✓ Ensuring node image (kindest/node:v1.37.0)
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
 ✓ Joining worker nodes
Set kubectl context to "kind-k8s-lab"
```

```text
NAME                    STATUS   ROLES           AGE     VERSION   INTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                              CONTAINER-RUNTIME
k8s-lab-control-plane   Ready    control-plane   7m55s   v1.37.0   172.19.0.4    Debian GNU/Linux 13 (trixie)   6.18.33.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4
k8s-lab-worker          Ready    <none>          7m41s   v1.37.0   172.19.0.2    Debian GNU/Linux 13 (trixie)   6.18.33.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4
k8s-lab-worker2         Ready    <none>          7m41s   v1.37.0   172.19.0.3    Debian GNU/Linux 13 (trixie)   6.18.33.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4
```

```text
NAME                                            READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-7dpbm                        1/1     Running   0          8m42s
coredns-559f6c778d-zf5dm                        1/1     Running   0          8m42s
etcd-k8s-lab-control-plane                      1/1     Running   0          8m49s
kindnet-6cx84                                   1/1     Running   0          8m36s
kindnet-kpfzw                                   1/1     Running   0          8m42s
kindnet-x794k                                   1/1     Running   0          8m37s
kube-apiserver-k8s-lab-control-plane            1/1     Running   0          8m49s
kube-controller-manager-k8s-lab-control-plane   1/1     Running   0          8m49s
kube-proxy-h92d4                                1/1     Running   0          8m42s
kube-proxy-kx6f6                                1/1     Running   0          8m36s
kube-proxy-tfz4t                                1/1     Running   0          8m37s
kube-scheduler-k8s-lab-control-plane            1/1     Running   0          8m49s
```

```text
kind-k8s-lab

Kubernetes control plane is running at https://127.0.0.1:44941
CoreDNS is running at https://127.0.0.1:44941/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAMES                   IMAGE                  STATUS
k8s-lab-control-plane   kindest/node:v1.37.0   Up 10 minutes
k8s-lab-worker          kindest/node:v1.37.0   Up 10 minutes
k8s-lab-worker2         kindest/node:v1.37.0   Up 10 minutes
day14-api-1             day14-api              Up 2 hours (healthy)
day14-redis-1           redis:7-alpine         Up 2 hours
```

---

## What Worked

- Checksum verification passed (`kubectl: OK`) before installing anything as root.
- Client and server both landed on v1.37.0 — zero version skew. kind v0.33.0
  happens to ship the current stable Kubernetes. This will not always be true;
  when kind lags, `--image kindest/node:vX.Y.Z` pins it explicitly.
- All 3 nodes `Ready`, all 12 `kube-system` Pods `Running`, 0 restarts.
- `Preparing nodes 📦 📦 📦` — three boxes for the three declared nodes, a direct
  confirmation that the config file was honoured.

## What Failed

Nothing.

---

## What I Broke

Nothing today. The LAB 01 challenge — deliberately stopping a worker node — has
**not** been attempted yet.

---

## Error Message

None.

---

## Investigation

Not applicable. Nothing failed.

---

## Root Cause

Not applicable.

---

## Solution

Not applicable.

---

## Verification

Six commands run, all consistent with a healthy cluster:

| Check | Result |
|---|---|
| API server reachable | Yes — server v1.37.0 returned |
| Nodes `Ready` | 3 of 3 |
| `kube-system` Pods `Running` | 12 of 12, 0 restarts |
| Correct context | `kind-k8s-lab` |
| Docker containers | 3, matching the 3 nodes |

---

## Mistake

Two small ones, both instructive:

1. Typed `kubctl` instead of `kubectl`, then tried `sudo kubctl`. **`command not
   found` is never a permissions problem** — the shell searches `$PATH` for the
   name first and fails before permissions are ever consulted. The split worth
   remembering:
   - `command not found` → wrong name, or not on `$PATH`
   - `Permission denied` → file found, but not executable or readable by you

   Reaching for `sudo` on the first one always wastes a step.

2. Two containers from the Docker phase (`day14-api-1`, `day14-redis-1`) are
   still running and consuming memory, which matters against a 7.6 GiB budget.
   Not harmful, but worth noticing in `docker ps` rather than being surprised by
   it later.

---

## Lesson Learned

**A Pod's name tells you what created it.** Static Pods are suffixed with the
node name, DaemonSet Pods with one random string, Deployment Pods with two — the
ReplicaSet hash then the Pod hash. That makes Pod origin readable at a glance,
which becomes a diagnostic shortcut later.

**Redundancy requires separate failure domains, not just a replica count.** Two
CoreDNS Pods on one node is one failure away from total DNS loss.

---

## Troubleshooting Knowledge

**Symptom:** a Pod deleted with `kubectl delete pod` immediately returns.

| Step | Detail |
|---|---|
| CHECK | What owns the Pod? |
| COMMAND | `kubectl get pod <name> -o jsonpath='{.metadata.ownerReferences}'` |
| INTERPRETATION | A ReplicaSet, DaemonSet, or Job owner means a controller will recreate it. A `Node` owner means it is a static Pod mirror |
| ROOT CAUSE | Deleting a managed Pod deletes an instance, not the intent |
| FIX | Delete the **owner**, or for a static Pod move its manifest out of `/etc/kubernetes/manifests/` |
| PREVENTION | Check ownership before deleting anything that "won't stay deleted" |

---

## Interview Questions

1. What is a static Pod, and which component starts it?
2. Why does `kubectl delete pod kube-apiserver-<node>` not stop the API server?
3. Why do `kube-proxy` and `kindnet` run once per node while `etcd` does not?
4. What is a mirror Pod and why does it exist?
5. What version skew does Kubernetes support between `kubectl` and the API server?
6. Two CoreDNS replicas are running. Is cluster DNS highly available? What else
   must be true?
7. What does `<none>` in the ROLES column of `kubectl get nodes` mean?

---

## Challenge — COMPLETED (session of 2026-09-16, continued on Nero)

> Run `docker stop k8s-lab-worker2`.
>
> **Before** running any `kubectl` command, write down the prediction:
> 1. How long until `kubectl get nodes` shows it as `NotReady`?
> 2. What, specifically, notices? Name the component.
> 3. If Pods had been running on it, what would happen to them, how quickly, and
>    which component would act?
>
> Then observe and compare against the prediction. Restore with
> `docker start k8s-lab-worker2`.

### Prediction (written before observing)

1. ~40 seconds.
2. "The control plane" — not yet able to name the specific component.
3. No — predicted the DaemonSet Pods (`kube-proxy`, `kindnet`) would not be
   rescheduled elsewhere.

### First attempt — a false negative, not a failed test

`docker stop k8s-lab-worker2` was run at `23:25:47`, but `kubectl get nodes -w`
was interrupted with Ctrl+C almost immediately and the node was restarted
before 40 seconds had passed. `kubectl get pods -n kube-system -o wide` still
showed `kube-proxy`/`kindnet` as `1/1 Running` on `worker2` at that point — but
this was stale, cached status from the kubelet's last report before it went
dark, not live confirmation. **Nothing was disproven; not enough time had
elapsed to observe anything.** This only became clear later, from event
history (see below).

### Second attempt — timed properly

```text
23:51:51   docker stop k8s-lab-worker2   (recorded via `date; docker stop ...`)
23:52:35   Ready condition LastTransitionTime -> Unknown, Reason: NodeStatusUnknown
```

44 seconds elapsed — consistent with the default `node-monitor-grace-period`
(40s) plus the Node Lifecycle Controller's own sync interval.

`kubectl describe node k8s-lab-worker2` showed:

```text
Taints:  node.kubernetes.io/unreachable:NoExecute
         node.kubernetes.io/unreachable:NoSchedule
Conditions:
  Ready   Unknown   ...   NodeStatusUnknown   Kubelet stopped posting node status.
Events:
  NodeNotReady   19s (x2 over 26m)   node-controller   Node k8s-lab-worker2 status is now: NodeNotReady
```

- `From: node-controller` names the exact component (the **Node Lifecycle
  Controller**, part of `kube-controller-manager`) — not just "the control
  plane."
- Two taints, two jobs: `NoSchedule` stops new Pods landing here; `NoExecute`
  is what would eventually evict existing ones.
- `kube-proxy` and `kindnet` stayed listed under `Non-terminated Pods`, same
  age, `0` restarts — never evicted. **Correction to the prediction's
  reasoning:** it isn't that they "aren't rescheduled elsewhere" after some
  delay — DaemonSet Pods get an automatic, indefinite toleration for
  `not-ready`/`unreachable` `NoExecute` taints (no `tolerationSeconds` at
  all), so they are never evicted by this taint in the first place. An
  ordinary Pod (owned by a ReplicaSet) would get the default 300s tolerance,
  then be evicted and recreated on a healthy node by its controller.
- `(x2 over 26m)` on that event was the tell that the **first attempt did
  briefly trigger a real `NotReady` transition** around `23:26` — it just
  wasn't seen live because the watch had already been exited. The cluster's
  event history remembered it even though the terminal did not.

### Recovery, confirmed

```text
docker start k8s-lab-worker2
23:54:22   kubelet posts fresh status; Ready -> True, KubeletReady
           Taints: <none>
```

Every condition's `NodeHasSufficientMemory` / `NodeHasNoDiskPressure` /
`NodeHasSufficientPID` / `NodeReady` event fired **twice** at the same age
(`99s (x2 over 99s)`) — the same doubled pattern seen when the node first
joined the cluster (`25m (x2 over 25m)`). A kubelet posting its initial status
twice in quick succession appears to be normal startup behaviour, not
something specific to recovering from an outage.

### Outcome vs. prediction

| # | Predicted | Observed |
|---|---|---|
| 1 | ~40s | 44s |
| 2 | "control plane" | `node-controller` (Node Lifecycle Controller) |
| 3 | Not rescheduled | Confirmed, and stronger than predicted — never evicted at all, due to a DaemonSet-specific indefinite toleration |

---

## End-of-Day Status

COMPLETED

| Item | State |
|---|---|
| `kubectl` installed and checksum-verified | Done |
| `kind` installed | Done |
| 3-node cluster created | Done |
| All nodes `Ready` | Done |
| All `kube-system` Pods `Running` | Done |
| Four verification questions understood | Done — taught, not independently derived |
| LAB 01 challenge (node failure) | **Done** — predicted, observed, timed, recovery confirmed (2026-09-16, on machine `Nero`) |

---

## Next Session

Next journal file: `journal/daily/day-02-control-plane-and-nodes.md` — already
opened; Day 02 is IN PROGRESS (node-failure/recovery mechanism already covered
via the challenge above). Remaining for Day 02:

1. Verify the static Pod claim directly:
   ```bash
   docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/
   ```
2. Check whether both CoreDNS replicas landed on the same node:
   ```bash
   kubectl get pods -n kube-system -o wide | grep coredns
   ```
3. Continue Day 02 from there — see `journal/daily/day-02-control-plane-and-nodes.md`.
