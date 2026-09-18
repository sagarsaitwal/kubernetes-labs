# Day 02 — Control Plane vs Worker Node

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-16 (node-failure half, on `Nero`) / 2026-09-18 (static manifests + CoreDNS half, on `IT-SAGARS`) |
| **Day** | 02 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Control plane vs worker node, inspected on the live cluster |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (started on `Nero`, continued on `IT-SAGARS` — two independent clusters from the same committed config, not the same cluster; see Environment) |

---

## Today's Objective

Part 1 (Nero): understand what the control plane and a worker node each
actually do, and specifically — how does the control plane know a worker node
has failed, given it never reaches out to check?

Part 2 (IT-SAGARS): verify the static-Pod bootstrap story from Day 01 with
direct evidence on disk, confirm CoreDNS's actual placement, and read the two
remaining control-plane static manifests (`etcd`, `kube-scheduler`) to learn
what distinguishes a stateful control-plane component from a stateless one.

## Module

01 — Kubernetes Fundamentals

## Section

Architecture

## Topic

Control plane vs worker node

## Subtopic

Node health detection (kubelet heartbeats, the Lease object, the Node
Lifecycle Controller, taints); static Pod manifests on disk
(`kube-apiserver`, `etcd`, `kube-scheduler`); stateless vs stateful
control-plane components; two distinct high-availability mechanisms in one
control plane; CoreDNS replica placement.

---

## Theory Learned

### Part 1 — Node health detection (Nero)

**The worker reports in; the control plane never reaches out.** Each node's
`kubelet` writes a small **Lease object** (`coordination.k8s.io/v1`, in the
`kube-node-lease` namespace) roughly every 10 seconds — a lightweight heartbeat
kept separate from the full `NodeStatus` (capacity, conditions, images)
because renewing a tiny object is far cheaper at scale than rewriting the
whole Node object that often.

The **Node Lifecycle Controller** (a sub-controller inside
`kube-controller-manager`, confirmed directly in `Events` as `node-controller`)
watches every node's Lease. If a lease goes unrenewed for longer than
`node-monitor-grace-period` (default 40s), it flips that node's `Ready`
condition to `Unknown` — the moment `kubectl get nodes` starts printing
`NotReady`. It then applies a **taint**:

- `node.kubernetes.io/unreachable:NoSchedule` — stop scheduling new Pods here.
- `node.kubernetes.io/unreachable:NoExecute` — start evicting existing Pods,
  once their toleration for this taint runs out.

**What "runs out" means depends entirely on what owns the Pod, not on the
taint itself:**

- A Pod owned by a **ReplicaSet/Deployment** gets a default `tolerationSeconds:
  300` for this taint. After 5 minutes, it's evicted, and the ReplicaSet
  controller — noticing it's short a replica — creates a new Pod, which the
  scheduler places on a healthy node. This is what "rescheduling" actually is.
- A Pod owned by a **DaemonSet** gets an automatic, **indefinite** toleration
  for exactly this taint (no `tolerationSeconds` at all) — added by the
  DaemonSet controller itself. It is never evicted by node unreachability. Its
  contract is "one copy per node," so there is no "elsewhere" to move it to;
  it simply waits, `Unknown`, until its node comes back.
- A **bare Pod** with no owning controller never comes back on its own either
  way — nothing is watching to recreate it.

Confirmed directly with `k8s-lab-worker2`'s two DaemonSet Pods (`kube-proxy`,
`kindnet`): both stayed listed under `Non-terminated Pods` the entire time the
node was down, same age, `0` restarts.

**`kubectl get nodes -w` prints one line per watch event on the object, not
per visible-column change.** Multiple identical-looking `NotReady` lines for
the same node reflect multiple separate writes to that Node object (here, four
conditions flipping to `Unknown` one at a time) — the table just doesn't show
every field that changed.

**Event history is a more reliable record than a live terminal.** A
`(x2 over 26m)` count on a `NodeNotReady` event revealed that an earlier,
seemingly-aborted experiment had actually triggered a real (if brief)
transition that nobody saw live, because the watch had already been exited.
"I didn't see it happen" is not the same claim as "it didn't happen."

### Part 2 — Static Pod manifests and component anatomy (IT-SAGARS)

