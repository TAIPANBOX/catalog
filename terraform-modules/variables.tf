# variables.tf
#
# TEMPLATE - starting point, not a finished module. The variables an
# operator filling in agent-with-guardrail.tf needs to set, split out so
# they can be supplied via a terraform.tfvars file, -var flags, or your own
# CI's variable injection instead of being hardcoded in the .tf itself.
#
# Mirrors the attributes terraform-provider-taipan's taipan_agent_passport
# and taipan_wardryx_policy resources actually accept (see
# internal/provider/passport_resource.go and wardryx_policy_resource.go in
# that repo) - not every field either resource supports, just the ones this
# starter pair uses. Add more variables here if you need more of either
# resource's surface.

# --- identity: who this agent is -------------------------------------------

variable "trust_domain" {
  type        = string
  description = "CHANGE ME: your organization's agent-passport trust domain, e.g. \"acme-bank.example\". Lowercase only (agent-passport SPEC.md Sec 3.1) - the id this module builds will fail Wardryx/Idryx validation otherwise."
}

variable "agent_path" {
  type        = string
  description = "CHANGE ME: this agent's path within your trust domain, e.g. \"ops/remediation-bot\". Lowercase, segments separated by \"/\"."
}

variable "owner" {
  type        = string
  description = "CHANGE ME: the human or team principal accountable for this agent, e.g. \"team-ops@YOUR-ORG.example\". Required by the Agent Passport spec - this is the answer to an auditor's first question."
}

variable "display_name" {
  type        = string
  default     = ""
  description = "Optional human-readable name for this agent, shown in dashboards and reports."
}

variable "runtime" {
  type        = string
  default     = ""
  description = "Optional free-form label for the agent's runtime/framework, e.g. \"langgraph\", \"crewai\", \"autogen\"."
}

variable "parent" {
  type        = string
  default     = ""
  description = "Optional agent:// id of this agent's static provisioning parent (the agent that spawns it), if any. Leave blank for an agent that is not spawned by another one."
}

# --- attestation: how you bind this id to a real workload -------------------

variable "attestation_method" {
  type        = string
  default     = "none"
  description = "One of: none, oidc, spiffe-svid, enclave-key, mtls-cert. \"none\" is the honest default until you actually wire up a real workload identity - it is legal, not an error, and exists so the posture stays visible rather than silently faked."
  validation {
    condition     = contains(["none", "oidc", "spiffe-svid", "enclave-key", "mtls-cert"], var.attestation_method)
    error_message = "attestation_method must be one of: none, oidc, spiffe-svid, enclave-key, mtls-cert."
  }
}

variable "attestation_detail" {
  type        = string
  default     = ""
  description = "Method-specific reference for attestation_method, e.g. a SPIFFE ID for spiffe-svid or an issuer URL for oidc. Ignored when attestation_method is \"none\"."
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Optional free-form labels on the passport, e.g. { env = \"prod\", cost_center = \"cs-eu\" }."
}

# --- guardrail: the Wardryx policy layered on top of this agent -------------

variable "policy_target_glob" {
  type        = string
  default     = ""
  description = "The agent:// glob the Wardryx policy targets. Leave blank to default to this exact agent's id (a one-to-one guardrail); set your own broader glob, e.g. \"agent://your-org.example/ops/*\", to cover a whole team's agents with one policy instead."
}

variable "deny_tool" {
  type        = list(string)
  default     = []
  description = "CHANGE ME: tool names this agent's policy refuses outright, e.g. [\"shell_exec\", \"send_wire_transfer\"]."
}

variable "max_steps" {
  type        = number
  default     = 0
  description = "Caps a run's step count. 0 means no cap - set a real ceiling for any agent that can loop."
}

variable "require_human_above_usd" {
  type        = number
  default     = 0
  description = "Estimated-cost threshold above which Wardryx holds the action for a human to approve. 0 means no threshold."
}

variable "deny_above_usd" {
  type        = number
  default     = 0
  description = "Hard, non-approvable cost ceiling - no approval token can cross it. 0 means no hard ceiling. Set above require_human_above_usd to get an approvable band between the two."
}

variable "deny_if_unattested" {
  type        = bool
  default     = false
  description = "When true, Wardryx denies any request from this agent that carries no live attestation. Recommended true for anything privileged."
}

# --- provider connection -----------------------------------------------------

variable "wardryx_url" {
  type        = string
  default     = null
  description = "Wardryx base URL. Falls back to the WARDRYX_URL environment variable when unset - keep it out of this file's values if you commit them."
}

variable "wardryx_admin_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Admin-role Wardryx bearer key (just the key segment, not the full key:org:role triple). Falls back to WARDRYX_KEY. Required only because taipan_wardryx_policy calls the live Wardryx API; taipan_agent_passport needs no API access at all."
}
