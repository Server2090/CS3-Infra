# tofu/terraform.tfvars
# Non-secret variable values for cs3-infra tofu.
# This file is committed to git in plaintext.
# Anything sensitive goes in secrets.sops.yaml instead.
#
# OpenTofu automatically reads this file on every plan/apply.
# You never need to pass -var-file=terraform.tfvars manually.

# ── Proxmox connection ────────────────────────────────────────────
proxmox_endpoint = "https://192.168.80.30:8006/"
# Points at pve — the CS3 R440.
# 8006 is the Proxmox API port — always HTTPS, never HTTP.
# The trailing slash is required by the bpg/proxmox provider.

# ── Proxmox placement ─────────────────────────────────────────────
proxmox_node        = "pve"
proxmox_vm_storage  = "vmdata"
proxmox_iso_storage = "local"
# These match the defaults in variables.tf but are explicit here
# so the values are visible without having to open variables.tf.
# Explicit is always easier to debug than implicit defaults.
