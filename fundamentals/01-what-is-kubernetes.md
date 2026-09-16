# Module 01 — Lesson 01: What is Kubernetes and Why Do We Need It?

Author: Sagar Saitwal

Status: theory written, not yet verified by lab

---

## 1. Start from where Docker stopped

The Docker phase ended with a working Compose stack: a Node API and Postgres,
with `depends_on: condition: service_healthy` fixing a genuine startup race.

That stack works. Ask four questions about it:

| Question | Compose answer |
|---|---|
| The host reboots. What restarts the app? | `restart: always` — **if the Docker daemon starts, and if the host comes back** |
| The host's disk dies. What restarts the app? | Nothing. There is one host |
| Traffic triples. What adds capacity? | You, manually, on a second machine you configure by hand |
| A new image is pushed. How does it roll out with no downtime? | `docker compose up -d` recreates the container. There is a gap |

Every one of those failures has the same shape: **something has to notice, decide,
and act — and on a single Docker host, that something is a human.**

Kubernetes is that something.

---

## 2. What Kubernetes actually is

> Kubernetes is a **container orchestrator**: a control system that continuously
> compares the state you declared against the state that exists, and takes action
> to close the gap.

That sentence is the whole thing. Everything else is detail.

The formal name for this is a **reconciliation loop**:

```text
        +----------------------------+
        |                            |
        v                            |
   DESIRED STATE              observe / compare
   "3 replicas of nginx"             ^
        |                            |
        v                            |
      ACT  ----------------->  CURRENT STATE
   create / delete / update   "2 replicas running"
```

This loop never stops. It is not triggered by your command — your command only
changes the desired state. The loop was already running, and it runs forever.

