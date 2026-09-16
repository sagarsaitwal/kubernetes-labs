# Daily Learning Plan — Day 00 to Day 130

Author: Sagar Saitwal

The full day-by-day plan from zero to production Kubernetes and CKA / CKAD / CKS.

---

## How to read this

- Each row becomes one file: `journal/daily/day-NN-topic.md`
- **Topics are fixed; the calendar is not.** A day that needs two sittings stays
  one day number. A skipped calendar day consumes no day number.
- A day is only `COMPLETED` when theory + lab + verification + exercise all
  actually happened.
- **This plan will change.** Some topics will turn out to need two days, others
  will collapse into one. Revisions are expected and should be recorded, not
  hidden.

## Pacing assumption

Roughly 1-2 focused hours per day: one concept, one lab, one deliberate
break/fix cycle, one journal entry. At a steady 5 days per week this is about
6 months. At 3 days per week, about 10.

## Status summary

| | |
|---|---|
| Total planned days | 131 (Day 00 - Day 130) |
| Completed | 1 (Day 00) |
| In progress | 1 (Day 01 — LAB 01 challenge outstanding) |
| Projects | 10 |
| Certifications targeted | CKA, CKAD, CKS |

---

## Phase 1 — Foundations (Days 00-05)

Module 01-03. Goal: know what Kubernetes is, have a working cluster, and be
fluent enough with `kubectl` that it stops being an obstacle.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 00 | Setup and what is Kubernetes | `day-00-setup-and-what-is-kubernetes.md` | — | COMPLETED |
| 01 | Cluster setup with kind | `day-01-cluster-setup.md` | LAB 01 | PARTIALLY COMPLETED |
| 02 | Control plane vs worker node | `day-02-control-plane-and-nodes.md` | LAB 02 | NOT STARTED |
| 03 | Architecture and the request flow | `day-03-architecture-request-flow.md` | LAB 03 | NOT STARTED |
| 04 | kubectl core verbs and output formats | `day-04-kubectl-core.md` | LAB 04 | NOT STARTED |
| 05 | Namespaces, labels, selectors, annotations | `day-05-namespaces-labels-selectors.md` | LAB 05 | NOT STARTED |

---

## Phase 2 — Workloads (Days 06-13)

Module 04-06. Goal: understand what actually runs, and what keeps it running.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 06 | Pod anatomy, YAML, lifecycle, phases | `day-06-pod-basics.md` | LAB 06 | NOT STARTED |
| 07 | Multi-container Pods, sidecars, init containers | `day-07-multi-container-pods.md` | LAB 07 | NOT STARTED |
| 08 | Pod failures: Pending, CrashLoopBackOff, ImagePullBackOff | `day-08-pod-troubleshooting.md` | LAB 08 (break/fix) | NOT STARTED |
| 09 | ReplicaSets and why you rarely write one | `day-09-replicasets.md` | LAB 09 | NOT STARTED |
| 10 | Deployments and rolling updates | `day-10-deployments.md` | LAB 10 | NOT STARTED |
| 11 | Rollout history, rollback, update strategies | `day-11-rollouts-and-rollback.md` | LAB 11 | NOT STARTED |
| 12 | DaemonSets, Jobs, CronJobs | `day-12-daemonsets-jobs-cronjobs.md` | LAB 12 | NOT STARTED |
| 13 | StatefulSets — identity and ordering | `day-13-statefulsets-intro.md` | LAB 13 | NOT STARTED |

---

## Phase 3 — Networking (Days 14-20)

Module 07-08. Goal: understand how anything reaches anything else — and be able
to prove where traffic stops.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 14 | Pod networking, Pod IPs, the flat network model | `day-14-pod-networking.md` | LAB 14 | NOT STARTED |
| 15 | Services: ClusterIP | `day-15-services-clusterip.md` | LAB 15 | NOT STARTED |
| 16 | Services: NodePort, LoadBalancer, ExternalName | `day-16-services-nodeport-loadbalancer.md` | LAB 16 + **PROJECT 01** | NOT STARTED |
| 17 | DNS, CoreDNS, service discovery | `day-17-dns-and-coredns.md` | LAB 17 | NOT STARTED |
| 18 | Endpoints, EndpointSlices, kube-proxy, iptables/IPVS | `day-18-endpoints-and-kube-proxy.md` | LAB 18 | NOT STARTED |
| 19 | CNI: how pod networking is actually implemented | `day-19-cni.md` | LAB 19 | NOT STARTED |
| 20 | NetworkPolicy and network troubleshooting | `day-20-network-policy-and-troubleshooting.md` | LAB 20 (break/fix) | NOT STARTED |

