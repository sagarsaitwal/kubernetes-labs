# Daily Entry Template

Author: Sagar Saitwal

Copy this to `journal/daily/day-NN-topic.md` at the start of each
learning day. Delete this header block, keep everything below the line.

Sections that do not apply get `None` or `Not applicable today` — **not
deletion**. A consistent shape is what makes entries comparable months later,
and an empty "What I Broke" section is itself information.

---

```markdown
# Day NN — <Topic>

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | YYYY-MM-DD |
| **Day** | NN |
| **Module** | NN — <Module name> |
| **Topic** | <What this day covered> |
| **Status** | COMPLETED / PARTIALLY COMPLETED / BLOCKED |
| **Cluster** | <cluster name, node count, k8s version> |

---

## Today's Objective

What this session set out to do.

## Module

## Section

## Topic

## Subtopic

---

## Theory Learned

The concept, in my own words. Not copied from documentation.

## Why It Matters

The practical reason this exists. What breaks without it.

---

## Commands Used

For every important command:

### `<command>`

- **What it does:**
- **Important options:**
- **Why I used it:**
- **Expected output:**
- **Actual output:**

---

## YAML / Configuration

The manifests written today, with the reasoning behind non-obvious fields.

---

## Lab Performed

Exactly what was done, in order.

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | |
| Node count | |
| OS | |
| Container runtime | |
| CNI | |
| Cluster type | |

---

## Expected Result

## Actual Result

## What Worked

## What Failed

---

## What I Broke

**Do not hide mistakes.** Record the actual failure.

Examples of the right level of detail:
- Created wrong selector — Service had no endpoints
- Pod stayed Pending — no node had enough allocatable memory
- Wrong containerPort — Service reachable but connection refused

## Error Message

The real output, copied exactly.

```text

```

## Investigation

How the problem was diagnosed, in the order the commands were actually run.

```bash
kubectl get <object>
kubectl describe <object>
kubectl logs <pod>
kubectl get events --sort-by=.lastTimestamp
```

What each output revealed, and what it ruled out.

## Root Cause

The actual reason — proven, not suspected.

## Solution

Exactly how it was fixed.

## Verification

How the fix was confirmed. A fix that was not verified is not a fix.

---

## Mistake

What did I misunderstand? What did I believe before that turned out wrong?

## Lesson Learned

What should I remember next time?

## Troubleshooting Knowledge

Turn the specific problem into a reusable rule.

```text
SYMPTOM -> CHECK -> COMMAND -> INTERPRETATION -> ROOT CAUSE -> FIX -> PREVENTION
```

If this is a new failure mode, also add it to
`journal/mistakes-and-lessons.md` and the relevant `troubleshooting/` folder.

---

## Interview Questions

Questions this topic would realistically be asked about.

## Challenge

The exercise set for this topic, and whether it was attempted.

---

## End-of-Day Status

| Item | State |
|---|---|
| | |

## Next Session

Next journal file: `journal/daily/day-NN-<topic>.md`

1.
2.
3.
```

---

## End-of-session checklist

After writing the daily entry, update:

| File | Update |
|---|---|
| `progress/current-progress.md` | Overwrite with the new resume point |
| `progress/completed-topics.md` | Append **only** if theory + lab + verification + exercise all happened |
| `progress/next-steps.md` | Re-queue what is next |
| `journal/learning-journal.md` | Add one row to the index table |
| `journal/mistakes-and-lessons.md` | Add an entry **only** if something broke |
| `README.md` | Update the module progress table and the daily journal table |
