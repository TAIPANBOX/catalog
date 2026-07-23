# Terraform templates for the taipan provider

[terraform-provider-taipan](https://github.com/TAIPANBOX/terraform-provider-taipan) manages agent identity and Wardryx policy as code: `taipan_agent_passport` renders and validates an Agent Passport document, `taipan_wardryx_policy` pushes a guardrail live to a Wardryx instance via its policy-as-code API. The files here are a starting-point pair, not a published, versioned module - copy them into your own configuration and fill in the variables.

`agent-with-guardrail.tf` declares one agent's passport and its matching Wardryx policy together, since in practice you almost always want both for a new agent at once. `variables.tf` holds the inputs it needs (`trust_domain`, `agent_path`, `owner`, attestation fields, optional `filesystem`/`models` declarations, guardrail thresholds, and the provider connection). The resource attribute names mirror the provider's real schema, not a guess - see each file's own comments for where that was checked. The optional `filesystem`/`models` blocks that Genaryx's onboard wizard emits for a passport are supported here too, added to the provider in PR #1 (2026-07-23) and rendered to the passport document's root-level `filesystem`/`models` arrays; they are declarations of intent for audit and inventory (agent-passport SPEC.md 4.4-4.5), not controls enforced at runtime.

## How to use these

1. Copy both files into your Terraform configuration.
2. Fill in `variables.tf`'s values - a `terraform.tfvars` file (gitignored, or injected by your CI) is the usual place for the real ones, especially `wardryx_admin_key`.
3. The `TAIPANBOX/taipan` provider is published to the [Terraform Registry](https://registry.terraform.io/providers/TAIPANBOX/taipan) (v0.1.0), so a plain `terraform init` resolves it. Declare it in a `required_providers` block (`source = "TAIPANBOX/taipan"`, e.g. `version = "~> 0.1"`), run `terraform init`, then `terraform plan`; review the plan before `terraform apply`. For provider development, a from-source `dev_overrides` block in `~/.terraformrc` (see the provider's [Install](https://github.com/TAIPANBOX/terraform-provider-taipan#install) section) bypasses `terraform init` and version resolution entirely.
4. `taipan_wardryx_policy` needs an admin-role Wardryx key; `taipan_agent_passport` calls no API at all and works even with no Wardryx configured.

This catalog does not run, host, or manage any Terraform state on your behalf - these files only help you write a correct configuration faster, against infrastructure you provision and operate yourself.
