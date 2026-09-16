# Day 02 — Control Plane vs Worker Node

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-16 |
| **Day** | 02 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Control plane vs worker node, inspected on the live cluster |
| **Status** | IN PROGRESS |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on machine `Nero`) |

---

## Today's Objective

Understand what the control plane and a worker node each actually do, and
specifically: how does the control plane know a worker node has failed, given
it never reaches out to check?

## Module

01 — Kubernetes Fundamentals

## Section

Architecture

## Topic

Control plane vs worker node

## Subtopic

Node health detection: kubelet heartbeats, the Lease object, the Node
Lifecycle Controller, taints

---

## Theory Learned

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

## Why It Matters

This is the actual mechanism behind "Kubernetes survives a node failure,"
which was the entire justification (Day 01) for using a 3-node cluster instead
of one. Understanding *how* the control plane notices, and *why* a DaemonSet
Pod's fate differs from a Deployment Pod's fate under the identical taint,
distinguishes "the cluster looks the same either way in `kubectl get nodes`"
from "these are two structurally different recovery paths."

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

---

## Lab Performed

This was the LAB 01 challenge (stop a worker node, predict, observe), whose
subject matter turned out to *be* Day 02's core topic. Full prediction,
first-attempt false negative, second-attempt timed result, and recovery are
recorded in `journal/daily/day-01-cluster-setup.md` under "Challenge —
COMPLETED." Not duplicated here in full to avoid two sources of truth for the
same timestamps.

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | v1.37.0 (client and server) |
| Node count | 3 — 1 control-plane, 2 workers |
| OS (host) | Windows / WSL2 FedoraLinux-44 |
| Machine | `Nero` (see `SystemInfo.md`) |
| Container runtime | containerd 2.3.4 |
| CNI | kindnet |

---

## What Worked

- The second, properly-timed attempt matched the predicted mechanism almost
  exactly (44s vs. a ~40s prediction).
- Event history (`kubectl describe node`, the `Events` section) surfaced a
  detail the live terminal had missed entirely — the first attempt's brief
  real `NotReady` blip.

## What Failed

Not applicable — nothing broke; this was a deliberate, successful experiment.

---

## What I Broke

Deliberately: `k8s-lab-worker2` was stopped via `docker stop` to observe node
failure detection. Restored via `docker start`. No lasting damage — this is
exactly what the challenge asked for.

## Mistake

First attempt: interrupted `kubectl get nodes -w` and restarted the node
**before** the 40-second grace period had elapsed, then read the still-cached
`Running` status on `kube-proxy`/`kindnet` as if it were live confirmation
nothing had happened. Nothing had actually been tested yet — the experiment
was stopped too early to observe anything, not disproven.

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

## Challenge

None issued yet for Day 02 specifically — the LAB 01 challenge doubled as this
day's practical work. Remaining open items (see Unresolved Issues) are
verification tasks, not a new break/fix challenge.

---

## End-of-Day Status

IN PROGRESS

| Item | State |
|---|---|
| Node heartbeat / Lease mechanism | Taught and directly observed |
| Node Lifecycle Controller, taints | Taught and directly observed |
| DaemonSet vs. controller-owned Pod eviction behaviour | Taught and directly observed |
| Static Pod manifests verified on disk | **Not done** |
| CoreDNS placement re-verified by hand | **Not done** |

## Unresolved Issues

1. Verify static Pod manifests directly on disk:
   ```bash
   docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/
   ```
2. Confirm CoreDNS replica placement:
   ```bash
   kubectl get pods -n kube-system -o wide | grep coredns
   ```

## Next Session

Next journal file: this one continues, or `journal/daily/day-03-*.md` once
Day 02 is fully closed out.

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Run the two commands above and record real output.
3. Continue Day 02 — inspect the remaining control plane components
   (`etcd`, `kube-scheduler`, `kube-controller-manager`) on the live cluster.
