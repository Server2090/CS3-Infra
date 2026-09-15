# tofu/modules/voip/versions.tf
# Declares the provider source for this module.
#
# VERSION PINNING LIVES IN tofu/versions.tf ONLY — not here.
# This file uses >= to identify the provider without constraining
# the version. The root tofu/versions.tf does all real pinning.
# Rule: when you bump the provider version, edit tofu/versions.tf
# only. Never need to touch this file.

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.113"
      # Loose lower bound only — "I need at least 0.113".
      # The root versions.tf ~> 0.113 constraint is the effective
      # ceiling. Both constraints are satisfied simultaneously.
    }
  }
}
