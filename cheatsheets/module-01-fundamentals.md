# Module 01 — Fundamentals Cheatsheet

Author: Sagar Saitwal

Covers: Day 00 – Day 03. Updated after each day of Module 01.

This is **quick reference only** — the reasoning, the mistakes, and the full
command output live in `journal/daily/`. Come here to look something up fast;
go there to see how it was actually learned.

---

## Core concepts

- **Reconciliation loop:** `DESIRED STATE -> compare -> ACT -> CURRENT STATE`,
  running forever. This is *why* Kubernetes is declarative rather than
  imperative — the loop never stops, your command only changes what it's
  aiming for.
- **A Kubernetes node (in `kind`) is a Docker container**, not a separate
  machine. It shares the host's kernel but ships its own userland (a
  different OS image) — the same shared-kernel model proven in the Docker
  phase.
- **A Pod's name reveals what created it:**
  | Pattern | Created by |
  |---|---|
  | `<name>-<node-name>` | Static Pod (kubelet, no scheduler involved) |
  | `<name>-<5 random chars>` | DaemonSet |
  | `<name>-<10 chars>-<5 chars>` | Deployment (ReplicaSet hash + Pod hash) |
- **Static Pods** are started by the **kubelet** directly from
  `/etc/kubernetes/manifests/*.yaml` on disk — no API server involved. This is
  how `etcd` and `kube-apiserver` bootstrap before the cluster exists to
  create anything through. `kubectl` shows a read-only **mirror Pod** for
  each; deleting the mirror does nothing permanent — the kubelet still sees
  the file and restarts it. To actually stop one, move the file.
- **Stateless vs stateful control-plane components — a concrete test, not a
  guess:**
  ```text
  Has --data-dir + a real data volume mount?
     YES -> stateful   (etcd — the only one)
     NO, only a kubeconfig/cert volume -> stateless
            (kube-apiserver, kube-scheduler, kube-controller-manager)
  ```
- **Two different high-availability mechanisms exist in one control plane:**
  | Component | Mechanism | Active members at once |
  |---|---|---|
  | `etcd` | Raft consensus — every write needs a majority vote | All members |
  | `kube-scheduler`, `kube-controller-manager` | `--leader-elect=true` — one lock, one winner | Exactly one |
- **`hostNetwork: true`** on every static control-plane Pod — they share the
  node's real network namespace directly rather than getting a private Pod IP.
- **A taint's effect depends on the Pod's *owner*, not the taint alone:**
  - ReplicaSet/Deployment Pod: default `tolerationSeconds: 300`, then evicted
    and rescheduled elsewhere by the owning controller.
  - DaemonSet Pod: automatic, **indefinite** toleration for
    `node.kubernetes.io/unreachable` — never evicted. Contract is "one per
    node," so there's no "elsewhere."
- **Node health is heartbeat-based, not polled.** The kubelet renews a small
  `Lease` object (`coordination.k8s.io/v1`) roughly every 10s. The **Node
  Lifecycle Controller** (inside `kube-controller-manager`) watches leases,
  not the node itself. Missed for longer than `node-monitor-grace-period`
  (default 40s) → node flips to `NotReady` and gets tainted.
- **Two replicas is not automatically redundancy.** Only true if they land in
  different failure domains — check the `NODE` column, don't assume it.
- **`kubectl apply`/`create` returning "created" only proves the API server
  stored the object.** Nothing about running, scheduled, or healthy. Verify
  separately, always.
- **A live `-w` watch only shows events while connected.** `kubectl
  describe`'s `Events` section (with counts like `(x2 over 26m)`) is the
  durable record — trust it over terminal scrollback.
- **Admission/defaulting is directly observable — no special tooling
  needed.** Diff what you wrote against what `kubectl describe` shows was
  stored. A manifest with zero tolerations came back with two, injected by
  the `DefaultTolerationSeconds` admission plugin.
