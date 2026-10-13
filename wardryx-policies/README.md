# Wardryx policy templates

[Wardryx](https://github.com/TAIPANBOX/wardryx) is a policy decision point (PDP): given a proposed action from one of your own agents, it decides `allow`, `deny`, or `hold`. The files in this directory are starting-point policy documents for it, not a finished security posture - each one covers one common shape of guardrail (a finance desk, an HR team, a support bot, a customer-facing shop assistant, a data pipeline, an org-wide floor) with realistic-but-placeholder values you are expected to edit before you rely on them.

Every file mirrors the real `Policy` struct Wardryx loads (`internal/policy`): `name`, `target` (an `agent://` glob), `allow_tool`, `deny_tool`, `allow_domains`, `require_human_above_usd`, `deny_above_usd`, `max_steps`, and `deny_if_unattested`. A policy file may hold one document or a YAML/JSON list of several; `global-baseline.yaml` demonstrates the list form.

`allow_tool` needs Wardryx v1.3.0 or later. Wardryx v1.2.0 refuses a file that uses it at startup, which is the safe failure. Pushed through `PUT /v1/policies`, v1.2.0 stores the policy without the list and allows the tools it would have refused, so do not send such a policy to a v1.2.0 deployment that way.

Only `support-shop-allow-list.yaml` uses `allow_tool`, and it is opt-in: it refuses every tool its list does not name, so list your real tool names before you load it. The other files in this directory are the base set and do not refuse unlisted tools.

## How to use these

1. Copy the templates you need into your own policy directory.
2. Replace every `YOUR-ORG.example` trust domain and placeholder path segment with your real `agent://` naming.
3. Tune the thresholds (`require_human_above_usd`, `deny_above_usd`, `max_steps`) and tool/domain lists to your own risk tolerance. Wardryx matches a tool name with case and surrounding spaces folded (measured against Wardryx v1.2.0), and with nothing else. Where a policy has an `allow_tool` list, a tool not on that list is refused whatever its spelling, so a respelled name needs no entry of its own. Where a policy has only `deny_tool`, a different spelling such as a hyphen in place of an underscore is allowed unless you list it too.
4. Point Wardryx at the directory:

   ```sh
   wardryx serve -policy ./policies
   ```

   Wardryx loads every `*.yaml`, `*.yml`, and `*.json` file directly under that directory (non-recursive) at startup. A malformed file is a hard error by design - Wardryx refuses to start with a smaller rule set than you intended rather than silently dropping a broken file.

These are templates, not agents, and not a hosted service: nothing here runs anywhere until you load it into a Wardryx instance you operate. They exist to help you govern your own agents faster, starting from a sane shape instead of a blank file.