**Static Pod manifests exist exactly where Day 01 said they would.**
`docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/`
listed all four expected files (`etcd.yaml`, `kube-apiserver.yaml`,
`kube-controller-manager.yaml`, `kube-scheduler.yaml`), each `-rw-------`
(600, root-only) and all timestamped identically — written in one instant when
`kind create cluster` bootstrapped the node, before any API server existed to
have created them another way.

**No `kube-proxy.yaml` or `kindnet.yaml` in that directory.** Consistent with
Day 01's theory: those are DaemonSet Pods, created *through* the API server
once it exists, so they cannot be static — only the components needed to
bring the API server itself into being live on disk.

**Reading `kube-apiserver.yaml` in full** showed real flags matching the
architecture already taught: `--etcd-servers=https://127.0.0.1:2379` (talks to
etcd over localhost — they share this node's network namespace via
`hostNetwork: true`), `--tls-cert-file`/`--client-ca-file` (server identity for
anyone connecting to it), `--service-account-signing-key-file` (how it issues
ServiceAccount tokens), and `priorityClassName: system-node-critical` (never
evicted under resource pressure).

**Reading `etcd.yaml` confirmed the stateful/stateless distinction directly:**

- `--data-dir=/var/lib/etcd` plus a real `hostPath` volume mount
  (`etcd-data` -> `/var/lib/etcd`) — the literal disk location holding every
  object ever created in this cluster. No other static Pod has an equivalent.
- `--listen-client-urls=https://127.0.0.1:2379,...` — the other end of the
  connection seen in `kube-apiserver.yaml`. Two files, read separately,
  describing the same link from each side.
- `--initial-cluster=k8s-lab-control-plane=https://172.19.0.2:2380` — lists
  only **one** member. In a real HA control plane this field lists 3 or 5
  members, comma-separated; one entry here is direct, visible proof this is a
  single-node "cluster of one" for etcd's own internal consensus.
- `--client-cert-auth=true` / `--peer-client-cert-auth=true` — mutual TLS is
  required for every connection, including from `127.0.0.1`. This is the
  matching half of `kube-apiserver.yaml`'s
  `--etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt` — the
  apiserver was presenting a client certificate the whole time; localhost
  alone was never sufficient to be trusted.
- `image: registry.k8s.io/etcd:3.7.0-0` — a version number completely
  independent of Kubernetes' own `v1.37.0`. etcd is a separate CNCF project
  Kubernetes adopted as a storage backend, with its own release cycle and its
  own compatibility matrix against Kubernetes versions (relevant later at
  Day 79, cluster upgrades).

**Reading `kube-scheduler.yaml` established the general test for
stateless vs stateful,** after an initial wrong guess (see Mistake 002):

```yaml
volumeMounts:
- mountPath: /etc/kubernetes/scheduler.conf
  name: kubeconfig          # credentials only — not data
```

No `--data-dir`, no data-holding volume — only a `kubeconfig` file, which is
how a **client** authenticates *to* the API server (the same relationship
`kubectl` itself has). `etcd` and `kube-apiserver` are servers being connected
*to*, so they carry TLS server certificates instead. The concrete,
checkable test that separates the two categories:

```text
Has --data-dir + a real data volume?
   YES -> stateful (etcd only, on this cluster)
   NO, only a kubeconfig/cert volume -> stateless
          (kube-apiserver, kube-scheduler, kube-controller-manager)
```

**Two different high-availability mechanisms exist in one control plane, and
`kube-scheduler.yaml` revealed the second one:**

```yaml
- --leader-elect=true
```

| Component | HA mechanism | Active members at once |
|---|---|---|
| `etcd` | Raft consensus — every write needs a majority vote | All members simultaneously |
| `kube-scheduler`, `kube-controller-manager` | Leader election — one lock in the API server | Exactly one; the rest are idle standbys |

A stateless component only needs a lock to decide who's in charge, because a
standby holding no data needs no synchronization. A stateful component needs
every member agreeing on every write, which is a fundamentally more expensive
guarantee — which is exactly why etcd is the component production clusters are
most careful about.

**CoreDNS placement check found a real, verified single point of failure on
this cluster:**

```text
coredns-559f6c778d-7dpbm   ...   10.244.0.2   k8s-lab-control-plane
coredns-559f6c778d-zf5dm   ...   10.244.0.3   k8s-lab-control-plane
```

Both replicas — same node. Not a hypothetical from Day 01; an actual property
of this specific cluster, confirmed by reading the `NODE` column directly.
**Corroborating evidence found unprompted in the same output:** both Pods
showed `RESTARTS: 2 (155m ago)` — an identical, simultaneous restart count,
which is what a shared failure domain actually looks like in practice, not
just in theory.