**PROJECT 01** — Nginx + Deployment + Service. First end-to-end application.

---

## Phase 4 — Configuration (Days 21-23)

Module 09. Goal: one image, many environments.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 21 | ConfigMaps: env vars and volume mounts | `day-21-configmaps.md` | LAB 21 | NOT STARTED |
| 22 | Secrets, and why base64 is not encryption | `day-22-secrets.md` | LAB 22 | NOT STARTED |
| 23 | Config reload behaviour, immutability, common traps | `day-23-config-patterns.md` | LAB 23 + **PROJECT 02** | NOT STARTED |

**PROJECT 02** — Python web application + Service + ConfigMap.

---

## Phase 5 — Storage (Days 24-28)

Module 10. Goal: data that survives the Pod.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 24 | Volumes: emptyDir, hostPath, and their lifecycles | `day-24-volumes.md` | LAB 24 | NOT STARTED |
| 25 | PersistentVolume and PersistentVolumeClaim | `day-25-pv-and-pvc.md` | LAB 25 | NOT STARTED |
| 26 | StorageClass and dynamic provisioning | `day-26-storageclass.md` | LAB 26 | NOT STARTED |
| 27 | StatefulSet with persistent storage | `day-27-statefulset-storage.md` | LAB 27 + **PROJECT 03** | NOT STARTED |
| 28 | Storage failures: PVC Pending, mount errors, access modes | `day-28-storage-troubleshooting.md` | LAB 28 (break/fix) | NOT STARTED |

**PROJECT 03** — Application + PostgreSQL + PVC + Secret.

---

## Phase 6 — Resources and Scheduling (Days 29-36)

Module 11-12. Goal: control where workloads land and what they may consume.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 29 | Requests, limits, and QoS classes | `day-29-requests-and-limits.md` | LAB 29 | NOT STARTED |
| 30 | OOMKilled and CPU throttling, diagnosed properly | `day-30-oomkilled-and-throttling.md` | LAB 30 (break/fix) | NOT STARTED |
| 31 | ResourceQuota and LimitRange | `day-31-quota-and-limitrange.md` | LAB 31 | NOT STARTED |
| 32 | The scheduler: filtering and scoring | `day-32-scheduler-basics.md` | LAB 32 | NOT STARTED |
| 33 | nodeSelector and node affinity | `day-33-nodeselector-and-affinity.md` | LAB 33 | NOT STARTED |
| 34 | Pod affinity and anti-affinity | `day-34-pod-affinity.md` | LAB 34 | NOT STARTED |
| 35 | Taints, tolerations, and node isolation | `day-35-taints-and-tolerations.md` | LAB 35 | NOT STARTED |
| 36 | Topology spread, PriorityClass, preemption | `day-36-topology-spread-and-priority.md` | LAB 36 | NOT STARTED |

---

## Phase 7 — Health and Reliability (Days 37-38)

Module 13. Goal: let Kubernetes know when your app is actually usable.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 37 | Liveness, readiness, and startup probes | `day-37-probes.md` | LAB 37 (break/fix) | NOT STARTED |
| 38 | Graceful shutdown, preStop, termination grace period | `day-38-graceful-shutdown.md` | LAB 38 | NOT STARTED |

---

## Phase 8 — Security (Days 39-45)

