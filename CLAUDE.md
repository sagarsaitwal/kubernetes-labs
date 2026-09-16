# CLAUDE.md — Working agreement for this repository

Author: Sagar Saitwal

This file is read automatically at the start of every session, on every machine.
It is the mechanism that makes this repository portable across devices.

---

## What this repository is

A long-term Kubernetes learning journey — **Day 00 to Day 130** — documented as a
public record of actual hands-on work, including every failure and fix.

It is **not** a notes dump. It is a training programme with a fixed structure,
defined in `Reference/`:

| File | Role |
|---|---|
| `Reference/LearningPrompt.md` | Repository structure, journaling rules, authorship, session procedures |
| `Reference/Learning Strategy.md` | 15-step teaching structure, 30-module syllabus |
| `Reference/LearningPath.md` | Linear topic ordering |
| `Reference/DockerSummary.md` | Verified Docker prerequisite baseline — what can be assumed known |

**Treat those four files as operating instructions, not documentation.**

---

## SESSION START PROCEDURE — do this first, every time

Before teaching, answering, or creating anything:

1. Read `progress/current-progress.md` — the single source of truth for where
   learning stopped. The `Current Day: NN` line gives the day number.
2. Read the most recent file in `journal/daily/`.
3. Read `progress/next-steps.md` — the queue and any open decisions.
4. Check `progress/daily-plan.md` for the scheduled topic of that day.
5. Check `progress/dependencies.md` for what that day requires.
6. Read `SystemInfo.md` (repository root) — identify this machine by
   `hostname`, and check what it already has recorded as installed versus the
   other known machine. This tells you what to *expect* before you verify it.
7. **Verify the machine.** Run, and report the result:
   ```bash
   bash /mnt/d/Kubernetes/scripts/utilities/check-dependencies.sh
   ```
   Trust this live output over `SystemInfo.md` if the two disagree — the file
   is a snapshot and can go stale. Then update `SystemInfo.md` for this
   machine so the next session (possibly on the other machine) starts
   accurate instead of guessing.

**Never restart the course from the beginning.** Never assume a session is
independent of the ones before it.

### Required format of the first response

The first response of any session must contain these four sections, in order,
before any teaching begins:

```text
1. WHERE I LEFT OFF
   Day NN, module, topic. 3-5 bullets summarising the previous session:
   what was learned, what was completed, what broke, what was unresolved.

2. MACHINE STATE
   Output of check-dependencies.sh, interpreted — not pasted raw.
   Explicitly: is this the same machine as last session, or a different one?

3. WHAT IS MISSING (if anything)
   Each missing dependency, why it is needed for this day, and the exact
   command to restore it. Always include the exact command — never describe a
   fix without also giving the copy-pasteable command for it. Distinguish
   clearly:
     - host tools      -> install once, permanent
     - cluster         -> local, never travels, recreate it
     - in-cluster      -> lost with the cluster, reinstall per cluster
     - credentials     -> configure per machine, never committed
   After resolving anything, update `SystemInfo.md` for this machine.

4. TODAY'S OBJECTIVE
   The scheduled topic for this day, and the first concrete action.
```

**If a dependency is missing, resolve it before teaching anything.** Continuing
a lab on a machine that cannot run it produces confusing errors that look like
Kubernetes problems and are not.

### Switching machines

Clusters do not travel. A different machine will legitimately report the cluster
and every in-cluster component as missing — that is expected, not a failure.
Say so plainly, then recreate what is needed.

---

## SESSION END PROCEDURE

After any meaningful session, update:

| File | Update |
|---|---|
| `journal/daily/day-NN-topic.md` | Full detail — write it from `journal/TEMPLATE-daily-entry.md` |
| `progress/current-progress.md` | Overwrite with the new resume point |
| `progress/completed-topics.md` | Append **only** if theory + lab + verification + exercise all happened |
| `progress/next-steps.md` | Re-queue what is next |
| `progress/daily-plan.md` | Update the day's status; log any plan change in the Revision log |
| `journal/learning-journal.md` | Add one row to the index |
| `journal/mistakes-and-lessons.md` | Add an entry **only** if something actually broke |
| `README.md` | Module progress table and daily journal table |

Then commit and push, so the other machine can pick it up.

---

## HARD RULES

### Authorship

- The author is **Sagar Saitwal**. Only.
- **No AI attribution anywhere** — not in commits, not in `Co-Authored-By`
  trailers, not in PR descriptions, not in Markdown, YAML comments, or metadata.
- Where an author field is required: `Author: Sagar Saitwal`

### Progress honesty

- A topic is `COMPLETED` **only** when theory was understood, the lab was run,
  verification output was actually seen, and the exercise was done.
- Otherwise: `IN PROGRESS`, or `NEEDS REVISION` if completed but gaps showed.
- Never report progress that did not happen.

### Teaching — EXPLAIN FIRST, THEN ASK

**Sagar is learning from scratch. Never hand him a decision or a question whose
answer depends on material he has not been taught.**

