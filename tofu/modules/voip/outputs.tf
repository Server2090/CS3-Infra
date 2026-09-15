# tofu/modules/voip/outputs.tf
# Exposes values from this module to the root config.
# After tofu apply, run: tofu output
# to see these values printed in your terminal.
#
# These outputs become referenceable in tofu/main.tf as:
#   module.voip.vm_ip
#   module.voip.vm_id
# Useful when a future module (e.g. a firewall rule VM) needs to
# know the VoIP server's IP without hardcoding it.

output "vm_ip" {
  description = "Static IPv4 address assigned to the VoIP VM via cloud-init."
  value       = var.vm_ip
  # We expose the input variable directly rather than reading from
  # the VM resource because the bpg/proxmox provider surfaces the
  # cloud-init IP only after the VM has fully booted and the QEMU
  # guest agent has reported it back to Proxmox.
  # The input variable is authoritative — it is what we told cloud-init
  # to configure, so it is always correct immediately after apply.
}

output "vm_id" {
  description = "Proxmox VM ID. Use this to reference the VM in pvesh commands or the Proxmox API."
  value       = proxmox_virtual_environment_vm.voip.vm_id
  # Read from the actual resource so the output reflects the ID
  # Proxmox recorded, not just what we asked for. They will always
  # match, but reading from the resource is the correct pattern —
  # it creates an implicit dependency so this output is only
  # populated after the VM resource is successfully created.
}

output "vm_name" {
  description = "Hostname of the VoIP VM as registered in Proxmox."
  value       = proxmox_virtual_environment_vm.voip.name
}