Module 14. Goal: least privilege, and being able to prove it.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 39 | Authentication and authorization: how a request is allowed | `day-39-authn-and-authz.md` | LAB 39 | NOT STARTED |
| 40 | RBAC: Role and RoleBinding | `day-40-rbac-roles.md` | LAB 40 | NOT STARTED |
| 41 | RBAC: ClusterRole, ClusterRoleBinding, aggregation | `day-41-rbac-clusterroles.md` | LAB 41 | NOT STARTED |
| 42 | ServiceAccounts and workload identity | `day-42-serviceaccounts.md` | LAB 42 | NOT STARTED |
| 43 | SecurityContext, capabilities, runAsNonRoot, readOnlyRootFilesystem | `day-43-security-context.md` | LAB 43 | NOT STARTED |
| 44 | Pod Security Standards and Pod Security Admission | `day-44-pod-security-standards.md` | LAB 44 | NOT STARTED |
| 45 | Image security, supply chain, RBAC troubleshooting | `day-45-image-security-and-rbac-debugging.md` | LAB 45 (break/fix) | NOT STARTED |

---

## Phase 9 — Ingress (Days 46-48)

Module 15. Goal: real traffic from outside the cluster.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 46 | Ingress and Ingress Controllers: the split responsibility | `day-46-ingress-concepts.md` | LAB 46 | NOT STARTED |
| 47 | Path and host routing, rewrite rules | `day-47-ingress-routing.md` | LAB 47 | NOT STARTED |
| 48 | TLS termination, and Ingress 404 vs 502 | `day-48-ingress-tls-and-troubleshooting.md` | LAB 48 (break/fix) + **PROJECT 04** | NOT STARTED |

**PROJECT 04** — Production-style web app: Ingress + TLS + Deployment + Service + ConfigMap + Secret.

---

## Phase 10 — Helm (Days 49-52)

Module 16. Goal: package and parameterise, without losing sight of the YAML.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 49 | Helm concepts: charts, releases, repositories | `day-49-helm-fundamentals.md` | LAB 49 | NOT STARTED |
| 50 | Installing and inspecting third-party charts | `day-50-helm-install-charts.md` | LAB 50 | NOT STARTED |
| 51 | Writing your own chart: templates and values | `day-51-helm-authoring.md` | LAB 51 | NOT STARTED |
| 52 | Upgrade, rollback, dependencies, environment overlays | `day-52-helm-lifecycle.md` | LAB 52 | NOT STARTED |

---

## Phase 11 — Observability (Days 53-58)

Module 17. Goal: know what is happening before someone tells you.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 53 | Logs, events, and their retention limits | `day-53-logs-and-events.md` | LAB 53 | NOT STARTED |
| 54 | metrics-server and `kubectl top` | `day-54-metrics-server.md` | LAB 54 | NOT STARTED |
| 55 | Prometheus: scraping, targets, PromQL basics | `day-55-prometheus.md` | LAB 55 | NOT STARTED |
| 56 | Grafana: dashboards and what to actually put on them | `day-56-grafana.md` | LAB 56 + **PROJECT 05** | NOT STARTED |
| 57 | kube-state-metrics and node-exporter | `day-57-kube-state-metrics.md` | LAB 57 | NOT STARTED |
| 58 | Centralised logging and alerting | `day-58-logging-and-alerting.md` | LAB 58 + **PROJECT 06** | NOT STARTED |

**PROJECT 05** — Prometheus + Grafana + metrics.
**PROJECT 06** — Centralised log collection.

---

## Phase 12 — Systematic Troubleshooting (Days 59-63)

Module 18. Goal: consolidate every failure mode into one repeatable method.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 59 | The methodology: observe, isolate, prove, fix, prevent | `day-59-troubleshooting-method.md` | LAB 59 | NOT STARTED |
| 60 | Workload failures end to end | `day-60-workload-failures.md` | LAB 60 (break/fix) | NOT STARTED |
| 61 | Networking failures end to end | `day-61-network-failures.md` | LAB 61 (break/fix) | NOT STARTED |
| 62 | Storage and scheduling failures end to end | `day-62-storage-scheduling-failures.md` | LAB 62 (break/fix) | NOT STARTED |
| 63 | Cluster and node-level failures | `day-63-cluster-failures.md` | LAB 63 (break/fix) | NOT STARTED |

---

## Phase 13 — Internals (Days 64-69)

