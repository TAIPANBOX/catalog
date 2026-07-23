# agent-with-guardrail.tf
#
# TEMPLATE - a starting point, not a finished module. Copy this file and
# variables.tf together, fill in your own values (a terraform.tfvars file is
# the usual place), then `terraform init && terraform plan`.
#
# WHAT THIS DECLARES
# One agent, as code, two resources:
#   1. taipan_agent_passport - renders and validates this agent's identity
#      document (schema taipanbox.dev/agent-passport/v0.1). Calls no API:
#      a passport is a static file Idryx/Qryx read from disk.
#   2. taipan_wardryx_policy  - the guardrail layered on top of it, pushed
#      live to your Wardryx instance via its policy-as-code API
#      (PUT /v1/policies/{id}). This one DOES call an API, and destroying
#      the resource actually removes the rule from Wardryx.
#
# Mirrors terraform-provider-taipan's own examples/main.tf resource shapes
# (see that repo, or wardryx-policies/ and passport-templates/ in this
# catalog for the underlying document formats each resource renders).
#
# FILESYSTEM AND MODELS: DECLARED, NOT ENFORCED
# The Genaryx onboard wizard's generated Terraform snippet
# (genaryx/crates/api/src/onboard/commands.rs) emits filesystem {} and
# models {} blocks inside taipan_agent_passport, mirroring the
# filesystem/models fields the Agent Passport JSON schema supports
# (agent-passport SPEC.md Sec 4.4-4.5). terraform-provider-taipan's
# taipan_agent_passport resource now defines both, as repeatable nested
# blocks that render to the passport document's root-level filesystem/models
# arrays (added in provider PR #1, merged 2026-07-23). This module exposes
# them through the optional var.filesystem and var.models inputs, rendered as
# the dynamic "filesystem"/"models" blocks in the resource below. Both
# default to empty: leave them unset and the rendered passport is
# byte-for-byte what it was before these blocks existed.
#
# Note what these two declare vs. what they do: filesystem/models are
# declarations of intent carried on the passport for audit and inventory, not
# controls this stack enforces at runtime - nothing grants, mounts, or
# restricts access based on them. What is actually enforced lives in the
# taipan_wardryx_policy resource below (tools, spend, steps, attestation).
# See passport-templates/README.md for the same distinction on the JSON side.

terraform {
  required_providers {
    taipan = {
      source  = "TAIPANBOX/taipan"
      version = "~> 0.1"
    }
  }
}

# Remove this block if your root module already declares the taipan
# provider elsewhere - one provider "taipan" block per configuration.
provider "taipan" {
  wardryx_url = var.wardryx_url
  wardryx_key = var.wardryx_admin_key
}

locals {
  agent_id = "agent://${var.trust_domain}/${var.agent_path}"

  # Defaults the Wardryx policy to matching this one agent exactly; set
  # policy_target_glob yourself (e.g. a "/*" prefix) to cover a whole team
  # with one shared policy instead.
  policy_target = var.policy_target_glob != "" ? var.policy_target_glob : local.agent_id

  # Wardryx addresses policies by id, not by name - derive a stable one from
  # the agent path so re-running this module against the same agent always
  # updates the same policy instead of creating a duplicate.
  policy_id = "guardrail-${replace(var.agent_path, "/", "-")}"
}

resource "taipan_agent_passport" "this" {
  id           = local.agent_id
  owner        = var.owner
  display_name = var.display_name
  runtime      = var.runtime
  parent       = var.parent

  attestation_method = var.attestation_method
  attestation_detail = var.attestation_detail

  labels = var.labels

  # Optional declared folder scopes and LLM providers/models, rendered to the
  # passport document's root-level filesystem/models arrays. Both stay out of
  # the document entirely when their variable is left at its empty default.
  dynamic "filesystem" {
    for_each = var.filesystem
    content {
      path = filesystem.value.path
      mode = filesystem.value.mode
    }
  }

  dynamic "models" {
    for_each = var.models
    content {
      provider = models.value.provider
      model    = models.value.model
      endpoint = models.value.endpoint
    }
  }

  # CHANGE ME (or remove): writes the rendered passport JSON to disk, e.g.
  # for Idryx/Qryx to read directly. Drop this attribute if you only want
  # the computed `json` output below and no managed file.
  output_path = "${path.module}/passports/${replace(var.agent_path, "/", "-")}.json"
}

resource "taipan_wardryx_policy" "this" {
  id     = local.policy_id
  target = local.policy_target

  deny_tool               = var.deny_tool
  max_steps               = var.max_steps
  require_human_above_usd = var.require_human_above_usd
  deny_above_usd          = var.deny_above_usd
  deny_if_unattested      = var.deny_if_unattested
}

output "agent_passport_json" {
  description = "The rendered, schema-validated Agent Passport document (taipanbox.dev/agent-passport/v0.1)."
  value       = taipan_agent_passport.this.json
}

output "wardryx_policy_id" {
  description = "The Wardryx policy id this module manages - use it to look the rule up via GET /v1/policies/{id}."
  value       = taipan_wardryx_policy.this.id
}
