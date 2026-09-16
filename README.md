# Kubernetes Learning Journey

Author: Sagar Saitwal

A complete, chronological, hands-on record of learning Kubernetes from scratch
to production level — including every lab, every failure, and every fix.

---

## Why this repository exists

Most Kubernetes notes are a list of `kubectl` commands. That teaches recall, not
reasoning, and it collapses the first time a real cluster behaves unexpectedly.

This repository is built on the opposite premise: the useful skill is being able
to look at a broken cluster and work through

> What is happening? Why is it happening? Which component is responsible?
> How can I prove it? How can I fix it? How do I prevent it?

So this repository records the **process**, not a polished result. Failed
attempts stay in. Wrong initial understandings stay in, next to the corrected
version. The mistakes are the most valuable part of it.

## Learning objective

Become capable of designing, deploying, troubleshooting, securing, monitoring,
and operating Kubernetes clusters in real production environments — and, along
the way, be prepared for CKA, CKAD, and CKS.

---

## Roadmap

```text
Linux + Containers
       |
Kubernetes Fundamentals
       |
Pods  ->  Deployments  ->  Services
       |
Networking  ->  Storage  ->  ConfigMaps / Secrets
       |
Scheduling  ->  Security  ->  Ingress
       |
Helm  ->  Monitoring  ->  Troubleshooting
       |
Kubernetes Internals  ->  Production
       |
EKS / AKS  ->  CI/CD  ->  GitOps
       |
Advanced Kubernetes  ->  CKA / CKAD / CKS
```

---

## Current progress

**Day 00 of 130 — Module 01, Kubernetes Fundamentals — IN PROGRESS**

Currently at Lesson 01. No cluster exists yet; LAB 01 on Day 01 sets one up.

| | |
|---|---|
| Day-by-day plan | [`progress/daily-plan.md`](progress/daily-plan.md) — 131 days, 10 projects, 3 certifications |
| Where I stopped | [`progress/current-progress.md`](progress/current-progress.md) |
| What is next | [`progress/next-steps.md`](progress/next-steps.md) |

| Module | Topic | Status |
|:--:|---|---|
| 01 | Kubernetes Fundamentals | IN PROGRESS |
| 02 | Architecture | NOT STARTED |
| 03 | kubectl | NOT STARTED |
| 04 | Pods | NOT STARTED |
| 05 | ReplicaSets | NOT STARTED |
| 06 | Deployments | NOT STARTED |
| 07 | Services | NOT STARTED |
| 08 | Networking | NOT STARTED |
| 09 | ConfigMaps & Secrets | NOT STARTED |
| 10 | Storage | NOT STARTED |
| 11 | Scheduling | NOT STARTED |
| 12 | Resources | NOT STARTED |
| 13 | Health Checks | NOT STARTED |
| 14 | Security / RBAC | NOT STARTED |
| 15 | Ingress | NOT STARTED |
| 16 | Helm | NOT STARTED |
| 17 | Monitoring | NOT STARTED |
| 18 | Troubleshooting | NOT STARTED |
| 19 | Kubernetes Internals | NOT STARTED |
| 20 | CRD / Operators | NOT STARTED |
| 21 | Autoscaling | NOT STARTED |
| 22 | Production Kubernetes | NOT STARTED |
| 23 | AWS EKS | NOT STARTED |
| 24 | Azure AKS | NOT STARTED |
| 25 | CI/CD | NOT STARTED |
| 26 | GitOps | NOT STARTED |
| 27 | Advanced Kubernetes | NOT STARTED |
| 28 | CKA | NOT STARTED |
| 29 | CKAD | NOT STARTED |
| 30 | CKS | NOT STARTED |

**Nothing is marked COMPLETED until theory was understood, the lab was run, and
verification output was actually seen.**

### Next topic

LAB 01 — set up the Kubernetes learning environment.
See [`fundamentals/labs/lab-01-lab-environment-setup.md`](fundamentals/labs/lab-01-lab-environment-setup.md)

---

## How to use this repository

If you are learning Kubernetes yourself, this is the intended route:

| Step | Where |
|---|---|
| 1. See the whole plan | [`progress/daily-plan.md`](progress/daily-plan.md) — every day, Day 00 to Day 130 |
| 2. Understand the ordering | [`progress/roadmap.md`](progress/roadmap.md) |
| 3. Start the theory | [`fundamentals/`](fundamentals/) |
| 4. Do the lab before reading ahead | `*/labs/` |
| 5. Read the failures early | [`journal/mistakes-and-lessons.md`](journal/mistakes-and-lessons.md) |
| 6. Follow the narrative | [`journal/daily/`](journal/daily/) |
| 7. Copy working manifests | [`examples/`](examples/) |
| 8. Diagnose something broken | [`troubleshooting/`](troubleshooting/) |