Module 19. Goal: stop treating the control plane as a black box.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 64 | API server: request path, admission chain, API groups | `day-64-api-server.md` | LAB 64 | NOT STARTED |
| 65 | etcd: the cluster's only database | `day-65-etcd.md` | LAB 65 | NOT STARTED |
| 66 | Controllers, the reconciliation loop, informers and watches | `day-66-controllers-and-reconciliation.md` | LAB 66 | NOT STARTED |
| 67 | Scheduler internals: plugins, extension points | `day-67-scheduler-internals.md` | LAB 67 | NOT STARTED |
| 68 | kubelet and the CRI | `day-68-kubelet-and-cri.md` | LAB 68 | NOT STARTED |
| 69 | CNI and CSI internals | `day-69-cni-and-csi-internals.md` | LAB 69 | NOT STARTED |

---

## Phase 14 — Extending Kubernetes (Days 70-73)

Module 20. Goal: the API is not a fixed list.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 70 | CustomResourceDefinitions | `day-70-crds.md` | LAB 70 | NOT STARTED |
| 71 | Writing a simple controller | `day-71-custom-controller.md` | LAB 71 | NOT STARTED |
| 72 | The Operator pattern, and real-world operators | `day-72-operators.md` | LAB 72 | NOT STARTED |
| 73 | Admission webhooks: mutating and validating | `day-73-admission-webhooks.md` | LAB 73 | NOT STARTED |

---

## Phase 15 — Autoscaling (Days 74-76)

Module 21.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 74 | HorizontalPodAutoscaler | `day-74-hpa.md` | LAB 74 | NOT STARTED |
| 75 | VerticalPodAutoscaler and Cluster Autoscaler | `day-75-vpa-and-cluster-autoscaler.md` | LAB 75 | NOT STARTED |
| 76 | KEDA and event-driven scaling | `day-76-keda.md` | LAB 76 | NOT STARTED |

---

## Phase 16 — Production Kubernetes (Days 77-82)

Module 22. Goal: what changes when it is not a lab.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 77 | HA control plane and etcd quorum | `day-77-ha-control-plane.md` | LAB 77 | NOT STARTED |
| 78 | Building a cluster with kubeadm | `day-78-kubeadm.md` | LAB 78 | NOT STARTED |
| 79 | Cluster upgrades without downtime | `day-79-cluster-upgrades.md` | LAB 79 | NOT STARTED |
| 80 | Backup, restore, etcd snapshots, disaster recovery | `day-80-backup-and-restore.md` | LAB 80 | NOT STARTED |
| 81 | Multi-tenancy, namespace strategy, network design | `day-81-multi-tenancy.md` | LAB 81 | NOT STARTED |
| 82 | Capacity planning and cost optimisation | `day-82-capacity-and-cost.md` | LAB 82 | NOT STARTED |

---

## Phase 17 — AWS EKS (Days 83-88)

Module 23. **Costs money — use free tier where possible and destroy resources daily.**

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 83 | EKS architecture and the managed control plane | `day-83-eks-architecture.md` | LAB 83 | NOT STARTED |
| 84 | VPC design, subnets, and the AWS VPC CNI | `day-84-eks-networking.md` | LAB 84 | NOT STARTED |
| 85 | Node groups, managed nodes, Fargate | `day-85-eks-nodes.md` | LAB 85 | NOT STARTED |
| 86 | IAM, IRSA, and workload identity | `day-86-eks-iam-and-irsa.md` | LAB 86 | NOT STARTED |
| 87 | ALB Ingress Controller and EBS/EFS CSI | `day-87-eks-ingress-and-storage.md` | LAB 87 | NOT STARTED |
| 88 | EKS autoscaling, logging, upgrades | `day-88-eks-operations.md` | LAB 88 + **PROJECT 09** | NOT STARTED |

**PROJECT 09** — AWS EKS: VPC + EKS + node groups + ALB + IAM + storage.

---

## Phase 18 — Azure AKS (Days 89-92)

