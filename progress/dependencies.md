# Dependencies

Author: Sagar Saitwal

**Read this when resuming on a different machine.**

This repository travels through GitHub, but the things the labs actually run
against do not. This file lists everything that must exist on a device before
work can continue, and on which day each item first becomes necessary.

Automated check:

```bash
bash /mnt/d/Kubernetes/scripts/utilities/check-dependencies.sh
```

It reads the current day from `progress/current-progress.md` and reports only
what that day needs.

---

## The three kinds of dependency

| Kind | Lives where | Lost when | Recovery |
|---|---|---|---|
| **Host tool** | `/usr/local/bin` on the machine | Never, unless the machine changes | Install once per machine |
| **In-cluster component** | The cluster's etcd | **Every `kind delete cluster`** | Reinstall per cluster |
| **External account** | A cloud provider | Never | Credentials configured per machine, never committed |

The middle row is the one that surprises people. Installing the NGINX Ingress
Controller is not "setting up your machine" — it is an object inside a specific
cluster. Recreate the cluster and it is gone.

---

## 1. Baseline — required from Day 01 onward

Everything below must be present before any lab runs.

| Dependency | Check | Required from |
|---|---|:--:|
| WSL2 (not WSL1) | `wsl --list --verbose` shows version 2 | Day 01 |
| cgroup v2 unified | `stat -fc %T /sys/fs/cgroup` returns `cgroup2fs` | Day 01 |
| Docker daemon, no sudo | `docker info` succeeds | Day 01 |
| Free memory ≥ 2 GiB | `free -h` | Day 01 |
| Free disk ≥ 20 GiB | `df -h /` | Day 01 |
| `kubectl` | `kubectl version --client` | Day 01 |
| `kind` | `kind version` | Day 01 |
| Cluster `k8s-lab` | `kind get clusters` | Day 01 |
| All nodes `Ready` | `kubectl get nodes` | Day 01 |

### Installing the baseline on a new machine

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git /mnt/d/Kubernetes
cd /mnt/d/Kubernetes
bash scripts/utilities/setup-machine.sh

cd fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

---

## 2. Host tools, by the day they are first needed

Install only when you reach that day. Installing everything up front means
installing things you cannot yet explain.

| Day | Tool | Purpose | Install |
|:--:|---|---|---|
| 01 | `kubectl` | Talk to the API server | `setup-machine.sh` |
| 01 | `kind` | Create local clusters | `setup-machine.sh` |
| 49 | `helm` | Package manager | `curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
| 55 | `jq` | Parse JSON output in labs | `sudo dnf install -y jq` |
| 70 | `kubebuilder` *(optional)* | Scaffold controllers | See Day 70 |
| 78 | `kubeadm`, `kubelet` | Build a cluster by hand | See Day 78 |
| 80 | `etcdctl` | etcd snapshots and restore | `sudo dnf install -y etcd` |
| 83 | `aws` CLI v2 | AWS access | See Day 83 |
| 83 | `eksctl` | Create and manage EKS clusters | See Day 83 |
| 89 | `az` CLI | Azure access | See Day 89 |
| 99 | `argocd` CLI | Argo CD from the terminal | See Day 99 |
| 102 | `kubectl-gateway` *(optional)* | Gateway API helper | See Day 102 |
| 106 | `kyverno` CLI | Test policies locally | See Day 106 |
| 107 | `cosign`, `syft`, `trivy` | Signing, SBOM, scanning | See Day 107 |
| 109 | `tmux`, `vim` | Exam environment practice | `sudo dnf install -y tmux vim` |

---

## 3. In-cluster components — reinstalled per cluster, not per machine

**These are the ones that silently break a resumed session.** They are objects
inside a specific cluster. Switch machines, or delete and recreate the cluster,
and every one of them is gone.

| Day installed | Component | Namespace | Verify | Reinstall |
|:--:|---|---|---|---|
| 46 | NGINX Ingress Controller | `ingress-nginx` | `kubectl get pods -n ingress-nginx` | See Day 46 |
| 54 | metrics-server | `kube-system` | `kubectl top nodes` | See Day 54 |
| 55 | Prometheus | `monitoring` | `kubectl get pods -n monitoring` | See Day 55 |
| 56 | Grafana | `monitoring` | `kubectl get pods -n monitoring` | See Day 56 |
| 57 | kube-state-metrics, node-exporter | `monitoring` | `kubectl get pods -n monitoring` | See Day 57 |
| 58 | Log collector | `logging` | `kubectl get pods -n logging` | See Day 58 |
| 74 | HPA (needs metrics-server) | — | `kubectl get hpa -A` | See Day 74 |
| 99 | Argo CD | `argocd` | `kubectl get pods -n argocd` | See Day 99 |
| 104 | Istio | `istio-system` | `istioctl verify-install` | See Day 104 |
| 106 | Kyverno / Gatekeeper | `kyverno` | `kubectl get pods -n kyverno` | See Day 106 |

### The rule that follows from this

**Every in-cluster component must be installed from a committed manifest or a
recorded Helm command — never from a one-off command typed into a terminal.**

If reinstalling it requires remembering what you typed three weeks ago, it is
not reproducible, and the repository has failed at its job. This is the same
reasoning that leads to GitOps on Day 98.

---

## 4. External accounts and credentials

| Day | What | Notes |
|:--:|---|---|
| 83 | AWS account | Free tier where possible. **EKS control plane is not free — destroy clusters daily.** |
| 89 | Azure account | Free tier / credits. Same warning about running clusters. |
| 93 | GitLab or Jenkins | Can be self-hosted in the cluster instead |
| 94 | Container registry | Docker Hub account from the Docker phase is fine |

**No credential for any of these is ever committed.** Configure them per machine:

```bash
aws configure          # writes ~/.aws/credentials — gitignored
az login               # writes ~/.azure — gitignored
```

The `.gitignore` already blocks `.aws/`, `.azure/`, `credentials`, `*.pem`,
`*.key`, and `kubeconfig`. Verify before any push:

```bash
git status --porcelain
```

---

## 5. Resuming on a different machine

```bash
# 1. Get the latest repository state
cd /mnt/d/Kubernetes && git pull

# 2. See where work stopped
cat progress/current-progress.md

# 3. Check what this machine is missing for that day
bash scripts/utilities/check-dependencies.sh

# 4. Fix whatever it reports, then continue
```

### If the cluster does not exist on this machine

Expected — clusters are local. Recreate it:

```bash
cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

Then reinstall any in-cluster components for days already completed, from the
table in section 3.

### If the cluster exists but is missing components

Also expected if it was created before those days. Section 3 lists what each day
added, and every one has a committed manifest or recorded install command.

---

## 6. Version drift between machines

Two machines will not have identical tool versions unless forced. Usually
harmless, with two exceptions worth knowing:

| Risk | Why it matters | Guard |
|---|---|---|
| **kubectl / cluster skew** | Kubernetes supports only ±1 minor version between client and API server | `kubectl version` shows both. Pin the kind node image if the gap is wider |
| **kind node image version** | Different kind releases ship different Kubernetes versions, so two machines can run different clusters | `kind create cluster --image kindest/node:vX.Y.Z` to pin explicitly |

Record both machines' versions in `progress/environments.md`. When behaviour
differs between machines, version skew is the first thing to check — not the
last.
