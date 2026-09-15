# tofu/outputs.tf
# Surfaces module outputs to the terminal after a successful apply.
# Run: tofu output
# at any time after apply to see current values without re-running apply.

output "voip_vm_ip" {
  description = "Static IP address of the Asterisk VoIP VM."
  value       = module.voip.vm_ip
  # Useful to confirm the IP you set in terraform.tfvars was applied
  # correctly, and to pass to other tools (Ansible inventory, DNS).
}

output "voip_vm_id" {
  description = "Proxmox VM ID of the Asterisk VoIP VM."
  value       = module.voip.vm_id
  # Use this in pvesh commands to interact with the VM via the API:
  #   pvesh get /nodes/pve/qemu/100/status/current
}

output "voip_vm_name" {
  description = "Hostname of the Asterisk VoIP VM as registered in Proxmox."
  value       = module.voip.vm_name
}
