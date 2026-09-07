# tofu/main.tf
# Root entry point for cs3-infra tofu.
# This file only calls modules — no resources defined directly here.
# One module block per VM. Add new VMs by adding new module blocks.
#
# Run order:
#   tofu init    — download providers and modules
#   tofu plan    — preview what will be created
#   tofu apply   — create the resources

# ── VMs ───────────────────────────────────────────────────────────
# No VMs defined yet — add module blocks here as VMs are planned.
# Example structure when adding a VM:
#
# module "vm_name" {
#   source = "./modules/vm_name"
#
#   node        = local.node
#   vm_storage  = local.vm_storage
#   iso_storage = local.iso_storage
#
#   cpu_type     = local.default_cpu_type
#   machine_type = local.default_machine_type
#   bios         = local.default_bios
#   scsihw       = local.default_scsihw
#   discard      = local.default_discard
#   vga          = local.default_vga
#   qemu_agent   = local.default_qemu_agent
#   nic_model    = local.default_nic_model
# }
