# tofu/variables.tf
# Declares all input variables for cs3-infra tofu.
# This file only declares variables — it never assigns values.
# Values come from two places:
#   terraform.tfvars  — non-secret values, committed to git
#   secrets.sops.yaml — encrypted secrets, never committed

# ── Proxmox connection ────────────────────────────────────────────

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL. Format: https://<ip>:8006/"
  type        = string
  # type = string enforces that this must be a text value.
  # OpenTofu errors immediately if the wrong type is passed.
}

# ── Proxmox placement ─────────────────────────────────────────────

variable "proxmox_node" {
  description = "Proxmox node name to deploy VMs on. Must match the node name shown in the Proxmox web UI exactly."
  type        = string
  default     = "pve"
  # default = pve — matches the hostname set during install.
  # If not set in terraform.tfvars this value is used.
}

variable "proxmox_vm_storage" {
  description = "Proxmox storage pool name for VM disks. Must match the storage name in Proxmox web UI under Datacenter > Storage."
  type        = string
  default     = "vmdata"
  # vmdata = the ZFS stripe pool created by the proxmox_cs3pve role.
  # Matches proxmox_zfs_storage in group_vars/proxmox.yml.
}

variable "proxmox_iso_storage" {
  description = "Proxmox local storage name where ISOs are kept."
  type        = string
  default     = "local"
  # local = Proxmox built-in storage at /var/lib/vz/
  # ISOs live at /var/lib/vz/template/iso/
}