**Root cause:** CoreDNS ships with `podAntiAffinity` as
`preferredDuringSchedulingIgnoredDuringExecution` — a preference, not a
requirement. Per Day 01's own `kind create cluster` output, the control-plane
node starts and CoreDNS is created **before** `Joining worker nodes` occurs.
At that exact moment, the control-plane node is the only schedulable node in
existence, so both replicas land there of necessity. Once the workers join,
**nothing re-evaluates already-running Pods** — Kubernetes' scheduler places a
Pod once, at creation, and never moves it afterward just because a better
option later appears. That is a general Kubernetes property (it is the entire
reason a tool called the *descheduler* exists), not a kind-specific quirk.

**Deliberately not fixed today.** The real fix — `required` anti-affinity or a
topology spread constraint — needs Day 34/36 material. Recorded as a verified
finding with a forward pointer, not left to be silently forgotten.

## Why It Matters

Part 1 is the actual mechanism behind "Kubernetes survives a node failure,"
which was the entire justification (Day 01) for using a 3-node cluster instead
of one.

Part 2 turns "trust me, static Pods bootstrap the control plane" into
something verified by hand, and gives a concrete, reusable test (data-dir +
data volume, present or absent) for a question — "is this stateful?" — that
would otherwise be answered by guessing how important something sounds. The
CoreDNS finding also demonstrates that "the scheduler placed things nicely"
cannot be assumed; it has to be checked, on this cluster specifically, not
inferred from general theory.

---

## Commands Used

### `kubectl get nodes -w`

- **What it does:** streams live updates to the Node list instead of one
  static snapshot.
- **Important options:** `-w` (watch) — keeps the connection open and prints a
  new line on every watch event for a matching object.
- **Why I used it:** to observe the exact moment a node's status changes,
  rather than polling and guessing whether I'd missed it.
- **Expected output:** the existing table, then new lines appended as nodes
  change state.
