# claude-agents

Personal Claude Code agents and a router skill: an adaptive **research → plan → implement** pipeline
that scales itself down to the size of the task.

The point is to keep heavy work out of the main conversation, and to hold a cheaper model to a standard
it would otherwise drift away from.

## What's in here

```
agents/researcher.md      haiku    — web + codebase research
agents/planner.md         opus     — xhigh effort, contract + wave-sequenced tasks
agents/implementer.md     sonnet   — xhigh effort, one scoped task at a time
skills/build/SKILL.md              — the router that decides which of the above to run
```

## Install

```sh
git clone git@github.com:ArtMin96/claude-agents.git ~/claude-agents
cd ~/claude-agents && ./install.sh
```

`install.sh` copies into `~/.claude/`. Pass `--link` to symlink instead, so edits in the repo take
effect immediately and `git pull` updates every agent at once.

Nothing else is required — Claude Code picks up `~/.claude/agents/*.md` and `~/.claude/skills/*/SKILL.md`
on the next session.

## How it works

`/build` classifies the request and runs **only the stages that are needed**:

| Route | When |
|---|---|
| Direct | one-line fix, typo, rename — no agents at all |
| Implement | scoped, understood, you know which files change |
| Plan → Implement | multiple files, new component, shared types, refactor |
| Research → Plan → Implement | involves a technique or library with no precedent in the repo |
| Research only | a question or comparison — knowledge, not a diff |
| Plan only | design and scope it, don't build it yet |

Explicit instructions override the heuristics: *"just fix X"* skips all ceremony, *"research this
properly"* forces the full pipeline.

### Parallel implementation without collisions

The planner emits tasks grouped into **waves**, each task owning an **exclusive write set**.

- Shared structure — types, interfaces, schemas — is settled **alone in Wave 1**.
- Leaf tasks then fan out in parallel, with **disjoint write sets** verified against a collision table
  before anything is dispatched.
- Dependent tasks get the settled signatures **pasted into the task text**, so a parallel agent never has
  to read a file another agent owns.

That last point is the design: stale knowledge is avoided by *sequencing*, not by coordination.

### Keeping a cheap model in line

`implementer` runs on Sonnet, which reliably drifts away from standards mid-run. Four mechanisms:

- **Preloaded skills** — `skills:` injects full skill content at startup, not just descriptions.
- **One task per run**, capped by `maxTurns` — less mid-work in which to drift.
- **A printed self-review table** against every standard, produced after re-reading its own diff.
- **A motivated write-set rule** — it explains that editing outside your set silently destroys another
  live agent's work, rather than just forbidding it.

Testing suggests motivated and *visible* constraints hold where decorative ones don't: rules producing an
inspectable artifact survived, rules whose compliance couldn't be seen were quietly dropped.

## Optional: the enforcement hook

The strongest anti-drift mechanism isn't included by default because it fires on **every** edit. Add it
to `agents/implementer.md` frontmatter if drift persists:

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            echo '{"additionalContext":"STANDARDS: single source of truth; no magic strings/numbers; no duplication; match surrounding architecture; tests assert behavior and proven to fail; stay inside your write set."}'
```

Unlike the other mechanisms this doesn't depend on the model's cooperation — the harness re-injects the
standards whether Sonnet wants them or not. Untested.

## Status

`researcher` has been exercised across external, internal, and hybrid routing, with citations verified
against sources. Findings: routing was correct in every run and code citations were accurate, but
**statistics from web research are worth spot-checking** — one fabricated figure recurred across runs
before the quote rules were tightened.

`planner`, `implementer`, and the `/build` router are **not yet tested**.

## Requirements

Claude Code with support for the `effort`, `skills`, and `maxTurns` subagent frontmatter fields.
