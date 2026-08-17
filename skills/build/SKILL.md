---
name: build
description: Adaptive research → plan → implement pipeline that scales itself to the task. Use when the user asks to build, add, implement, fix, refactor, or design something and the work is worth delegating. Classifies intent first and runs only the stages that are actually needed — trivial edits are done directly, well-understood changes go straight to implementation, and only genuinely novel or multi-file work gets the full pipeline. Fans implementation out across parallel agents with disjoint file ownership.
---

# Build

An adaptive pipeline over three agents: `researcher` (haiku), `planner` (opus/xhigh), `implementer`
(sonnet/xhigh). The point is **running the smallest pipeline that does the job**, and keeping the heavy
work out of the main context.

**Ceremony is a cost, not a virtue.** A four-agent pipeline for a typo is a worse outcome than doing it
yourself. So is a blind edit to a subsystem you have not understood. Classify honestly.

---

## 1. Classify the request

Read what the user actually asked for. Pick the smallest route that fits.

| Route | When | Stages |
|---|---|---|
| **Direct** | One-line fix, typo, rename, a single obvious edit in a file you already understand | none — just do it |
| **Implement** | Scoped and well understood; no unknowns; you know exactly which files change | `implementer` |
| **Plan → Implement** | Multiple files, a new component, shared types/interfaces, refactor, or anything parallelizable | `planner` → `implementer`(s) |
| **Research → Plan → Implement** | Involves a technique, library, protocol, or pattern not already established in this repo | `researcher` → `planner` → `implementer`(s) |
| **Research only** | A question, a comparison, groundwork — the user wants knowledge, not a diff | `researcher` |
| **Plan only** | The user asked to design, scope, or think it through — not to build it yet | `planner` |

**Signals that research is needed:** an unfamiliar library or protocol; "how should we", "what's the best
way", "compare"; a technique with no precedent in this repo; anything where guessing an API would be
costly.
**Signals that planning is needed:** more than ~2 files; a shared type, interface, or schema changes; a
new module or component; the change has a real chance of being designed wrong; the work could be split
across parallel agents.
**Signals to skip straight to implementing:** the user described exactly what to change; a single file; a
pattern already used elsewhere in the repo that you can copy.

**The user's words win.** "Just fix X" means no ceremony. "Research and plan this properly" means the
full pipeline even if it looks small. "Don't overthink it" means Direct or Implement.

Say which route you picked in one short line, then go. Do not ask permission for a routine call — only
stop if two routes would produce materially different work and you genuinely cannot tell which is wanted.

---

## 2. Dispatch rules

**Give every agent what it needs, because it cannot see this conversation.** Include the concrete goal,
the relevant constraints from the user's actual words, and any decisions already made. An agent working
from a vague forwarded prompt produces vague work.

**No agent writes files unless the user asked for a file.** State this in the prompt: the report is the
deliverable. This applies to research briefs and plans alike.

**Keep the main context small.** Do not paste agent reports back verbatim. Relay the conclusion, the
decisions, and anything the user must act on. The full report stays in the agent's context where it
belongs.

---

## 3. Running the implementation waves

The planner returns tasks grouped into **waves**, each task carrying an **exclusive write set**.

1. **Verify the plan before dispatching.** Check the collision table: no file may appear in two tasks in
   the same wave. If it does, the plan is broken — send it back to the planner rather than dispatching
   agents that will corrupt each other.
2. **Dispatch a whole wave in a single message**, one `implementer` per task, so they run concurrently.
3. **Each implementer prompt must contain:** the task goal, its exclusive write set (spelled out as
   explicit paths), its read set, the settled contract it depends on (pasted in full — never tell it to
   go look at another task's files), and its verification command.
4. **Wait for the whole wave.** Do not start the next wave until every task in the current one reports.
5. **Between waves, check the reports.** If a task came back BLOCKED or PARTIAL, decide before continuing:
   fix it, re-plan, or surface it to the user. Do not run the next wave over a broken foundation.
6. **Wave 1 is usually a single task** — shared structure gets settled alone. That is correct, not a
   missed parallelization opportunity.

**Never dispatch two agents that can write the same file.** If in doubt, sequence them. Lost work from a
collision costs far more than the wall-clock you save.

---

## 4. After the waves

- Run the project's gates once at the end — lint, typecheck, full test suite — rather than after every
  task. Individual agents verify their own work; the final gate catches integration.
- Report to the user: what was built, what was verified with real output, anything left BLOCKED, and the
  "noticed but not touched" items the implementers surfaced.
- **Do not commit** unless the user asks.

---

## 5. Judgment

- **Downgrade freely.** If the planner says "no plan needed", believe it and go straight to implementing.
  If research comes back saying the answer was already in the repo, skip the planner.
- **One task is fine.** If honest partitioning yields a single task, run one implementer. Parallelism is
  a means, not a goal.
- **Escalate when it matters.** If a plan surfaces a real design decision — one where different choices
  lead to materially different systems — put it to the user before implementing, rather than letting an
  agent pick.
- **Stop on a bad foundation.** A wrong plan implemented in parallel is the most expensive failure this
  pipeline can produce. Spending one more planner run beats fanning out over a broken design.