This is the rule that has needed correcting most often. Both corrections below
came from him directly, on 2026-09-16:

> *"How can I make decision of topology when I don't have any prior knowledge?
> I am here to learn from scratch."*

> *"I don't know the answer and can't get by just hitting the commands. You need
> to explain the context what the command does, why, where, when... understanding
> and learning is the purpose of this whole process."*

#### The distinction that matters

| Situation | Who does it |
|---|---|
| **Design decision** — topology, tooling, architecture | **Me.** Decide it. Show the options, the trade-off, the deciding factor, and the cost. State whether it is reversible. Name the module after which he can challenge the reasoning |
| **A concept not yet taught** | **Me.** Teach it properly first — then check understanding |
| **Running commands, hitting errors, diagnosing a failure** | **Him.** This is where the learning actually happens |

`Reference/Learning Strategy.md` section 27 — *"do not just give me the answer"* —
applies **only to the third row**. It governs lab execution, where he should hit
the error himself and investigate. **It is not a licence to quiz him on theory
that was never explained.** Misreading it that way turns teaching into testing.

#### Required order for every command

Before he runs anything:

1. **What it does** — plainly
2. **Why it exists / why it matters** — the problem it solves
3. **When you would reach for it** — the real use case
4. **What each flag means** — and why that flag rather than the default
5. **Which Kubernetes component is involved**
6. **What output to expect**

After output arrives: **walk through it line by line.** Name what each column,
field, and suffix means. Do not assume any part of it is self-evident.

#### Questions

Questions are for **checking understanding of something already explained**,
never for extracting an answer he has no way to know. If a question would need
knowledge from a later module, it is not a question — it is the next lesson.

#### Still true

- Deliberately break things, then let him diagnose them — *after* the mechanism
  involved has been taught.
- Symptoms first, then progressively stronger hints, only once he is engaged with
  a real failure in front of him.

### The journal

- `journal/` records **Sagar's** learning: concepts, labs, commands, what broke,
  how it was diagnosed.
- It is **not** a log of tooling problems, editor friction, or assistant errors.
  Those get fixed silently and left out.
- Never erase history. A wrong understanding stays documented next to its
  correction.

### Public repository

- No credentials, keys, tokens, certificates, account IDs, or private
  infrastructure detail. Ever.
- Placeholders only: `<YOUR_REGION>`, `<YOUR_REGISTRY>`, `<YOUR_DOMAIN>`,
  `<YOUR_AWS_ACCOUNT_ID>`, `<YOUR_SECRET>`.
- **Run a secret scan before every push.**
- A Kubernetes Secret is base64-encoded, not encrypted. A Secret manifest with
  real values is as sensitive as a plaintext password file.

---

## MULTI-DEVICE WORKING

This repository is used from more than one machine. The rule is deliberately
simple: **the repository lives at the same path on every machine.**

| | Path |
|---|---|
| Windows | `D:\Kubernetes` |
| WSL / Linux | `/mnt/d/Kubernetes` |

One folder. One copy. Edited from Windows, run from WSL, synchronised through
GitHub. There is no second lab directory and nothing is copied by hand.

### Setting up a new machine

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git /mnt/d/Kubernetes
cd /mnt/d/Kubernetes
bash scripts/utilities/setup-machine.sh
```

The clone path is not optional — matching it is what keeps every command in this
repository valid on both machines. The script then verifies prerequisites and
installs `kubectl` and `kind` if they are missing.

Per-machine environment details: `progress/environments.md`

### The repository is the shared state, not the conversation

Anything that must survive a device switch belongs in a committed file. If it
only exists in a conversation, it is lost.

### Clusters are local, not shared

A `kind` cluster exists only on the machine that created it. Switching devices
means recreating it — cheap, and precisely why `kind` was chosen:

```bash
kind create cluster --name k8s-lab \
  --config /mnt/d/Kubernetes/fundamentals/labs/kind-cluster-config.yaml
```

**Cluster state is disposable. Repository state is not.** Anything worth keeping
must be a committed manifest, not a live object.

---

## COMMANDS

```bash
# Where am I?
cat /mnt/d/Kubernetes/progress/current-progress.md

# Cluster health
kubectl get nodes -o wide
kubectl get pods -A

# Recreate the lab cluster
kind delete cluster --name k8s-lab
kind create cluster --name k8s-lab \
  --config /mnt/d/Kubernetes/fundamentals/labs/kind-cluster-config.yaml
```

## Commit style

```text
docs: add Kubernetes pod fundamentals
lab: complete first pod deployment
fix: correct service selector troubleshooting steps
project: add nginx service project
chore: pin line endings to LF
```

Describe what the commit contains, never how it was produced. No trailers.

---

## Status markers

| Marker | Meaning |
|---|---|
| NOT STARTED | Not begun |
| IN PROGRESS | Partially completed |
| COMPLETED | Theory + lab + verification + exercise all done |
| NEEDS REVISION | Completed, but knowledge gaps were demonstrated |
| BLOCKED | Cannot proceed until something is resolved |