Module 24. Goal: a second cloud, for contrast rather than repetition.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 89 | AKS architecture and how it differs from EKS | `day-89-aks-architecture.md` | LAB 89 | NOT STARTED |
| 90 | AKS networking: kubenet vs Azure CNI | `day-90-aks-networking.md` | LAB 90 | NOT STARTED |
| 91 | Entra ID integration, managed identity, Azure RBAC | `day-91-aks-identity.md` | LAB 91 | NOT STARTED |
| 92 | AKS storage, ingress, scaling, upgrades | `day-92-aks-operations.md` | LAB 92 | NOT STARTED |

---

## Phase 19 — CI/CD (Days 93-97)

Module 25.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 93 | Pipeline design: build, scan, push, deploy | `day-93-pipeline-design.md` | LAB 93 | NOT STARTED |
| 94 | Container registry, image tagging and promotion strategy | `day-94-registry-and-tagging.md` | LAB 94 | NOT STARTED |
| 95 | GitLab CI to Kubernetes | `day-95-gitlab-ci.md` | LAB 95 | NOT STARTED |
| 96 | Jenkins to Kubernetes | `day-96-jenkins.md` | LAB 96 | NOT STARTED |
| 97 | Deployment strategies: blue/green, canary | `day-97-deployment-strategies.md` | LAB 97 + **PROJECT 07** | NOT STARTED |

**PROJECT 07** — Git to CI to image to registry to Kubernetes.

---

## Phase 20 — GitOps (Days 98-101)

Module 26.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 98 | GitOps principles and why drift matters | `day-98-gitops-principles.md` | LAB 98 | NOT STARTED |
| 99 | Argo CD: install, applications, sync policies | `day-99-argocd-basics.md` | LAB 99 | NOT STARTED |
| 100 | App-of-apps, projects, RBAC, multi-environment | `day-100-argocd-advanced.md` | LAB 100 | NOT STARTED |
| 101 | Secrets in GitOps, drift detection, rollback | `day-101-gitops-secrets-and-drift.md` | LAB 101 + **PROJECT 08** | NOT STARTED |

**PROJECT 08** — Git to Argo CD to Kubernetes.

---

## Phase 21 — Advanced Kubernetes (Days 102-108)

Module 27.

| Day | Topic | File | Lab | Status |
|:--:|---|---|---|---|
| 102 | Gateway API: the successor to Ingress | `day-102-gateway-api.md` | LAB 102 | NOT STARTED |
| 103 | Service mesh concepts and the sidecar/ambient split | `day-103-service-mesh-concepts.md` | LAB 103 | NOT STARTED |
| 104 | Istio: traffic management, mTLS, observability | `day-104-istio.md` | LAB 104 | NOT STARTED |
| 105 | Cilium and eBPF networking | `day-105-cilium-and-ebpf.md` | LAB 105 | NOT STARTED |
| 106 | Policy engines: Kyverno and OPA/Gatekeeper | `day-106-policy-engines.md` | LAB 106 | NOT STARTED |
| 107 | Supply chain security: signing, SBOM, admission | `day-107-supply-chain-security.md` | LAB 107 | NOT STARTED |
| 108 | Multi-cluster patterns and Cluster API | `day-108-multi-cluster.md` | LAB 108 | NOT STARTED |

---

## Phase 22 — CKA Preparation (Days 109-114)

Module 28. Administration focus. Timed practice from here on.

| Day | Topic | File | Status |
|:--:|---|---|---|
| 109 | CKA domains, exam mechanics, environment setup | `day-109-cka-overview.md` | NOT STARTED |
| 110 | Cluster architecture, installation, configuration drills | `day-110-cka-cluster-drills.md` | NOT STARTED |
| 111 | Workloads and scheduling drills | `day-111-cka-workload-drills.md` | NOT STARTED |
| 112 | Services and networking drills | `day-112-cka-networking-drills.md` | NOT STARTED |
| 113 | Storage and troubleshooting drills | `day-113-cka-storage-troubleshooting-drills.md` | NOT STARTED |
| 114 | Full timed mock exam and review | `day-114-cka-mock-exam.md` | NOT STARTED |

---

## Phase 23 — CKAD Preparation (Days 115-119)

Module 29. Application developer focus.

