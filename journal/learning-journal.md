# Kubernetes Learning Journal — Master Index

Author: Sagar Saitwal

High-level chronological index of every learning day. This file is a summary
only — full detail lives in `journal/daily/day-NN-topic.md`.

---

## Index

| Date | Day | Module | Topic | Status | Major Learning | Issue |
|---|---|---|---|---|---|---|
| 2026-09-16 | [00](daily/day-00-setup-and-what-is-kubernetes.md) | 01 — Fundamentals | Setup and what is Kubernetes | COMPLETED | Kubernetes solves the problems Compose stops at; `apply` succeeding is not proof of running; lab environment confirmed viable | — |
| 2026-09-16 | [01](daily/day-01-cluster-setup.md) | 01 — Fundamentals | Cluster setup (LAB 01) | COMPLETED | A node is a container sharing the host kernel; a Pod's name reveals its creator; static Pods bootstrap the control plane; replica count is not redundancy; LAB 01 challenge run and understood | — |
| 2026-09-16 / 2026-09-18 | [02](daily/day-02-control-plane-and-nodes.md) | 01 — Fundamentals | Control plane vs worker node | COMPLETED | Node heartbeats via Lease objects; taint effect depends on the Pod's owning controller (DaemonSet = indefinite toleration, ReplicaSet = evicted+rescheduled); static Pod manifests confirmed on disk; concrete stateless-vs-stateful test (`--data-dir` + data volume); two distinct HA mechanisms in one control plane (Raft vs leader-election) | Found a real, verified single point of failure — both CoreDNS replicas on one node — fix deferred to Day 34/36 |
| 2026-09-18 | [03](daily/day-03-architecture-request-flow.md) | 01 — Fundamentals | Architecture and the request flow | COMPLETED | Traced `kubectl apply`'s 14-step flow live: admission injects tolerations not written in the manifest; the scheduler filters by taint before scoring — explains why plain Pods avoid the control-plane node and why CoreDNS doesn't; `Restart Count` vs `Age` track different things | Steps 1-3 and 5 of the request flow still theory-only — deferred to Day 39-41, 45, 65/80 |
| 2026-09-21 | [04](daily/day-04-kubectl-core.md) | 01 — Fundamentals | kubectl core verbs and output formats | COMPLETED | Ran and interpreted `-o yaml`, `-o jsonpath`, `--dry-run=server`, `-o custom-columns` + `--sort-by`, `logs`, `exec`; found `--dry-run=server` only previews admission on the submitted object, not on objects a controller creates afterward | Stopped `k8s-lab-control-plane` container recovered (`docker start`); `ErrImagePull` root-caused to a corporate TLS-inspecting proxy (Zscaler) and fixed — Mistake 003 |
| 2026-09-22 | [05](daily/day-05-namespaces-labels-selectors.md) | 01 — Fundamentals | Namespaces, labels, selectors, annotations | COMPLETED | Namespace isolation proven (same Deployment name in `default` and `dev`, no collision); label selectors confirmed as the real Service/Deployment matching mechanism; annotations proven structurally excluded from selection | Simultaneous Pod restart noticed (`162m ago`), not investigated |
| 2026-09-22 | [06](daily/day-06-pod-basics.md) | 01 — Fundamentals | Pod anatomy, YAML, lifecycle, phases | COMPLETED | First hand-written manifest, correct on first attempt; Pod-level `Status:` vs. container-level `State:` distinguished; bare Pod's lack of a controller proven by deletion | `Pending`/`Failed` phases not observed (cached image) — deferred to Day 08 |
| 2026-09-22 | [07](daily/day-07-multi-container-pods.md) | 02 — Workloads | Multi-container Pods, sidecars, init containers | COMPLETED | Init-container ordering and completion-gating proven; native sidecar (`restartPolicy: Always`) still waits its turn; shared-volume handoff proven with real file content; sidecar persistence confirmed | Recurring Zscaler `ImagePullBackOff` (Mistake 003 pattern), recognized and fixed fast |

---

## File naming

Daily entries live in `journal/daily/` and are named:

```text
day-NN-topic.md
```

Example: `day-00-setup-and-what-is-kubernetes.md`

| Part | Purpose |
|---|---|
| `day-NN` | Learning day counter, zero-padded so files sort in learning order. Does **not** have to match the calendar — skipped days do not consume a number |
| `topic` | Short kebab-case subject, so the file list reads as a curriculum |

The calendar date is **not** in the filename. It is recorded in the metadata
table at the top of each file, and in the `Date` column of the index above —
which is what makes this table the place to look when you need the chronology.

---

## How to read this file

- **Status** reflects the state at the end of that day, not the final state of
  the topic. A topic can appear IN PROGRESS on one day and COMPLETED later.
- **Issue** records anything that failed, broke, or stayed unresolved that day.
  An empty cell means nothing broke, which is rarer than it looks.
- Nothing in this table is edited retroactively to look cleaner. If a day went
  badly, the row stays as it was written.

## Status legend

| Marker | Meaning |
|---|---|
| NOT STARTED | Not begun |
| IN PROGRESS | Partially completed |
| COMPLETED | Theory + lab + verification + exercise all done |
| NEEDS REVISION | Completed, but knowledge gaps were demonstrated |
| BLOCKED | Cannot proceed until something is resolved |