Every lab is written so it can be run independently. Every command is documented
with what it does and why it was used, not just its syntax.

---

## Prerequisites

Assumed known before starting — all covered in the preceding Docker phase:

- Basic Linux: filesystem, processes, permissions, systemd, package management
- Basic networking: IP, ports, DNS, TCP
- Docker: images, layers, containers, volumes, networks, Compose
- YAML syntax
- Git

The Docker phase this builds on is summarised in
[`Reference/DockerSummary.md`](Reference/DockerSummary.md) — a 14-day hands-on
project, source at https://github.com/sagarsaitwal/docker-labs

---

## Lab environment

Local-first, free, and reproducible. No cloud spend for the fundamentals.

| Item | Value |
|---|---|
| Host OS | Windows 11 Pro |
| Linux | WSL2, FedoraLinux-44 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| Container runtime | Docker Engine 29.7.2, in-distro — **not** Docker Desktop |
| CPU | 8 |
| Memory | 7.6 GiB |
| Cluster tool | kind (Kubernetes IN Docker) — to be installed in LAB 01 |

Two details of this setup matter more than they look:

1. **Docker Engine, not Docker Desktop.** There is no bundled single-node
   Kubernetes to inherit. Every cluster here is created explicitly, which means
   every knob is visible rather than preconfigured.
2. **cgroup v2 unified.** kind runs each Kubernetes node as a Docker container,
   and the kubelet inside it needs a writable cgroup hierarchy to enforce Pod
   resource limits. Older WSL2 shipped a hybrid cgroup v1 layout that broke this.

`kubeadm` — building a cluster by hand — is deliberately deferred to Module 22,
once there is enough context for it to teach something.

Per-machine details: [`progress/environments.md`](progress/environments.md)

---

## Working across devices

This repository is used from more than one machine, so it is built to be the
portable state rather than relying on any single device.

### One folder, same path on every machine

| | Path |
|---|---|
| Windows | `D:\Kubernetes` |
| WSL / Linux | `/mnt/d/Kubernetes` |

Edited from Windows, run from WSL, synchronised through GitHub. There is no
separate lab directory and nothing is copied by hand — which means every command
in this repository can be copied verbatim to either machine.

