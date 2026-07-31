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

## Gates

```sh
./scripts/templates-load.sh
./scripts/no-executables.sh
```

`templates-load.sh` needs the sibling repos checked out beside this one, and
Go, Terraform and `python3`. It fails rather than skipping when one is absent:
a skipped check reports silence as health. There is no CI in this repo, so
these are local gates.

## Running the gates

```sh
git config core.hooksPath .githooks   # once, per clone
```

There is no CI in this repository, so `.githooks/pre-push` is the ONLY thing
that runs the gates above. Without that one line they are scripts nobody calls,
which is a comment with an exit code. `git push --no-verify` skips them, and
should be rare enough to be worth explaining.

## Hard invariants

Each one carries how it is held today. Use `(gate: ...)`, `(test: ...)`,
`(partly gated: ...)` or `(not enforced)`, and use the weakest one that is
true.

1. **No executable ships from this repo.** No binary, no daemon, no installer.
   The moment this repo runs something, it stops being a catalog and becomes an
   undocumented agent in somebody's estate. `scripts/` is exempt: those are this
   repo's own gates and ship with nothing.
   *(gate: `scripts/no-executables.sh`)*
2. **A template is a starting point, never a claim of coverage.** A policy
   preset that reads as complete invites an operator to ship it unchanged.
   Every template says what it does not cover. *(not enforced)*
3. **A template that no consumer can load is broken, however good it looks.**
   Formats are owned by `wardryx`, `mockryx` and `agent-passport`. When one
   of them changes, the fix is here, and it is not optional.
   *(gate: `scripts/templates-load.sh`)*
4. **Nothing here denies by accident.** A preset that would break a working
   deployment on first apply is a bug, even if the rule it encodes is correct.
   Say what it blocks, in the file. *(not enforced)*

## Decisions that have no gate yet

**Held by this file alone: invariants 2 and 4.** Both are about what a template
CLAIMS rather than what it is, and no script reads that. A preset that reads as
complete, or one that would break a working deployment on first apply, is
caught by a reader or not at all.

Invariant 3 is `scripts/templates-load.sh`, and the important part is what it
does not do: it validates nothing against a schema we wrote. It loads each
template **with its consumer's own code**. Policies and passports go through
`wardryx check`, drills through `mockryx run` pointed at a dead loopback port
(exit 2 means it could not parse, exit 1 means it parsed and could not reach
the gateway, which is the expected result), passports again through the
agent-passport repo's own schema, and modules through `terraform fmt`.

**Writing it found a defect in a consumer rather than in a template.** The
deliberate break for the policy path, a policy carrying an unknown field,
passed. Wardryx was decoding without strict field checking, so a policy written
with `deny_tools` instead of `deny_tool` loaded, matched its agents and denied
nothing while reporting "allowed: request satisfies all matched policy rules".
Fixed in wardryx; the gate catches it now. That is the argument for delegating
to the consumer's parser in one paragraph: a check written here against our own
reading of the format would have agreed with our own assumptions.

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
