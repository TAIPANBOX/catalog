<div align="center">

# TAIPANBOX Catalog - governance templates for the agent stack

**Copy-paste starting points for governing your own AI agents: Wardryx policies, Mockryx drills, Agent Passports, and Terraform.**

![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)
![Status](https://img.shields.io/badge/status-templates%20only-2dd4bf.svg)

</div>

---

## What this is

An open catalog of reusable **templates**, not agents: copy-paste starting points for governing an AI agent stack you already operate. Every file here is inert until you copy it, edit its placeholder values, and load it into a tool you run yourself - a Wardryx policy directory, a Mockryx scenario directory, an Agent Passport store, or a Terraform configuration.

It exists so an operator starts from a sane, commented shape instead of a blank file, and as open, discoverable content for anyone governing agents with the TAIPANBOX stack (or adapting the same shapes to their own tooling).

## What this is not

- **Not a registry.** Nothing here is indexed, versioned, or resolved by name at runtime - there is no "install template X" mechanism, no lookup service, no central index of who is using what.
- **Not a marketplace.** Nothing here is sold, rated, or ranked, and there is no submission process turning this into a storefront.
- **Not a place that hosts anyone's agents.** This repository holds configuration text: YAML, JSON, and Terraform files. It runs nothing, and stores no agent's state, credentials, or output.
- **Not responsible for anyone's prompts.** A template that denies a tool or requires human approval is a starting shape for a policy you configure and operate. This catalog takes no responsibility for what any agent governed (or left ungoverned) by a copy of these files actually does - that responsibility stays with whoever deploys and edits the policy.

Every template here is defensive by design: it exists to help an operator govern their own agents, never to probe, denylist, or act on anyone else's.

## Contents

| Directory | What it is | How you use it |
|---|---|---|
| [`wardryx-policies/`](wardryx-policies/) | Policy-as-code documents for [Wardryx](https://github.com/TAIPANBOX/wardryx), the stack's policy decision point | `wardryx serve -policy <dir>` |
| [`mockryx-drills/`](mockryx-drills/) | Fire-drill scenarios for [Mockryx](https://github.com/TAIPANBOX/mockryx), the stack's pre-production guardrail rehearsal harness | `mockryx run --gateway <url> <dir>` |
| [`passport-templates/`](passport-templates/) | [Agent Passport](https://github.com/TAIPANBOX/agent-passport) identity documents for common agent runtimes (LangGraph, CrewAI, AutoGen) | copy, fill in, validate against the published schema |
| [`terraform-modules/`](terraform-modules/) | Starting-point `.tf` files for [terraform-provider-taipan](https://github.com/TAIPANBOX/terraform-provider-taipan) | `terraform init && terraform plan` |

Every file in every directory is heavily commented in its own comment syntax, explaining what to change and why, with realistic-but-clearly-placeholder values (`agent://YOUR-ORG.example/...`, `owner: team-x@YOUR-ORG.example`, and so on). **These are starting points to adapt, not finished policy** - read the comments, replace every placeholder, and test against your own infrastructure before relying on any of it.

## License

[Apache-2.0](./LICENSE). Copyright 2026 IT-RAT.

---

Part of the open TAIPANBOX agent-governance stack: TokenFuse (spend), Wardryx (policy), Engram (memory), Idryx (access), Qryx (crypto), Verdryx (quality), Mockryx (pre-prod), on the shared Agent Passport contract, configured via terraform-provider-taipan. The stack's home on the web is [**it-rat.com**](https://it-rat.com); the code lives at [**github.com/TAIPANBOX**](https://github.com/TAIPANBOX).
