# tofu/locals.tf
# Shared computed values used across all VM modules.
# Define once here — reference everywhere.
# Never hardcode these values in individual modules.
#
# locals vs variables:
#   variables = values that come IN from outside (tfvars, env vars)
#   locals    = values computed INSIDE the config from variables
#               or constants specific to this lab

locals {

  # ── Lab identity ──────────────────────────────────────────────
  lab_domain = "cs3.lab"
  # Internal domain — matches lab_domain in ansible group_vars/all.yml.
  # Used for VM hostnames and DNS records.

  # ── Proxmox placement ─────────────────────────────────────────
  node        = var.proxmox_node
  vm_storage  = var.proxmox_vm_storage
  iso_storage = var.proxmox_iso_storage
  # Wraps input variables into local names.
  # Modules reference locals.node instead of var.proxmox_node.
  # If you rename a variable you only fix it here, not in every module.

  # ── VM defaults ───────────────────────────────────────────────
  # Shared defaults for every VM module.
  # Override per-module in main.tf when a VM needs different settings.

  default_cpu_type = "kvm64"
  # kvm64 = safe generic x86-64 CPU baseline.
  # Compatible with all guest OSes and future node additions.
  # Override to host per-module if maximum performance is needed
  # and you are certain live migration will never be required.

  default_machine_type = "q35"
  # q35 = modern Intel ICH9 chipset emulation.
  # Required for PCIe passthrough and UEFI support.
  # Always use q35 for new VMs.

  default_bios = "ovmf"
  # ovmf = UEFI firmware (Open Virtual Machine Firmware).
  # ovmf IS UEFI — same thing, different name.
  # Always paired with q35 machine type.
  # Requires a small EFI disk per VM — defined in each module.

  default_scsihw = "virtio-scsi-pci"
  # Paravirtualised SCSI controller.
  # Fastest option, scales to multiple disks, supports TRIM to ZFS.

  default_discard = "on"
  # Passes TRIM from guest to ZFS when files are deleted.
  # Always enable on ZFS-backed disks.

  default_vga = "std"
  # Standard VGA — compatible with Proxmox noVNC console.

  default_qemu_agent = true
  # Enables QEMU guest agent for graceful shutdown and IP reporting.
  # Install qemu-guest-agent inside the guest OS after deployment.

  # ── Network ───────────────────────────────────────────────────
  default_nic_model = "virtio"
  # Paravirtualised NIC — fastest, lowest CPU overhead.
  # Supported natively by Linux and FreeBSD.

  # Bridge assignments — match bridges in group_vars/proxmox.yml
  bridge_management = "vmbr0"
  # vmbr0 = RMU CyberLab — management and general VM traffic

  bridge_internal = "vmbr1"
  # vmbr1 = Cyber Range internal bridge — isolated VM traffic

  bridge_wan = "vmbr2"
  # vmbr2 = CyberRange WAN — physical NIC for external traffic

  bridge_lab = "vmbr3"
  # vmbr3 = Lab LAN bridge — internal lab network segment
}
