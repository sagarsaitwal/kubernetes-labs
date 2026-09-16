# Kubernetes Learning Roadmap

Author: Sagar Saitwal

This file explains **why** topics sit in this order.
For the day-by-day schedule, see [`daily-plan.md`](daily-plan.md).

## Learning spine

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

## Module sequence

| # | Module | Why it sits here |
|---|---|---|
| 01 | Kubernetes Fundamentals | Mental model before any object |
| 02 | Architecture | Must know which component is responsible before troubleshooting |
| 03 | kubectl | The only interface to everything that follows |
| 04 | Pods | The smallest deployable unit; everything else wraps it |
| 05 | ReplicaSets | Needed to understand what a Deployment actually manages |
| 06 | Deployments | The real workload primitive |
| 07 | Services | Pods are mortal and their IPs change; Services fix that |
| 08 | Networking | Explains *why* Services work the way they do |
| 09 | ConfigMaps & Secrets | Separating config from image (carries over from Docker) |
| 10 | Storage | Persistence across Pod rescheduling |
| 11 | Scheduling | Controlling *where* Pods land |
| 12 | Resources | Requests/limits, QoS, OOMKilled |
| 13 | Health Checks | Liveness, readiness, startup probes |
| 14 | Security / RBAC | Authentication, authorization, SecurityContext |
| 15 | Ingress | HTTP routing into the cluster |
| 16 | Helm | Packaging and templating |
| 17 | Monitoring | Prometheus, Grafana, metrics-server |
| 18 | Troubleshooting | Systematic diagnosis, not guessing |
| 19 | Kubernetes Internals | API server, etcd, controllers, reconciliation |
| 20 | CRD / Operators | Extending the API |
| 21 | Autoscaling | HPA, VPA, Cluster Autoscaler, KEDA |
| 22 | Production Kubernetes | HA, upgrades, backup, DR |
| 23 | AWS EKS | Managed Kubernetes, cloud specifics |
| 24 | Azure AKS | Second cloud for contrast |
| 25 | CI/CD | Git to build to registry to deploy |
| 26 | GitOps | Argo CD, Flux |
| 27 | Advanced Kubernetes | Gateway API, service mesh, eBPF, policy engines |
| 28 | CKA | Administration exam prep |
| 29 | CKAD | Application developer exam prep |
| 30 | CKS | Security specialist exam prep |

## Project progression

| Project | Contents | Unlocked after |
|---|---|---|
| 01 | Nginx + Deployment + Service | Module 07 |
| 02 | Python app + Service + ConfigMap | Module 09 |
| 03 | App + PostgreSQL + PVC + Secret | Module 10 |
| 04 | Ingress + TLS + Deployment + Service + ConfigMap + Secret | Module 15 |
| 05 | Prometheus + Grafana + metrics | Module 17 |
| 06 | Centralised logging | Module 18 |
| 07 | Git to CI/CD to image to registry to Kubernetes | Module 25 |
| 08 | GitOps with Argo CD | Module 26 |
| 09 | AWS EKS: VPC, node groups, ALB, IAM, storage | Module 23 |
| 10 | Production platform: HA, security, monitoring, logging, autoscaling, Ingress, CI/CD, GitOps | Module 27 |

## Teaching cycle applied to every major concept

```text
THEORY -> EXAMPLE -> COMMAND -> LAB -> BREAK SOMETHING
   -> TROUBLESHOOT -> FIX -> VERIFY -> DOCUMENT -> CHALLENGE
```

## Rule for marking progress

A module becomes COMPLETED only when all four are true:

1. Theory understood
2. Lab completed
3. Verification performed with real output
4. Practical exercise / challenge completed

Otherwise: IN PROGRESS, or NEEDS REVISION if completed but knowledge gaps showed.

## Status legend

| Marker | Meaning |
|---|---|
| NOT STARTED | Not begun |
| IN PROGRESS | Partially completed |
| COMPLETED | Theory + lab + verification + exercise all done |
| NEEDS REVISION | Completed, but gaps were demonstrated |
| BLOCKED | Cannot proceed until something is resolved |
