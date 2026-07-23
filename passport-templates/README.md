# Agent Passport templates

An [Agent Passport](https://github.com/TAIPANBOX/agent-passport) is a small JSON document naming one agent: its `agent://` identifier, its owner, and optionally its runtime, its static provisioning parent, its attestation posture, and (new in this spec) the filesystem paths and LLM providers/models it is meant to use. It is metadata that Idryx and Qryx read, not a token and not something anything authenticates against - the Passport names an agent, it does not prove possession.

The three files here are starting points for the three most common agent runtimes, each showing a slightly different, all-still-valid shape (with vs. without a `parent`, different `attestation.method` values, a fully pinned vs. provider-only `models` entry) so you can see what is required and what is optional. Every placeholder value needs your own input before the document describes a real agent - each file marks itself clearly, including small `"//"` comment keys (JSON has no native comment syntax, so this catalog uses the common `"//"` string-key convention) that you should remove once you have filled in the real values.

**`filesystem` and `models` are declarations of intent, not enforced controls.** Writing `{"path": "/data/reports", "mode": "read"}` or `{"provider": "anthropic", "model": "claude-sonnet-4-5"}` on a passport does not grant, mount, or restrict anything by itself - no product in the stack enforces these fields today (Wardryx's own policy surface, for comparison, is tools/domains/spend/steps/attestation, with no path or model rule). They exist so an owner can put on record what an agent is *meant* to touch, so an auditor can later compare that declaration against what the agent's code actually imports and calls, and what it is observed reaching on the network. A mismatch between declared, coded, and observed is the finding this kind of inventory exists to surface.

## How to use these

1. Copy the template matching your agent's runtime (or the closest one - the shape is the same regardless of runtime).
2. Fill in `id` (your real `agent://` identifier - lowercase trust domain and path, see the spec), `owner`, and whichever optional fields apply.
3. Remove the `"//"` comment keys once you're done editing.
4. Validate it against the published schema before committing it, e.g.:

   ```sh
   python3 -m json.tool your-passport.json > /dev/null   # syntax check
   # schema check: see github.com/TAIPANBOX/agent-passport/schemas/agent-passport.schema.json
   ```

5. Store it wherever your org keeps this kind of config (a git repo, a config service) - nothing at runtime needs to fetch it. Idryx and Qryx consume it read-only.

These are templates, not agents: this catalog does not run, host, or take responsibility for any agent described by a document you build from one of these files. It only helps you write a correct one faster.
