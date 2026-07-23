# Wardryx policy templates

[Wardryx](https://github.com/TAIPANBOX/wardryx) is a policy decision point (PDP): given a proposed action from one of your own agents, it decides `allow`, `deny`, or `hold`. The files in this directory are starting-point policy documents for it, not a finished security posture - each one covers one common shape of guardrail (a finance desk, an HR team, a support bot, a data pipeline, an org-wide floor) with realistic-but-placeholder values you are expected to edit before you rely on them.

Every file mirrors the real `Policy` struct Wardryx loads (`internal/policy`): `name`, `target` (an `agent://` glob), `deny_tool`, `allow_domains`, `require_human_above_usd`, `deny_above_usd`, `max_steps`, and `deny_if_unattested`. A policy file may hold one document or a YAML/JSON list of several; `global-baseline.yaml` demonstrates the list form.

## How to use these

1. Copy the templates you need into your own policy directory.
2. Replace every `YOUR-ORG.example` trust domain and placeholder path segment with your real `agent://` naming.
3. Tune the thresholds (`require_human_above_usd`, `deny_above_usd`, `max_steps`) and tool/domain lists to your own risk tolerance.
4. Point Wardryx at the directory:

   ```sh
   wardryx serve -policy ./policies
   ```

   Wardryx loads every `*.yaml`, `*.yml`, and `*.json` file directly under that directory (non-recursive) at startup. A malformed file is a hard error by design - Wardryx refuses to start with a smaller rule set than you intended rather than silently dropping a broken file.

These are templates, not agents, and not a hosted service: nothing here runs anywhere until you load it into a Wardryx instance you operate. They exist to help you govern your own agents faster, starting from a sane shape instead of a blank file.
