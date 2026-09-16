# Module 01 — Kubernetes Fundamentals

Author: Sagar Saitwal

Status: IN PROGRESS

---

## Goal

Build the mental model before touching any Kubernetes object. By the end of this
module you should be able to say *which component is responsible* for any given
behaviour, and prove it from a real cluster.

---

## Lessons

| # | Lesson | Status | File |
|---|---|---|---|
| 01 | What is Kubernetes and why do we need it? | Written, not yet verified | [01-what-is-kubernetes.md](01-what-is-kubernetes.md) |
| 02 | Control Plane vs Worker Node | NOT STARTED | — |
| 03 | Request flow: kubectl to API server to etcd to controller to scheduler to kubelet | NOT STARTED | — |
| 04 | Declarative vs imperative; desired state vs current state | NOT STARTED | — |
| 05 | Kubernetes objects and the API | NOT STARTED | — |
| 06 | Namespaces | NOT STARTED | — |
| 07 | Labels, selectors, annotations | NOT STARTED | — |

## Labs

| # | Lab | Status | File |
|---|---|---|---|
| 01 | Set up the Kubernetes learning environment | NOT STARTED | [labs/lab-01-lab-environment-setup.md](labs/lab-01-lab-environment-setup.md) |
| 02 | Inspect the control plane inside a real cluster | NOT STARTED | — |

---

## Subdirectories

| Directory | Contents |
|---|---|
| `architecture/` | Control plane and node component detail |
| `kubectl/` | kubectl mastery — Module 03 |
| `namespaces/` | Namespace isolation and scoping |
| `labels-selectors/` | Labels, selectors, annotations |
| `api/` | The Kubernetes API, API groups, versions, `kubectl explain` |
| `labs/` | Hands-on labs for this module |

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
**Next:** Module 02 — Architecture