- **Actual output:** printed three `NotReady` lines for `worker2` in a row
  (see Theory Learned — multiple underlying condition changes), then unrelated
  `Ready` reprints for the other two nodes shortly after (likely a coincidental
  periodic kubelet resync, not caused by `worker2`'s failure).

### `date; docker stop k8s-lab-worker2`

- **What it does:** `date` prints the current time (pure bookkeeping, not a
  Kubernetes/Docker command — needed to measure elapsed time to `NotReady`).
  `docker stop` sends `SIGTERM` then (after a grace period) `SIGKILL` to the
  container's PID 1 — here, the process that is effectively running
  `containerd`, `kubelet`, and `kube-proxy` for that "node."
- **Important options:** none used beyond the container name.
- **Why I used it:** a kind "node" is just a Docker container, so stopping it
  simulates a worker machine losing power — abruptly, with no cooperative
  shutdown handshake with the API server. (Contrast with `kubectl drain`,
  planned maintenance's cooperative equivalent, not yet covered.)
- **Expected output:** the container name echoed back once stopped.
- **Actual output:** `Wed, 16 Sep 2026 23:51:51 +0530` / `k8s-lab-worker2`.

### `kubectl describe node <name>`

- **What it does:** full detail on one Node object — labels, taints, the Lease
  block, per-condition status with two separate timestamps
  (`LastHeartbeatTime` vs `LastTransitionTime`), capacity/allocatable
  resources, and the Pods currently assigned to it, plus its Event history.
- **Important options:** none — first look at the full unfiltered output.
- **Why I used it:** `kubectl get nodes` only shows the `Ready` column; this is
  where the taint, the specific failure reason, and the responsible component
  (`From:` field in Events) are actually visible.
- **Expected output:** a large structured text block, several sections.
- **Actual output (down):**
  ```text
  Taints:  node.kubernetes.io/unreachable:NoExecute
           node.kubernetes.io/unreachable:NoSchedule
  Ready    Unknown   ...LastTransitionTime: 23:52:35...   NodeStatusUnknown   Kubelet stopped posting node status.
  Events:  NodeNotReady   19s (x2 over 26m)   node-controller   ...
  ```
  **Actual output (recovered):**
  ```text
  Taints:  <none>
  Ready    True   ...LastTransitionTime: 23:54:22...   KubeletReady   kubelet is posting ready status
  Events:  NodeHasSufficientMemory / NodeHasNoDiskPressure / NodeHasSufficientPID / NodeReady, each 99s (x2 over 99s)
  ```

### `docker start k8s-lab-worker2`

- **What it does:** restarts the same, already-existing container (same
  filesystem, same container ID) — not a new one. `containerd` and `kubelet`
  cold-start again inside it.
- **Why I used it:** restore the node after the deliberate failure, and
  observe the recovery half of the same mechanism.
- **Expected output:** container name echoed back.
- **Actual output:** `k8s-lab-worker2`; node returned to `Ready` ~2m31s later
  (`23:51:51` stop -> `23:54:22` fresh `Ready` status).

### `docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/`

- **What it does:** runs `ls -l` inside the control-plane node container to
  list the directory the kubelet watches for static Pods.
- **Important options:** `-i` keeps stdin open, `-t` allocates a pseudo-TTY for
  readable output.
- **Why I used it:** physical evidence for the static-Pod bootstrap claim from
  Day 01 — either the files are there or the explanation was wrong.
- **Expected output:** four YAML files.
- **Actual output:**
  ```text
  -rw------- 1 root root 2610 Sep 18 07:03 etcd.yaml
  -rw------- 1 root root 3968 Sep 18 07:03 kube-apiserver.yaml
  -rw------- 1 root root 3267 Sep 18 07:03 kube-controller-manager.yaml
  -rw------- 1 root root 1726 Sep 18 07:03 kube-scheduler.yaml
  ```

### `docker exec -it k8s-lab-control-plane cat /etc/kubernetes/manifests/<file>.yaml`

- **What it does:** prints one static Pod manifest in full.
- **Why I used it:** run against `kube-apiserver.yaml`, `etcd.yaml`, and
  `kube-scheduler.yaml` in turn, to compare real flags against the theory
  already taught, and to establish the stateless/stateful test by direct
  comparison rather than by definition alone.
- **Actual output:** see Theory Learned for the specific flags extracted from
  each.

### `kubectl get pods -n kube-system -o wide | grep coredns`

- **What it does:** lists Pods with node placement visible, filtered to
  CoreDNS.
- **Important options:** `-o wide` adds the `NODE` column, the one that
  actually answers the question.
- **Why I used it:** to check, on this specific cluster, whether the Day 01
  correlated-failure risk (both CoreDNS replicas on one node) was real or
  hypothetical.
- **Expected output:** two lines; the interesting fact is whether the `NODE`
  column repeats.
- **Actual output:**
  ```text
  coredns-559f6c778d-7dpbm   1/1   Running   2 (155m ago)   45h   10.244.0.2   k8s-lab-control-plane
  coredns-559f6c778d-zf5dm   1/1   Running   2 (155m ago)   45h   10.244.0.3   k8s-lab-control-plane
  ```
  Confirmed: both on `k8s-lab-control-plane`.

---

## Lab Performed

Part 1 was the LAB 01 challenge (stop a worker node, predict, observe), whose
subject matter turned out to *be* Day 02's core topic. Full prediction,
first-attempt false negative, second-attempt timed result, and recovery are
recorded in `journal/daily/day-01-cluster-setup.md` under "Challenge —
COMPLETED." Not duplicated here in full to avoid two sources of truth for the
same timestamps.

Part 2 was self-directed inspection: list the static manifests, read three of
the four in full (`kube-apiserver`, `etcd`, `kube-scheduler`), attempt to
classify `kube-scheduler` before checking (got it wrong — see Mistake 002),
then verify CoreDNS placement directly. `kube-controller-manager`'s manifest
was not read line-by-line, since its *behavior* (the Node Lifecycle Controller)
was already directly observed and understood via Part 1's experiment.

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | v1.37.0 (client and server) |
| Node count | 3 — 1 control-plane, 2 workers |
| Part 1 machine | `Nero` — WSL2 FedoraLinux-44, kernel 6.6.87.2 |
| Part 2 machine | `IT-SAGARS` — WSL2 FedoraLinux-44, kernel 6.18.33.2 |
| Container runtime | containerd 2.3.4 |
| CNI | kindnet |

**Note on the two machines:** these are two separate `kind` clusters, both
named `k8s-lab`, both built from the identical committed
`kind-cluster-config.yaml` — not one cluster accessed from two places.
Clusters do not travel between machines (see `progress/environments.md`); the
*config* is what's shared, and each machine's cluster has its own independent
history, uptime, and restart count. This is why IT-SAGARS's CoreDNS Pods show
`45h` age with their own separate restart count, unrelated to anything that
happened on Nero.

---

## What Worked

- The second, properly-timed node-failure attempt matched the predicted
  mechanism almost exactly (44s vs. a ~40s prediction).
- Event history (`kubectl describe node`, the `Events` section) surfaced a
  detail the live terminal had missed entirely — the first attempt's brief
  real `NotReady` blip.
- Static Pod manifests matched the Day 01 theory exactly — right files, right
  permissions, right timestamp pattern, right absences (no DaemonSet
  manifests).
- Reading `kube-apiserver.yaml` and `etcd.yaml` closely enough to notice they
  referenced the same address (`127.0.0.1:2379`) from opposite sides, without
  being told to look for that specifically.
- Found the CoreDNS correlated-restart evidence (`2 (155m ago)` on both Pods)
  without being prompted to look for it — a stronger confirmation of the gap
  than the placement check alone would have given.

## What Failed

Not applicable for Part 1 — nothing broke; that was a deliberate, successful
experiment.

For Part 2: the first classification attempt on `kube-scheduler.yaml`
("stateful") was wrong — see Mistake 002 below.

---

## What I Broke

Deliberately: `k8s-lab-worker2` (on `Nero`) was stopped via `docker stop` to
observe node failure detection. Restored via `docker start`. No lasting
damage — this is exactly what the challenge asked for.

Nothing was broken during Part 2 — inspection only, no mutation.

## Mistake

**(Part 1)** First attempt: interrupted `kubectl get nodes -w` and restarted
the node **before** the 40-second grace period had elapsed, then read the
still-cached `Running` status on `kube-proxy`/`kindnet` as if it were live
confirmation nothing had happened. Nothing had actually been tested yet — the
experiment was stopped too early to observe anything, not disproven. Full
detail in `journal/mistakes-and-lessons.md`, Mistake 001.

**(Part 2)** Asked to classify `kube-scheduler.yaml` as stateless or stateful
having just correctly reasoned through the same question for `kube-apiserver`
(stateless) and `etcd` (stateful) — answered "stateful." Wrong. Had not yet
turned "stateful vs stateless" into a concrete, repeatable test (does it have
`--data-dir` + a real data volume, or only a kubeconfig/cert volume?) and
applied it mechanically to the new file; answered from impression rather than
evidence already sitting in the manifest. Full detail in
`journal/mistakes-and-lessons.md`, Mistake 002.

## Lesson Learned

1. Before concluding "X doesn't happen," confirm enough time actually passed
   for X to happen — a `docker stop` restored after 5 seconds tells you
   nothing about a 40-second mechanism.
2. A Pod's last-reported status (`Running`) is not a live health check — once
   its node stops reporting, that status is frozen at whatever the kubelet
   said last, not re-verified by anyone.
3. `kubectl describe <object>`'s `Events` section is a more trustworthy record
   than "what I watched scroll by," because a live watch only shows you things
   while you're actually looking at it.
4. A concrete criterion, once established (data-dir + data volume = stateful),
   should be applied mechanically to the next case — not re-guessed from a
   general impression of how "important" a component sounds.
5. Corroborating evidence is often already sitting in output you asked for a
   different reason — the CoreDNS restart counts weren't specifically searched
   for, but confirmed the finding more strongly than the placement column
   alone.
6. The scheduler places a Pod once, at creation, and never re-evaluates
   already-running Pods just because conditions later change — a cluster's
   layout can go stale purely from *when* something happened to be created.

## Troubleshooting Knowledge

```text
SYMPTOM: A node was deliberately (or actually) failed, but no status change
         was observed in a live `kubectl get nodes -w` session.
CHECK:   Was the watch actually left running long enough, and was the node
         restored before or after the grace period elapsed?
COMMAND: kubectl describe node <name>   (read the Events section, not just
         the current STATUS column)
INTERPRETATION: Event counts like "(x2 over 26m)" reveal transitions that
         happened even if nobody was watching live at that moment.
ROOT CAUSE: A live watch only shows events while it is connected; it is not
         a substitute for the cluster's own event history.
FIX:     Trust `describe`'s Events over terminal scrollback when reconciling
         "what actually happened."
PREVENTION: When timing a failure-detection mechanism, always let the
         experiment run past the expected threshold before restoring state.
```

```text
SYMPTOM: Uncertain whether a control-plane component is stateful.
CHECK:   Read its static Pod manifest (or Deployment spec).
COMMAND: docker exec -it <control-plane-node> cat /etc/kubernetes/manifests/<name>.yaml
INTERPRETATION: A `--data-dir` flag PLUS a matching hostPath/PVC volume mount
         means the component itself stores data (etcd, on this cluster).
         A kubeconfig-only or cert-only volume mount means the component is
         a stateless client of the API server, restartable with zero data
         loss (kube-apiserver, kube-scheduler, kube-controller-manager).
ROOT CAUSE: "Stateful" is not a property inferable from how central a
         component sounds — it is a checkable fact in its own manifest.
PREVENTION: Apply the data-dir + data-volume test explicitly before
         answering, rather than guessing from general impression.
```

```text
SYMPTOM: Two replicas of a workload exist; is it actually redundant?
CHECK:   kubectl get pods -n <namespace> -o wide, read the NODE column for
         every replica.
COMMAND: kubectl get pods -n kube-system -o wide | grep <workload>
INTERPRETATION: If the NODE column repeats across replicas, they share a
         single failure domain and redundancy is illusory. Correlated
         RESTARTS counts across replicas are strong corroborating evidence
         of a shared failure event.
ROOT CAUSE: Soft (preferred) anti-affinity is not enforced, and Kubernetes
         never re-schedules an already-running Pod just because a better
         node option appears later (e.g. a worker joining after the Pod
         was created on the only node that existed at the time).
FIX:     `required` anti-affinity or topology spread constraints (Day 34/36)
         — not yet implemented on this cluster; deliberately deferred.
PREVENTION: Never assume replica count alone means high availability;
         verify placement directly.
```

---

## Interview Questions

1. How does the control plane learn that a worker node has failed, given it
   never polls the node directly?
2. What is the difference between a Node's `NodeStatus` and its `Lease`
   object, and why are they separate?
3. What is the practical difference between the `NoSchedule` and `NoExecute`
   effects of a taint?
4. Why does a DaemonSet Pod not get rescheduled when its node fails, while a
   Deployment Pod does?
5. What does `tolerationSeconds` control, and what is its default for a
   normal Pod against the `unreachable`/`not-ready` taints?
6. What concrete evidence in a static Pod manifest distinguishes a stateful
   control-plane component from a stateless one?
7. Why does `kube-apiserver` need a client certificate to talk to `etcd`, even
   over `127.0.0.1`?
8. Name the two different high-availability mechanisms present in a single
   Kubernetes control plane, and explain why each component uses the one it
   does rather than the other.
9. A workload has two replicas. What single piece of evidence would prove or
   disprove that this is genuinely fault-tolerant?
10. Why is it possible for a Kubernetes cluster's Pod placement to become
    "stale" relative to its current set of nodes?

## Challenge

None formally issued for Day 02 — the LAB 01 challenge (Part 1) and the
self-directed classification exercise on `kube-scheduler.yaml` (Part 2, where
the wrong first answer was itself the useful outcome) together served as this
day's practical work.

---

## End-of-Day Status

COMPLETED

| Item | State |
|---|---|
| Node heartbeat / Lease mechanism | Taught and directly observed |
| Node Lifecycle Controller, taints | Taught and directly observed |
| DaemonSet vs. controller-owned Pod eviction behaviour | Taught and directly observed |
| Static Pod manifests verified on disk | Done — all 4 files confirmed, 3 read in full |
| Stateless vs stateful control-plane components | Done — concrete test established, applied (with one wrong first attempt, corrected) |
| Two HA mechanisms (Raft vs leader-election) | Done — identified from `--initial-cluster` and `--leader-elect` directly |
| CoreDNS placement re-verified by hand | Done — real gap found and root-caused, fix deferred to Day 34/36 |

## Unresolved Issues

None blocking. Forward-looking item recorded, not urgent:

1. CoreDNS anti-affinity fix (`required` affinity or topology spread
   constraints) — intentionally deferred to Day 34/36, not a Day 02 task.

## Next Session

Next journal file: `journal/daily/day-03-architecture-request-flow.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 03 — Architecture and the request flow: trace `kubectl apply` through
   the full 14-step path (already previewed at a high level in Lesson 01),
   this time confirming each step against the live cluster rather than theory
   alone.
