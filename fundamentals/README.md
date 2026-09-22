# Module 01 — Kubernetes Fundamentals

Author: Sagar Saitwal

Status: COMPLETED (Days 00-05 — see `progress/daily-plan.md`)

---

## Goal

Build the mental model before touching any Kubernetes object. By the end of this
module you should be able to say *which component is responsible* for any given
behaviour, and prove it from a real cluster.

---

## Lessons

**2026-09-22 — structural note:** this 7-lesson breakdown was the original
plan before the project moved to the Day 00-130 structure now governed by
`CLAUDE.md` and tracked in `progress/daily-plan.md`. That Day-based journal
(`journal/daily/day-NN-*.md`) is where the actual teaching, labs, and
verification now live and get updated every session — this table was left
behind when that shift happened and had gone stale. Retired as a
duplicate tracker; kept below only as a mapping to where each original
lesson's content actually lives now.

| # | Lesson | Status | Where it actually lives |
|---|---|---|---|
| 01 | What is Kubernetes and why do we need it? | **Covered & verified** | [01-what-is-kubernetes.md](01-what-is-kubernetes.md) (this file) + [Day 00](../journal/daily/day-00-setup-and-what-is-kubernetes.md)/[Day 01](../journal/daily/day-01-cluster-setup.md) |
| 02 | Control Plane vs Worker Node | **Covered & verified** | [Day 02](../journal/daily/day-02-control-plane-and-nodes.md) — static Pods, heartbeats/Lease, taints |
| 03 | Request flow: kubectl to API server to etcd to controller to scheduler to kubelet | **Covered & verified** | [Day 03](../journal/daily/day-03-architecture-request-flow.md) — traced live against a real Deployment |
| 04 | Declarative vs imperative; desired state vs current state | **Partial — no dedicated day** | Touched repeatedly, never as its own focused lesson: [Day 00](../journal/daily/day-00-setup-and-what-is-kubernetes.md) (reconciliation loop), [Day 03](../journal/daily/day-03-architecture-request-flow.md)/[Day 04](../journal/daily/day-04-kubectl-core.md) (`apply` idempotency, dry-run) |
| 05 | Kubernetes objects and the API | **Partial — no dedicated day** | Touched via [Day 04](../journal/daily/day-04-kubectl-core.md) (`-o yaml`/`-o jsonpath`/admission), not yet API groups/versions in depth — natural depth arrives at Day 64 (apiserver internals) |
| 06 | Namespaces | **Covered & verified** | [Day 05](../journal/daily/day-05-namespaces-labels-selectors.md) — isolation proven directly |
| 07 | Labels, selectors, annotations | **Covered & verified** | [Day 05](../journal/daily/day-05-namespaces-labels-selectors.md) — selector matching and the annotation boundary both proven directly |

Full day-by-day plan (all 131 days): [`progress/daily-plan.md`](../progress/daily-plan.md)

## Labs

Same structural note applies — see [`journal/daily/`](../journal/daily/)
for what actually ran, day by day.

| # | Lab | Status | File |
|---|---|---|---|
| 01 | Set up the Kubernetes learning environment | **Covered & verified** | [labs/lab-01-lab-environment-setup.md](labs/lab-01-lab-environment-setup.md) + [Day 01](../journal/daily/day-01-cluster-setup.md) (incl. node-failure break/fix challenge) |
| 02 | Inspect the control plane inside a real cluster | **Covered & verified** | [Day 02](../journal/daily/day-02-control-plane-and-nodes.md) — static Pod manifests read directly on the live cluster |

---

## Subdirectories

| Directory | Contents |
|---|---|
| `architecture/` | Empty — content ended up in [Day 03](../journal/daily/day-03-architecture-request-flow.md) instead |
| `kubectl/` | Empty — content ended up in [Day 04](../journal/daily/day-04-kubectl-core.md) instead |
| `namespaces/` | Empty — content ended up in [Day 05](../journal/daily/day-05-namespaces-labels-selectors.md) instead |
| `labels-selectors/` | Empty — content ended up in [Day 05](../journal/daily/day-05-namespaces-labels-selectors.md) instead |
| `api/` | Empty — no dedicated day yet; see the Lessons table's note on Lesson 05 |
| `labs/` | Hands-on labs for this module — still in active use |

These five topic subdirectories (all but `labs/`) predate the Day-based
structure and were never populated once that shift happened — left as
empty placeholders rather than deleted, in case a later module (or a
deliberate reference-doc pass) wants a topic-indexed home for this content
someday. Don't add new files into them by default; the day-NN journal is
the active record.

---

## The one idea this module exists to install

```text
        +----------------------------+
        |                            |
        v                            |
   DESIRED STATE              observe / compare
        |                            |
        v                            |
      ACT  ----------------->  CURRENT STATE
```

A reconciliation loop that never stops. Everything else in Kubernetes is a
specialisation of it.

---

## Where this sits

**Previous:** Docker phase — see `Reference/DockerSummary.md`
**Next:** Module 02 — Workloads (Days 06-13: Pods, ReplicaSets, Deployments,
StatefulSets, DaemonSets, Jobs, CronJobs — see
[`progress/daily-plan.md`](../progress/daily-plan.md)). Architecture and the
request flow (the old "Module 02" under the retired lesson numbering) are
already covered — see the Lessons table above.
