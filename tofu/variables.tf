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

# ── VoIP VM ───────────────────────────────────────────────────────
# One variable per configurable value for the VoIP server.
# Values are set in terraform.tfvars and passed to the voip module.
# To change the IP or VM ID later, edit terraform.tfvars only —
# never edit the module files directly.

variable "voip_vm_id" {
  description = "Proxmox VM ID for the VoIP server. Must be unique across all VMs on the node. 100 = first lab VM."
  type        = number
  default     = 100
  # Proxmox VM IDs 100–999 are the conventional range for user VMs.
  # IDs below 100 are reserved for Proxmox internal use.
}

variable "voip_vm_ip" {
  description = "Static IPv4 address for the VoIP VM in CIDR notation. The /24 tells cloud-init the subnet mask."
  type        = string
  default     = "192.168.80.10/24"
  # CIDR notation bundles the IP and subnet mask into one value.
  # 192.168.80.10/24 means IP=192.168.80.10, mask=255.255.255.0.
  # Cloud-init expects this format — do not separate them.
}

variable "voip_vm_gateway" {
  description = "Default IPv4 gateway for the VoIP VM. Must be reachable on the management bridge."
  type        = string
  default     = "192.168.80.1"
  # Matches default_gateway in ansible/inventory/group_vars/all.yml.
  # All traffic not destined for 192.168.80.0/24 goes here.
}