**This is the single most important idea in Kubernetes.** Almost every confusing
behaviour later ("why did my Pod come back after I deleted it?", "why is my
rollout stuck?", "why did that node's Pods reappear elsewhere?") is this loop
doing exactly what it was told.

### Contrast with Docker

| | Docker | Kubernetes |
|---|---|---|
| Model | **Imperative** — "do this now" | **Declarative** — "keep it looking like this" |
| Command | `docker run nginx` | `kubectl apply -f deployment.yaml` |
| Result | A container exists because you made it | An object exists that a controller is now responsible for |
| You delete a container | It stays deleted | A controller notices and creates a replacement |
| Scope | One host | A pool of hosts, as one resource |

You already met a small version of this in Docker: `restart: always` is a tiny
reconciliation loop, scoped to one container on one host. Kubernetes generalises
it to every object, across every node.

---

## 3. The problems Kubernetes solves

Each of these is a problem you would hit next if you kept scaling the Compose
setup.

| Problem | What Kubernetes does |
|---|---|
| **Self-healing** | A container crashes, or a whole node dies — replacements are created elsewhere automatically |
| **Scheduling** | You say "run this"; Kubernetes decides *which machine* has the CPU, memory, and constraints to host it |
| **Horizontal scaling** | Change a replica count, or let a metric change it for you |
| **Service discovery** | Pods get new IPs constantly. A Service gives a stable name and address in front of them |
| **Load balancing** | Traffic to that name is spread across healthy backends automatically |
| **Rolling updates and rollback** | New version replaces old gradually, with health gates and a one-command undo |
| **Configuration separation** | ConfigMaps and Secrets injected at runtime, so one image serves every environment |
| **Storage abstraction** | A workload asks for "10Gi, ReadWriteOnce" without naming a disk or a host |
| **Resource governance** | Requests, limits, quotas, and priorities shared fairly across teams |
| **Declarative infrastructure** | The whole system is described in version-controlled YAML |

### The honest counterweight

Kubernetes is not free. It adds a control plane to run, a large API to learn,
and a lot of failure modes that simply do not exist on one Docker host. If you
run one application on one machine and can tolerate a restart, **Compose is the
correct answer** and Kubernetes is overhead.

Knowing when *not* to use it is part of knowing it.

---

## 4. Kubernetes vs Docker vs Docker Compose

These are the three most commonly confused items, and they are not competitors.

```text
Docker            builds and runs ONE container on ONE host
Docker Compose    runs MANY containers on ONE host, declaratively
Kubernetes        runs MANY containers across MANY hosts, declaratively,
                  and keeps them running without you
```

### "Kubernetes replaced Docker" — what actually happened

A widely misread piece of news. The facts:

- Kubernetes talks to a container runtime through an interface called the **CRI**
  (Container Runtime Interface).
- Docker Engine predates the CRI and does not speak it. Kubernetes used a shim
  called **dockershim** to translate.
- In Kubernetes **1.24**, dockershim was removed. Kubernetes stopped shipping
  built-in support for Docker Engine as a *node runtime*.

What that did **not** mean:

- Images you build with Docker still work perfectly. They are **OCI images** — an
  open standard. Kubernetes runs them everywhere.
- Docker is still the normal way to build images for Kubernetes.
- Your Docker knowledge transfers completely.

What clusters use as a node runtime today is usually **containerd** (which Docker
itself uses underneath) or **CRI-O**.

> A pleasing detail for this specific setup: kind runs Kubernetes nodes as Docker
> containers, and inside each of those containers the runtime is containerd. You
> will be able to see both layers directly in LAB 01.

---

## 5. Real-world example

A retail web application during a sale.

**On Compose, one host:**

Traffic spikes. One container saturates. You SSH in, edit the Compose file, add
replicas — and hit the ceiling of a single machine's CPU. To add a second
machine you configure it by hand, then put a load balancer in front and maintain
its backend list yourself. If a machine dies at 2am, someone's phone rings.

**On Kubernetes:**

You declare the app should run with 3 replicas, each requesting 200m CPU and
256Mi memory, behind one Service, fronted by an Ingress. Then:

- The **scheduler** places those 3 Pods on whichever nodes have room.
- A **Service** gives them one stable DNS name; traffic is balanced across the
  healthy ones automatically.
- A **HorizontalPodAutoscaler** watches CPU and raises the replica count during
  the sale, then lowers it after.
- A node dies. Its Pods are noticed missing and recreated on surviving nodes.
  The Service drops the dead backends from rotation. Nobody's phone rings.
- The sale ends; capacity shrinks back on its own.

Nothing in that list is a command you run at the time. It is all consequence of
declared state plus loops that never stop running.

---

## 6. High-level architecture

A Kubernetes **cluster** is a set of machines (**nodes**) presented as one pool
of compute. Nodes have two roles.

```text
                        kubectl / CI / Argo CD
                                  |
                                  | (HTTPS, authenticated + authorized)
                                  v
+--------------------------------------------------------------------+
|                          CONTROL PLANE                              |
|                        "decides what should happen"                 |
|                                                                     |
|   kube-apiserver  <---->  etcd                                      |
|        ^                  (the only database; cluster state)        |
|        |                                                            |
|        +---- kube-scheduler          (which node should host this?) |
|        +---- kube-controller-manager (reconciliation loops)         |
|        +---- cloud-controller-manager (cloud integration, optional) |
+--------------------------------------------------------------------+
                                  |
              +-------------------+-------------------+
              |                   |                   |
              v                   v                   v
        +-----------+       +-----------+       +-----------+
        |  NODE 1   |       |  NODE 2   |       |  NODE 3   |
        |           |       |           |       |           |
        | kubelet   |       | kubelet   |       | kubelet   |
        | kube-proxy|       | kube-proxy|       | kube-proxy|
        | runtime   |       | runtime   |       | runtime   |
        |           |       |           |       |           |
        | [Pod][Pod]|       | [Pod]     |       | [Pod][Pod]|
        +-----------+       +-----------+       +-----------+
                      "does what it is told"
```

### Control plane components

| Component | Responsibility | Remember it as |
|---|---|---|
| **kube-apiserver** | The only front door. Every read and write goes through it — authentication, authorization, admission, validation | The receptionist. Nothing gets past it |
| **etcd** | Distributed key-value store. The *entire* cluster state. Lose it and you lose the cluster | The filing cabinet. **Only the API server is allowed to open it** |
| **kube-scheduler** | Watches for Pods with no node assigned; picks one based on resources, taints, affinity | The seating host. Only *assigns*; does not start anything |
| **kube-controller-manager** | Runs the reconciliation loops — Deployment, ReplicaSet, Node, Job, and many more | The floor managers. One loop per concern |
| **cloud-controller-manager** | Cloud-specific integration: load balancers, volumes, node lifecycle | The liaison to AWS/Azure/GCP. Absent locally |

### Node components

| Component | Responsibility | Remember it as |
|---|---|---|
| **kubelet** | The agent on every node. Takes Pod specs assigned to its node and makes the runtime actually run them. Reports status back | The site supervisor. Talks to the API server, never to etcd |
| **kube-proxy** | Implements Service networking on the node via iptables or IPVS rules | The traffic router |
| **Container runtime** | Actually runs containers — containerd or CRI-O, via the CRI | The engine. This is Docker's job, done by its successor |

### The detail that surprises most people

**Nothing talks directly to anything else.** The scheduler does not tell the
kubelet to start a Pod. It writes `nodeName` onto the Pod object via the API
server. The kubelet on that node is *watching* the API server, sees a Pod now
assigned to it, and acts.

Every component watches the API server and reacts. It is a hub-and-spoke design,
not a chain of commands.

This is why "which component is responsible?" is always answerable, and it is
why troubleshooting is systematic rather than guesswork.

---

## 7. What happens when you run `kubectl apply -f deployment.yaml`

Trace it once now; you will re-derive it in Module 19 with much more depth.

```text
 1. kubectl reads the YAML, converts to JSON, POSTs to kube-apiserver
        |
 2. API server: AUTHENTICATION    -- who are you?
        |
 3. API server: AUTHORIZATION     -- RBAC: may you do this?
        |
 4. API server: ADMISSION         -- mutate (add defaults) then validate
        |
 5. API server writes the Deployment object to etcd
        |
 6. kubectl prints "deployment.apps/nginx created"   <-- YOUR COMMAND ENDS HERE
        |
 7. Deployment controller (watching) sees a new Deployment, creates a ReplicaSet
        |
 8. ReplicaSet controller sees a ReplicaSet wanting 3 Pods, 0 exist -> creates 3 Pod objects
        |
 9. Those Pods have no nodeName. They are PENDING
        |
10. Scheduler sees unscheduled Pods, filters and scores nodes, writes nodeName
        |
11. kubelet on each chosen node sees a Pod assigned to it
        |
12. kubelet asks the container runtime (via CRI) to pull images and start containers
        |
13. kubelet reports status back to the API server
        |
14. Pod becomes RUNNING
```

**Step 6 is the one to internalise.** `created` means *the API server accepted
and stored the object*. It says nothing about whether anything is running,
scheduled, pullable, or healthy. Steps 7-14 happen afterwards, asynchronously,
and any of them can fail.

This is the Kubernetes version of a lesson already learned in Docker — *a
hardcoded log string is not proof of runtime state*. Here: **an `apply` success
message is not proof of a running application.** Confirming that requires
`kubectl get`, `kubectl describe`, and `kubectl get events`.

---

## 8. Core terminology

Enough to read any Kubernetes document. Each gets a full module later.

| Term | Meaning | Closest Docker analogue |
|---|---|---|
| **Cluster** | The whole system: control plane + nodes | A Compose project, scaled to many hosts |
| **Node** | One machine, physical or virtual | The Docker host |
| **Pod** | **Smallest deployable unit.** One or more containers that share a network namespace and storage volumes | A container — but see below |
| **ReplicaSet** | Keeps N identical Pods running | `deploy: replicas:` with a supervisor |
| **Deployment** | Manages ReplicaSets to give rolling updates and rollback | No equivalent |
| **Service** | Stable name, IP, and load balancing in front of a changing set of Pods | Compose's embedded DNS, but durable |
| **Ingress** | HTTP/HTTPS routing from outside into Services | An nginx reverse proxy you'd run yourself |
| **Namespace** | A virtual partition of the cluster for isolation and quota | Compose project scoping |
| **Label** | Key/value tag on an object | Docker labels |
| **Selector** | A query over labels — how objects find each other | No real equivalent |
| **ConfigMap** | Non-secret configuration, injected as env vars or files | `--env-file` |
| **Secret** | Same, for sensitive data. **Base64-encoded, not encrypted by default** | Docker secrets |
| **Volume / PV / PVC** | Storage decoupled from the Pod's lifetime | Named volumes |
| **Manifest** | The YAML describing a desired object | A Compose file |
| **Controller** | A loop reconciling desired vs current state for one kind of object | `restart: always`, generalised |

### The Pod is not a container — and the reason is one you already proved

A Pod is a group of containers that share a **network namespace** and can share
**volumes**. Containers in one Pod reach each other on `localhost` and share one
IP address.

During the Docker phase you verified: *localhost inside a container never means a
sibling container — every container has its own private loopback.*

That is exactly right for Docker, and it is exactly what a Pod deliberately
changes. A Pod is the unit that says *these containers are one deployable thing,
so they may share a loopback*. That is what makes the sidecar pattern possible.

**Why the extra layer exists:** most Pods hold one container. The abstraction
earns its cost for the minority that need a tightly-coupled helper — a log
shipper, a proxy, a credential refresher — that must be scheduled on the same
node, live and die together, and share the network.

---

## 9. Common misconceptions

| Misconception | Reality |
|---|---|
| "Kubernetes replaced Docker" | Kubernetes stopped using Docker Engine as a *node runtime* in 1.24. Docker-built OCI images run everywhere, unchanged |
| "A Pod is just a container" | A Pod is a shared network+storage context for one *or more* containers |
| "kubectl apply succeeded, so it's running" | It means the API server stored the object. Nothing more |
| "Kubernetes gives high availability automatically" | It gives the *mechanisms*. A single-replica Deployment with no probes and no resource requests is not highly available |
| "Secrets are encrypted" | Base64-encoded by default. Encryption at rest is configuration you must enable |
| "The scheduler starts Pods" | It only writes `nodeName`. The kubelet starts them |
| "I deleted the Pod, it's gone" | If a controller owns it, a replacement appears. Delete the *owner* |
| "Kubernetes is always the right answer" | For one app on one host that tolerates a restart, Compose is correct and Kubernetes is overhead |

---

## 10. Production considerations

Noted now, revisited properly in Module 22.

- **etcd is the cluster.** Back it up. Losing etcd without a backup loses
  everything except what you have in Git.
- **The control plane is a single point of failure until it isn't.** Production
  runs 3 or 5 control-plane nodes; etcd needs an odd number for quorum.
- **Managed control planes (EKS/AKS/GKE) exist because of the two points above.**
  The cloud provider runs and backs up etcd for you.
- **Declared state belongs in Git, not just in the cluster.** A cluster
  reconstructed from Git is a recovery. A cluster reconstructed from memory is an
  outage. This is the reasoning that leads to GitOps in Module 26.

---

## 11. Knowledge check

Answer from understanding, not by searching. Answers are not written here.

1. What is a reconciliation loop, and why does it make Kubernetes declarative
   rather than imperative?
2. You run `kubectl delete pod web-abc123` and a new Pod appears seconds later.
   Which component created it, and why?
3. Why can two containers in the same Pod reach each other on `localhost` when
   two Docker containers on the same host cannot?
4. `kubectl apply` prints `created`. Name three things that could still go wrong
   afterwards, and the component responsible for each.
5. Which component actually starts a container: the scheduler, the kubelet, or
   the controller manager? What do the other two do instead?
6. Why is it accurate to say "Kubernetes removed Docker support" and also
   accurate to say "your Docker images work fine on Kubernetes"?
7. Name a situation where choosing Kubernetes would be the *wrong* decision.

---

## 12. Mini exercise

No cluster is needed. On paper, map the Docker project `01-node-postgres`
(Node API + Postgres, Compose) onto Kubernetes objects.

For each, name the object and justify it:

| Compose concept | Kubernetes object? | Why |
|---|---|---|
| The `api` service | ? | ? |
| The `db` service | ? | ? |
| `depends_on: condition: service_healthy` | ? | ? |
| The implicit project network | ? | ? |
| The Postgres named volume | ? | ? |
| `POSTGRES_PASSWORD` env var | ? | ? |
| Published port `3000:3000` | ? | ? |

One of these has **no single clean equivalent** and is genuinely interesting to
argue about. Identifying which one, and why, is the actual point of the exercise.

---

## 13. Challenge

> The Docker phase established that `depends_on: condition: service_healthy`
> fixed a real startup race, because Postgres takes seconds to accept
> connections after its process starts.
>
> Kubernetes has **no** `depends_on`. Pods in a Deployment start in no
> guaranteed order, and the API Pod may well start before the database is
> reachable.
>
> **Is that a design flaw? If not, what is Kubernetes assuming about your
> application instead — and what does that assumption imply you must build into
> the application itself?**

There is a genuinely good answer here, and it reframes how you write every
containerised application afterwards. Attempt it before Module 13.

---

## Next

**LAB 01 — Set up the Kubernetes learning environment**
[`labs/lab-01-lab-environment-setup.md`](labs/lab-01-lab-environment-setup.md)

Then Lesson 02 — Control Plane vs Worker Node, inspected on a real cluster.
