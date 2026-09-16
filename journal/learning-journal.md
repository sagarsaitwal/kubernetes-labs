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
| 2026-09-16 | [02](daily/day-02-control-plane-and-nodes.md) | 01 — Fundamentals | Control plane vs worker node | IN PROGRESS | Node heartbeats via Lease objects; Node Lifecycle Controller marks `NotReady` after ~40s grace period; a taint's effect depends on the Pod's owning controller — DaemonSet Pods get an indefinite toleration and are never evicted, only ReplicaSet-owned Pods actually get rescheduled; event history is more reliable than live terminal output | Static manifest check and CoreDNS placement re-check still pending |

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
