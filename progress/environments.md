# Lab Environments

Author: Sagar Saitwal

This repository is used from more than one machine. Each machine's facts are
recorded here, because several Kubernetes behaviours depend on them — available
memory caps cluster size, cgroup version decides whether `kind` works at all,
and kernel version affects which features are usable.

---

## The path convention

**The repository lives at the same path on every machine.**

| | Path |
|---|---|
| Windows | `D:\Kubernetes` |
| WSL / Linux | `/mnt/d/Kubernetes` |

One folder, one copy, synchronised through GitHub. Edited from Windows, run from
WSL. There is no separate lab directory and nothing is copied by hand.

### Why a fixed path rather than a variable

An environment variable is the right answer when a repository genuinely must
live at different paths — shared CI runners, multiple users, mixed operating
systems. None of that applies here: both machines are yours.

A convention you enforce once beats a variable you have to remember, and it
means every command in this repository can be copied verbatim to either machine.

### Why not a separate lab directory in `~`

The tempting alternative is a working directory inside WSL (`~/kubernetes-labs`)
with files copied back into the repository afterwards. It was rejected because
**the copy step is the one that gets forgotten** — a lab finished late, the YAML
never copied back, and the repository silently loses the thing it exists to
record. Two copies of a file also leaves no answer to "which one is current?".

One folder removes the question entirely.

---

## Machine 1 — IT-SAGARS

Primary machine. Verified 2026-09-16.

| Item | Value |
|---|---|
| Host OS | Windows 11 Pro 10.0.26200 |
| Linux | WSL2, FedoraLinux-44 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| systemd | active |
| Docker | Engine 29.7.2 — installed inside Fedora, **not** Docker Desktop |
| CPU | 8 cores |
| Memory | 7.6 GiB total |
| Disk free | 952 GiB |
| kubectl | v1.37.0 (Kustomize v5.8.1) |
| kind | v0.33.0 |
| Repository path | `D:\Kubernetes` / `/mnt/d/Kubernetes` |

### Notes

- Docker runs against a normal Linux daemon and socket — the same shape as a
  real Linux server, not the Docker Desktop VM setup common on Windows. This
  means there is no bundled single-node Kubernetes to inherit; every cluster is
  created explicitly.
- 7.6 GiB total memory is the binding constraint. A 3-node `kind` cluster uses
  roughly 1.2 GiB. Prometheus and Grafana (Day 55-56) will add more.

---

## Machine 2 — not yet recorded

Run this on the second machine and paste the output here:

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git /mnt/d/Kubernetes
cd /mnt/d/Kubernetes
bash scripts/utilities/setup-machine.sh
```

The clone path is not optional. Matching it is what keeps every command in this
repository valid on both machines.

The script prints a ready-made table to paste into this section.

| Item | Value |
|---|---|
| Host OS | |
| Linux | |
| Kernel | |
| Architecture | |
| cgroup | |
| Docker | |
| CPU | |
| Memory | |
| Disk free | |
| kubectl | |
| kind | |
| Repository path | |

---

## What does **not** transfer between machines

| Item | Transfers? | Why |
|---|:--:|---|
| Repository content | ✅ | Via git |
| Learning progress | ✅ | `progress/` and `journal/` are committed |
| Manifests and configs | ✅ | Committed YAML |
| **The cluster itself** | ❌ | A `kind` cluster is local Docker containers |
| **Objects running in it** | ❌ | They live in that cluster's etcd |
| **kubeconfig** | ❌ | Points at a local port; also `.gitignore`d deliberately |
| **Container images pulled** | ❌ | Local Docker cache |

### The implication worth internalising

**Cluster state is disposable; repository state is not.**

Anything worth keeping must be a committed manifest, not a live object. This is
not a limitation of `kind` — it is exactly the discipline that GitOps (Day 98)
formalises, and the reason a cluster reconstructed from Git is a recovery while
a cluster reconstructed from memory is an outage.

On switching machines, recreate the cluster:

```bash
cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

---

## Re-verifying an environment

WSL restarts, Docker upgrades, and kernel updates all change things silently.
Before a session that depends on the cluster:

```bash
stat -fc %T /sys/fs/cgroup    # must be cgroup2fs
docker info >/dev/null && echo "docker OK"
kind get clusters             # does a cluster already exist here?
kubectl get nodes             # is it healthy?
free -h                       # enough memory for what is planned?
```

Or simply re-run the setup script, which is safe to run repeatedly:

```bash
bash /mnt/d/Kubernetes/scripts/utilities/setup-machine.sh
```