| Day | Topic | File | Status |
|:--:|---|---|---|
| 115 | CKAD domains and speed technique | `day-115-ckad-overview.md` | NOT STARTED |
| 116 | Application design and build drills | `day-116-ckad-design-drills.md` | NOT STARTED |
| 117 | Deployment, configuration, observability drills | `day-117-ckad-deployment-drills.md` | NOT STARTED |
| 118 | Services and networking drills | `day-118-ckad-networking-drills.md` | NOT STARTED |
| 119 | Full timed mock exam and review | `day-119-ckad-mock-exam.md` | NOT STARTED |

---

## Phase 24 — CKS Preparation (Days 120-126)

Module 30. Security specialist focus. **Requires a valid CKA first.**

| Day | Topic | File | Status |
|:--:|---|---|---|
| 120 | CKS domains and threat model | `day-120-cks-overview.md` | NOT STARTED |
| 121 | Cluster setup and hardening drills | `day-121-cks-cluster-hardening.md` | NOT STARTED |
| 122 | System hardening and minimising microservice vulnerabilities | `day-122-cks-system-hardening.md` | NOT STARTED |
| 123 | Supply chain security drills | `day-123-cks-supply-chain.md` | NOT STARTED |
| 124 | Runtime security: Falco, audit logs, seccomp, AppArmor | `day-124-cks-runtime-security.md` | NOT STARTED |
| 125 | Monitoring, logging, and runtime detection drills | `day-125-cks-detection-drills.md` | NOT STARTED |
| 126 | Full timed mock exam and review | `day-126-cks-mock-exam.md` | NOT STARTED |

---

## Phase 25 — Capstone (Days 127-130)

**PROJECT 10** — a complete production-style platform, built from scratch and
documented as if handing it to a team.

| Day | Topic | File | Status |
|:--:|---|---|---|
| 127 | Architecture design and decision record | `day-127-capstone-design.md` | NOT STARTED |
| 128 | Platform build: HA, networking, storage, security | `day-128-capstone-build.md` | NOT STARTED |
| 129 | Observability, autoscaling, CI/CD, GitOps integration | `day-129-capstone-operations.md` | NOT STARTED |
| 130 | Failure injection, disaster recovery drill, handover docs | `day-130-capstone-validation.md` | NOT STARTED |

---

## Project index

| # | Project | Planned day | Status |
|:--:|---|:--:|---|
| 01 | Nginx + Deployment + Service | 16 | NOT STARTED |
| 02 | Python app + Service + ConfigMap | 23 | NOT STARTED |
| 03 | App + PostgreSQL + PVC + Secret | 27 | NOT STARTED |
| 04 | Ingress + TLS + full config | 48 | NOT STARTED |
| 05 | Prometheus + Grafana + metrics | 56 | NOT STARTED |
| 06 | Centralised logging | 58 | NOT STARTED |
| 07 | CI/CD to Kubernetes | 97 | NOT STARTED |
| 08 | GitOps with Argo CD | 101 | NOT STARTED |
| 09 | AWS EKS platform | 88 | NOT STARTED |
| 10 | Production Kubernetes platform (capstone) | 127-130 | NOT STARTED |

---

## Break / fix days

Days where something is deliberately broken before it is fixed. These are the
highest-value days in the plan and should not be skipped when short on time.

| Day | What gets broken |
|:--:|---|
| 08 | Pod failures: Pending, CrashLoopBackOff, ImagePullBackOff |
| 20 | NetworkPolicy blocking traffic, Service with no endpoints |
| 28 | PVC Pending, mount failures, wrong access mode |
| 30 | OOMKilled and CPU throttling |
| 37 | Failing liveness and readiness probes |
| 45 | RBAC permission denied |
| 48 | Ingress 404 vs 502 |
| 60-63 | Consolidated failure injection across all areas |
| 130 | Full disaster recovery drill |

---

## Revision log

Changes to this plan get recorded here rather than silently applied.

| Date | Change | Reason |
|---|---|---|
| 2026-09-16 | Plan created | Initial scope: Day 00-130 |
| 2026-09-16 | Day 00 completed, Day 01 partially completed | Cluster built and verified; LAB 01 break/fix challenge carried forward |
