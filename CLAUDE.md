# CLAUDE.md, working instructions for catalog

These instructions apply to any model working in this repo. Read this file
before changing anything. It holds process and invariants only: **no status.**

## Read before you change anything

1. `README.md`, and specifically the sentence about templates, not agents.
2. The policy and drill formats in the repos that consume them: `wardryx` for
   policies, `mockryx` for drills, `agent-passport` for passport templates.
   This repo does not define those formats, it uses them.

## What this is

An open catalog of governance **templates**: Wardryx policy presets, Mockryx
drill scenarios, agent-passport templates, Terraform modules. Public,
Apache-2.0.

**It ships no runtime and governs nothing itself.** It is the starting material
an operator adapts, so a fresh deployment denies something real on day one
instead of shipping empty. That distinction is the whole product and it is easy
to erode one convenience at a time.

## Hard invariants

Each one carries how it is held today. Use `(gate: ...)`, `(test: ...)`,
`(partly gated: ...)` or `(not enforced)`, and use the weakest one that is
true.

1. **No executable ships from this repo.** No binary, no daemon, no installer.
   The moment this repo runs something, it stops being a catalog and becomes an
   undocumented agent in somebody's estate. *(not enforced)*
2. **A template is a starting point, never a claim of coverage.** A policy
   preset that reads as complete invites an operator to ship it unchanged.
   Every template says what it does not cover. *(not enforced)*
3. **A template that no consumer can load is broken, however good it looks.**
   Formats are owned by `wardryx`, `mockryx` and `agent-passport`. When one
   of them changes, the fix is here, and it is not optional.
   *(not enforced)*
4. **Nothing here denies by accident.** A preset that would break a working
   deployment on first apply is a bug, even if the rule it encodes is correct.
   Say what it blocks, in the file. *(not enforced)*

## Decisions that have no gate yet

Every invariant above is held by this file alone.

**Invariant 3 is the one to automate and the cheapest here:** load every
template with its consumer's own parser in CI and fail if any of them refuses.
Right now nothing checks that these files still parse, which means this repo can
break silently when a sibling changes a format, and nobody finds out until an
operator does.

Invariant 1 is a two-line check: fail if any file in the tree is executable or
carries a shebang.

## Standing rule

An approved architecture decision is **not finished** until it is two things: a
numbered invariant in this file, and a gate in a script if it can be checked
structurally. Until then it is a document, and documents do not stop code.

## Conventions

- **No long dashes** anywhere: not in code, docs, commit messages, or PR
  bodies. Use a comma, a colon, parentheses, or a short hyphen.
- Nothing paid or metered gets enabled without telling the user first and
  getting agreement.
- Do not delete or revoke keys, tokens, or certificates on your own initiative.
