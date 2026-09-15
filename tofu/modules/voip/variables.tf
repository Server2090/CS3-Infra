# tofu/modules/voip/variables.tf
# Declares every input variable for the VoIP VM module.
# Values are passed in from tofu/main.tf which reads them from
# locals.tf and terraform.tfvars — nothing is hardcoded here.
#
# Two categories of variables:
#   1. Placement/hardware — passed from locals (shared defaults)
#   2. VM identity       — specific to this VM (IP, size, name)

# ── Proxmox placement ─────────────────────────────────────────────

variable "node" {
  description = "Proxmox node name to deploy the VM on. Must match the node name in the Proxmox web UI exactly."
  type        = string
}

variable "vm_storage" {
  description = "Proxmox storage pool for the VM root disk. Must match a storage name under Datacenter > Storage."
  type        = string
}

variable "iso_storage" {
  description = "Proxmox local storage where the downloaded cloud image is kept. Typically 'local'."
  type        = string
}

# ── VM hardware defaults ───────────────────────────────────────────
# These are passed in from locals.tf so every VM in the project
# uses the same baseline. Override per-VM only when necessary.

variable "cpu_type" {
  description = "QEMU CPU model. kvm64 is the safe generic baseline for all guests."
  type        = string
  default     = "kvm64"
}

variable "machine_type" {
  description = "QEMU machine type. q35 is required for UEFI and PCIe support."
  type        = string
  default     = "q35"
}

variable "bios" {
  description = "Firmware type. ovmf = UEFI. Always pair with q35 machine type."
  type        = string
  default     = "ovmf"
}

variable "scsihw" {
  description = "SCSI controller model. virtio-scsi-pci is the fastest option."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "discard" {
  description = "Enable TRIM passthrough from guest to ZFS. Always on for ZFS-backed disks."
  type        = string
  default     = "on"
}

variable "vga" {
  description = "VGA type. std is compatible with Proxmox noVNC console."
  type        = string
  default     = "std"
}

variable "qemu_agent" {
  description = "Enable QEMU guest agent. Required for graceful shutdown and IP reporting in Proxmox."
  type        = bool
  default     = true
}

variable "nic_model" {
  description = "NIC driver model. virtio is the paravirtualised driver — fastest, lowest CPU overhead."
  type        = string
  default     = "virtio"
}

# ── VM identity ───────────────────────────────────────────────────
# These are specific to this VM and set in terraform.tfvars.

variable "vm_id" {
  description = "Proxmox VM ID. Must be unique across all VMs on the node. Range 100-999 is conventional for VMs."
  type        = number
}

variable "vm_name" {
  description = "VM hostname. Used as the Proxmox VM name and the cloud-init hostname."
  type        = string
  default     = "voip"
}

# ── VM sizing ─────────────────────────────────────────────────────
# Asterisk is lightweight. 2 cores and 2 GB RAM handles hundreds
# of concurrent calls — this is far more than two ATAs will ever need.
# Bump vm_memory if you add call recording or transcoding later.

variable "vm_cores" {
  description = "Number of vCPU cores. 2 is sufficient for Asterisk with two ATAs."
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "RAM in MB. 2048 = 2 GB. More than enough for Asterisk with two ATAs."
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Root disk size in GB. 20 GB is generous for Asterisk, logs, and call recordings."
  type        = number
  default     = 20
}

# ── Networking ────────────────────────────────────────────────────

variable "vm_ip" {
  description = "Static IPv4 address for the VM in CIDR notation. Example: 192.168.80.10/24"
  type        = string
}

variable "vm_gateway" {
  description = "Default IPv4 gateway for the VM. Must be reachable from the management bridge."
  type        = string
}

variable "bridge" {
  description = "Proxmox bridge the VM NIC attaches to. vmbr0 = management bridge."
  type        = string
  default     = "vmbr0"
}

# ── Cloud-init credentials ────────────────────────────────────────
# The SSH public key is read from your Ansible control machine and
# injected into the VM at first boot via cloud-init.
# The private key never touches this file or git.

variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init. Paste the full contents of your ~/.ssh/cs3admin@cs3.lab.pub here."
  type        = string
  sensitive   = true
  # sensitive = true means OpenTofu will not print this value
  # in plan or apply output — it shows as (sensitive value) instead.
  # The value is still stored in state, so protect your state file.
}

variable "cloud_init_user" {
  description = "Default user created by cloud-init inside the VM. Debian 13 cloud images use 'debian'."
  type        = string
  default     = "debian"
  # Debian cloud images always create a 'debian' user — not 'admin', not 'ubuntu'.
  # This is the account Ansible will connect to after the VM boots.
}