- **The scheduler filters nodes by taint before it ever scores them.** A
  Pod with no matching toleration never becomes a candidate for a tainted
  node — kind's control-plane node carries `node-role.kubernetes.io/
  control-plane:NoSchedule` by default, which explains why ordinary Pods
  never land there while explicitly-tolerating system Pods (CoreDNS) can.
- **`Restart Count` and `Age`/`Start Time` answer different questions.** A
  container restarting inside an existing Pod bumps `Restart Count` but
  leaves `Age` unchanged; a genuinely new Pod object resets `Age` to near
  zero. The same underlying event (a node reboot) can produce either,
  depending on the component.

---

## Commands

| Command | What it does | When to reach for it |
|---|---|---|
| `kubectl version` | Client + server versions | First command on any unfamiliar cluster; check skew (max ±1 minor) |
| `kubectl get nodes -o wide` | Nodes + IP/OS/kernel/runtime | First "is this cluster healthy" check |
| `kubectl get pods -n kube-system` | System component Pods | `-n` is required — default namespace hides these |
| `kubectl get pods -n kube-system -o wide` | + `NODE` column | Check actual placement (e.g. is CoreDNS spread out?) |
| `kubectl config current-context` | Which cluster kubectl is pointed at | Before anything destructive; always after switching machines |
| `kubectl cluster-info` | API server endpoint | Confirms reachability |
| `kubectl describe node <name>` | Full detail: taints, Lease, conditions, Events | Root-causing a `NotReady` or scheduling issue |
| `kubectl get nodes -w` | Live stream of node status changes | Watching a failure/recovery in real time |
| `kubectl get events --sort-by=.lastTimestamp` | Cluster-wide event history | More reliable than trusting what you happened to see live |
| `docker exec -it <node> ls -l /etc/kubernetes/manifests/` | List static Pod manifests on a kind node | Verify the bootstrap files physically exist |
| `docker exec -it <node> cat /etc/kubernetes/manifests/<f>.yaml` | Read one static Pod manifest | See the exact flags a component started with |
| `docker ps` | Docker's view of the "nodes" | 1-to-1 with `kubectl get nodes` in a kind cluster |
| `docker stop <node>` | Simulate ungraceful node failure | Break/fix: watch `NotReady` + taint + eviction |
| `docker start <node>` | Restore a stopped node | Recovery half of the same experiment |
| `kubectl apply -f <file>` | Declaratively create/update from a manifest | Default way to submit anything — idempotent, unlike `create` |
| `kubectl get rs` | List ReplicaSets | Confirm a Deployment actually created one; hash ties Deployment→RS→Pod together |
| `kubectl get pods -o wide -w` | Live Pod status + `NODE` column | Try to catch `Pending`/`ContainerCreating` — often still too slow, use `describe`'s Events as fallback |

---

## Important flags seen so far (static Pod manifests)

| Flag | Where | Meaning |
|---|---|---|
| `--data-dir=/var/lib/etcd` | `etcd` only | Where cluster state physically lives on disk |
| `--etcd-servers=https://127.0.0.1:2379` | `kube-apiserver` | Connects to etcd, localhost only — they're co-located |
| `--listen-client-urls` incl. `127.0.0.1:2379` | `etcd` | The other end of the apiserver↔etcd link |
| `--initial-cluster=<name>=<peer-url>` | `etcd` | Lists ALL etcd members; one entry = single-node "cluster of one" |
| `--client-cert-auth=true` / `--peer-client-cert-auth=true` | `etcd` | Mutual TLS required even over localhost |
| `--leader-elect=true` | `kube-scheduler`, `kube-controller-manager` | One active leader among replicas — not Raft |
| `--kubeconfig=/etc/kubernetes/scheduler.conf` | `kube-scheduler` | Client credentials — this component *calls* the API server, doesn't serve |
| `hostNetwork: true` | all 4 static Pods | Shares the node's real network namespace |
| `priorityClassName: system-node-critical` | all 4 static Pods | Never evicted under resource pressure |

---

## Findings on THIS cluster (observed, not generic theory)

**Both CoreDNS replicas landed on `k8s-lab-control-plane`** — not spread
across the two workers. Confirmed via
`kubectl get pods -n kube-system -o wide | grep coredns`.

- **Why:** CoreDNS's anti-affinity is `preferred`, not `required`. kind starts
  the control-plane node and creates CoreDNS *before* workers finish joining,
  so the control-plane node is briefly the only schedulable option. The
  scheduler never re-evaluates already-running Pods afterward.