### Setting up a new machine

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git /mnt/d/Kubernetes
cd /mnt/d/Kubernetes
bash scripts/utilities/setup-machine.sh
```

The clone path is not optional. The script then verifies prerequisites (cgroup
v2, Docker reachability, memory), installs `kubectl` and `kind` with checksum
verification if they are missing, and prints this machine's environment facts.

### What does and does not travel

| Travels via git | Does **not** travel |
|---|---|
| All repository content | The cluster — `kind` nodes are local Docker containers |
| Learning progress and journals | Objects running in it — they live in that cluster's etcd |
| Manifests and configuration | kubeconfig — points at a local port, and is `.gitignore`d |
| | Pulled container images — local Docker cache |

**Cluster state is disposable; repository state is not.** Anything worth keeping
must be a committed manifest, not a live object — which is the same discipline
GitOps formalises later in the course.

---

## Repository structure

```text
kubernetes-learning/
|
|-- README.md                 This file
|-- CLAUDE.md                 Working agreement; read first on any machine
|-- LICENSE                   MIT
|-- CONTRIBUTING.md           Conventions used throughout
|
|-- progress/                 Portable learning state (read this first)
|   |-- current-progress.md   Source of truth for where learning stopped
|   |-- daily-plan.md         Full Day 00-130 plan, every day and lab
|   |-- environments.md       Per-machine facts and the path convention
|   |-- roadmap.md            Module ordering and rationale
|   |-- completed-topics.md   Only verified completions
|   |-- next-steps.md         Queue and unresolved decisions
|
|-- journal/
|   |-- learning-journal.md          Chronological index, one row per day
|   |-- daily/                       Full detail, one file per learning day
|   |   |-- day-NN-topic.md
|   |-- TEMPLATE-daily-entry.md      Fixed section layout for new entries
|   |-- mistakes-and-lessons.md      Accumulated failures, searchable by symptom
|
|-- fundamentals/             Module 01-03: architecture, kubectl, namespaces, labels, API
|-- workloads/                Pods, ReplicaSets, Deployments, StatefulSets, DaemonSets, Jobs, CronJobs
|-- networking/               Pod networking, Services, DNS, Ingress, NetworkPolicy, CNI
|-- storage/                  Volumes, PV, PVC, StorageClasses, CSI
|-- configuration/            ConfigMaps, Secrets
|-- scheduling/               nodeSelector, affinity, taints/tolerations, topology spread
|-- security/                 RBAC, ServiceAccounts, SecurityContext, Pod Security
|-- resources/                Requests/limits, ResourceQuota, LimitRange, autoscaling
|-- health/                   Liveness, readiness, startup probes
|-- helm/                     Helm fundamentals, charts, projects
|-- observability/            Metrics, Prometheus, Grafana, logging, alerting
|-- troubleshooting/          Symptom-indexed diagnostic knowledge base
|-- internals/                API server, etcd, scheduler, controllers, kubelet, CRI/CNI/CSI
|-- aws/eks/                  Amazon EKS
|-- azure/aks/                Azure AKS
|-- cicd/                     GitLab, Jenkins, container registry
|-- gitops/argocd/            Argo CD
|-- examples/                 Small, focused, reusable manifests
|-- projects/                 Progressively harder end-to-end projects
|-- scripts/
|   |-- utilities/setup-machine.sh   One-command setup for a new machine
|
|-- Reference/                Source material and prerequisite summary
```

---

## Projects

Built after the modules that make them possible. Each gets its own README,
manifests, architecture diagram, and troubleshooting notes.

| # | Project | Contents | Status |
|:--:|---|---|---|
| 01 | First Kubernetes application | Nginx + Deployment + Service | NOT STARTED |
| 02 | Python web application | Deployment + Service + ConfigMap | NOT STARTED |
| 03 | Application + database | App + PostgreSQL + PVC + Secret | NOT STARTED |
| 04 | Production-style web app | Ingress + TLS + Deployment + Service + ConfigMap + Secret | NOT STARTED |
| 05 | Monitoring | Prometheus + Grafana + metrics | NOT STARTED |
| 06 | Logging | Centralised log collection | NOT STARTED |
| 07 | CI/CD | Git to CI to image to registry to Kubernetes | NOT STARTED |
| 08 | GitOps | Git to Argo CD to Kubernetes | NOT STARTED |
| 09 | AWS EKS | VPC + EKS + node groups + ALB + IAM + storage | NOT STARTED |
| 10 | Production platform | HA, security, monitoring, logging, autoscaling, Ingress, CI/CD, GitOps | NOT STARTED |

---

## Troubleshooting knowledge

A symptom-indexed reference built up as failures actually happen — not copied
from documentation. Each entry follows the same shape:

```text
SYMPTOM -> CHECK -> COMMAND -> OUTPUT -> INTERPRETATION
   -> ROOT CAUSE -> FIX -> VERIFICATION -> PREVENTION
```

Planned coverage: `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`,
`ErrImagePull`, `CreateContainerConfigError`, `OOMKilled`, `ContainerCreating`,
stuck `Terminating`, `NodeNotReady`, Service with no endpoints, DNS failure,
Ingress 404, Ingress 502, NetworkPolicy blocking traffic, PVC `Pending`, mount
failures, RBAC denied, probe failures, stuck rollouts, registry problems.

Currently empty — nothing has broken yet.

---

## Daily learning journal

One file per learning day in [`journal/daily/`](journal/daily/), named
`day-NN-topic.md` so the list sorts in learning order **and** reads as a
curriculum. The calendar date is recorded inside each file and in the index
table below.

Each entry records the objective, theory, every command with an explanation of
what it does and why, YAML, the lab performed, the environment, expected vs
actual result, what broke, the error message, the investigation, the root cause,
the fix, the verification, the lesson, and what comes next.

| Date | Day | Topic | Status |
|---|---|---|---|
| 2026-09-16 | [00](journal/daily/day-00-setup-and-what-is-kubernetes.md) | Setup and what is Kubernetes | PARTIALLY COMPLETED |

---

## Status legend

| Marker | Meaning |
|---|---|
| NOT STARTED | Not begun |
| IN PROGRESS | Partially completed |
| COMPLETED | Theory + lab + verification + exercise all done |
| NEEDS REVISION | Completed, but knowledge gaps were demonstrated |
| BLOCKED | Cannot proceed until something is resolved |

---

## A note on secrets

This repository is public. No credentials, keys, tokens, certificates, account
IDs, or private infrastructure details are committed. Placeholders are used
throughout: `<YOUR_AWS_ACCOUNT_ID>`, `<YOUR_DOMAIN>`, `<YOUR_REGION>`,
`<YOUR_REGISTRY>`, `<YOUR_SECRET>`.

Note also that a Kubernetes Secret is only base64-encoded, not encrypted. A
Secret manifest with real values is as sensitive as a plaintext password file
and is never committed here.

---

## License

MIT — see [LICENSE](LICENSE).
