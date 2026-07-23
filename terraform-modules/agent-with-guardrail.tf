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
# A KNOWN GAP WORTH KNOWING ABOUT
# The Genaryx onboard wizard's generated Terraform snippet
# (genaryx/crates/api/src/onboard/commands.rs) emits filesystem {} and
# models {} blocks inside taipan_agent_passport, mirroring the newer
# filesystem/models fields the Agent Passport JSON schema itself now
# supports (agent-passport SPEC.md Sec 4.4-4.5). As of this catalog's
# writing, terraform-provider-taipan's actual taipan_agent_passport
# resource schema does NOT yet define those two attributes - only id,
# owner, display_name, runtime, parent, attestation_method,
# attestation_detail, labels, and output_path exist on the resource. If you
# need filesystem/models declared, put them directly on a hand-written
# passport JSON (see passport-templates/ in this catalog) for now, rather
# than in this Terraform resource; `terraform validate`/`apply` would
# reject a filesystem {} or models {} block here until the provider catches
# up (this file deliberately omits them so it applies cleanly today).

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
