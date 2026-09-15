# tofu/main.tf
# Root entry point for cs3-infra tofu.
# This file only calls modules — no resources defined directly here.
# One module block per VM. Add new VMs by adding new module blocks.
#
# Run order:
#   tofu init    — download providers and modules (run once, re-run after any version change)
#   tofu plan    — preview what will be created/changed/destroyed
#   tofu apply   — execute the plan

# ── VMs ───────────────────────────────────────────────────────────

module "voip" {
  source = "./modules/voip"
  # Relative path to the module directory.
  # OpenTofu reads all .tf files inside ./modules/voip/ as the module.

  # ── Proxmox placement ───────────────────────────────────────────
  # All three come from locals.tf — defined once, used by every module.
  # If you ever rename your storage pool, change it in locals.tf once
  # and every module picks it up automatically.
  node        = local.node
  vm_storage  = local.vm_storage
  iso_storage = local.iso_storage

  # ── VM hardware defaults ─────────────────────────────────────────
  # All sourced from the shared defaults in locals.tf.
  # These are the same values every other VM in the lab will use.
  # Only override a value here if THIS VM genuinely needs something
  # different — e.g. a different cpu_type for live migration testing.
  cpu_type     = local.default_cpu_type
  machine_type = local.default_machine_type
  bios         = local.default_bios
  scsihw       = local.default_scsihw
  discard      = local.default_discard
  vga          = local.default_vga
  qemu_agent   = local.default_qemu_agent
  nic_model    = local.default_nic_model

  # ── Network ──────────────────────────────────────────────────────
  bridge     = local.bridge_management
  # local.bridge_management = "vmbr0"
  # vmbr0 is the management bridge with the physical NIC attached.
  # The ATAs sit on the same 192.168.80.0/24 network and reach
  # Asterisk here — no routing or NAT needed between them.

  vm_ip      = var.voip_vm_ip
  vm_gateway = var.voip_vm_gateway
  # Both come from terraform.tfvars — change them there, not here.

  # ── VM identity ──────────────────────────────────────────────────
  vm_id   = var.voip_vm_id
  vm_name = "voip"
  # vm_name becomes the Proxmox display name and the cloud-init
  # hostname. Ansible will later set the FQDN to voip.cs3.lab.

  # ── Cloud-init credentials ───────────────────────────────────────
  ssh_public_key = file("~/.ssh/cs3admin@cs3.lab.pub")
  # file() reads the public key from your control machine at
  # plan/apply time. Public keys are not secret — they are safe
  # to pass this way. The private key never appears here or in git.
  # If this file does not exist yet, create it first with:
  #   ssh-keygen -t ed25519 -f ~/.ssh/cs3admin@cs3.lab -C "cs3admin@cs3.lab"
  # then re-run tofu plan.
}