- **Corroborating evidence:** both Pods showed identical
  `RESTARTS: 2 (155m ago)` — a correlated restart, direct proof this is a real
  single point of failure, not just a theoretical one.
- **Fix:** deferred to Day 34 (`required` pod anti-affinity) / Day 36
  (topology spread constraints) — deliberately not implemented yet.
- **Day 03 addendum — why it was ever eligible in the first place:** the
  control-plane node carries `node-role.kubernetes.io/control-plane:
  NoSchedule`. A plain Deployment Pod (tested directly: `nginx-trace`, 3
  replicas, none landed on control-plane) has no toleration for it and is
  filtered out before scoring. CoreDNS's `Tolerations` block shows it
  explicitly tolerates that exact taint (plus `CriticalAddonsOnly`) — that's
  the missing half of the explanation, not a kind-specific accident.

---

## Troubleshooting habits established so far

```text
"created" / "applied" succeeded
   -> does NOT mean running or healthy.
   -> verify with kubectl get / describe / logs / events.

A live "kubectl get X -w" session only shows events while connected.
   -> kubectl describe's Events section (with counts like "(x2 over 26m)")
      is the durable record; trust it over terminal scrollback.

A Pod's last-known status freezes when its node stops reporting.
   -> not proof of current state — just the last thing anyone heard
      before the node went dark.

"command not found" vs "Permission denied"
   -> wrong name / not on $PATH,  vs  found but not executable/readable.
   -> sudo never fixes the first one.

Is a control-plane component stateful?
   -> check its manifest for --data-dir + a real data volume.
   -> present = stateful (etcd). absent, only kubeconfig/certs = stateless.

Are N replicas of something actually redundant?
   -> kubectl get pods -o wide, read the NODE column for every replica.
   -> repeated node name = shared failure domain = redundancy is fake.

A Pod isn't landing on the node you expected (or a specific node at all)?
   -> kubectl describe node <name>   -- check Taints:
   -> kubectl describe pod <name>    -- check Tolerations:
   -> the scheduler filters out any node whose taints aren't tolerated
      BEFORE scoring even starts -- a mismatch means "never a candidate,"
      not "lost on merit."

Did admission actually inject/mutate anything?
   -> diff what you wrote against `kubectl describe`/`-o yaml` of what got
      stored -- defaults and injected fields (e.g. tolerationSeconds) show
      up on their own, no special tooling needed.
```

---

## Interview questions accumulated (Day 00–03)

1. What is a reconciliation loop, and why does it make Kubernetes declarative
   rather than imperative?
2. Why can two containers in the same Pod reach each other on `localhost`
   when two Docker containers on the same host cannot?
3. What does `kubectl apply` returning "created" actually guarantee, and what
   does it not?
4. What is a static Pod, and which component starts it? Why can't the API
   server itself be started as a normal Pod?
5. What is a mirror Pod, and why does deleting it via `kubectl` not actually
   stop the underlying static Pod?
6. Why do `kube-proxy` and `kindnet` run once per node, while `etcd` does not?
7. What concrete, checkable evidence distinguishes a stateless control-plane
   component from a stateful one?
8. Name the two different high-availability mechanisms inside one control
   plane, and explain why each component uses the one it does.
9. How does the control plane learn a worker node has failed, given it never
   polls the node directly?
10. What is the practical difference between a `NoSchedule` and a `NoExecute`
    taint?
11. Why does a DaemonSet Pod not get rescheduled when its node fails, while a
    Deployment Pod does?
12. Two replicas of a workload exist. Is that "highly available"? What
    additional fact do you need before answering?
13. Why does `kube-apiserver` need a client certificate to talk to `etcd`,
    even over `127.0.0.1`?
14. Why is it possible for a cluster's Pod placement to become "stale"
    relative to its current set of nodes?
15. `kubectl apply` prints `created`. Which of the 14 request-flow steps does
    that confirm, and which does it say nothing about?
16. How would you prove the admission stage actually ran, without reading
    Kubernetes source code?
17. Why did a plain Deployment's Pods avoid the control-plane node entirely,
    while CoreDNS could land there?
18. What's the difference between a Pod's `Restart Count` and its `Age`, and
    what does each one actually tell you happened?
