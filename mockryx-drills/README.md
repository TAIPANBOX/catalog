# Mockryx drill templates

[Mockryx](https://github.com/TAIPANBOX/mockryx) is a pre-production fire-drill harness: it sends crafted requests through a gateway you operate and checks that your guardrails respond the way you expect, before a real agent (or a prompt-injected one) ever gets the chance to. The files in this directory are starting-point scenarios, not a finished test suite - each one rehearses one guardrail failure mode (a runaway budget, a denied tool call, a leaked-looking secret) with placeholder identities and thresholds you are expected to edit.

Every file mirrors the real scenario schema Mockryx loads (`internal/scenario`): a `name`, optional `description` and `requires` (the optional gateway feature the drill depends on, e.g. `wardryx` or `dlp`), and one or more `steps`, each with a `request` (model, messages, optional tools), optional `headers` (`run_id`, `agent_id`, `budget_usd`, `on_behalf_of`, and so on), and a required `expect` (the HTTP status, and optionally response headers, a repeat deadline, or an async event).

These templates are adapted from the shapes Mockryx ships with, restructured as commented, edit-before-use starting points rather than drop-in copies of a working suite.

## How to use these

1. Copy the drills you need into your own scenario directory.
2. Replace every `YOUR-ORG.example` agent id and tune the thresholds to match your own environment and your own Wardryx/DLP/budget configuration.
3. Point Mockryx at your OWN pre-production gateway, ideally one sitting in front of a fake or echo model provider, never a live one:

   ```sh
   mockryx run --gateway http://127.0.0.1:8080 ./drills
   ```

Every drill here rehearses a defense, not an attack: it exists so you can confirm your own guardrails actually catch the thing they claim to catch, on your own schedule, against infrastructure you already own and control. These are templates, not agents, and not a hosted service - nothing runs anywhere until you point it at a gateway yourself.
