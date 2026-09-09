# tofu/versions.tf
# Pins the minimum OpenTofu version and all required providers.
# This is the first file tofu reads. If versions do not match it
# stops immediately with a clear error before touching anything.
# Keep this file focused — no resources, no variables, just versions.

terraform {
  required_version = ">= 1.12.0"
  # >= 1.12.0 means this config requires at least OpenTofu 1.12.
  # You are running 1.12.6 which satisfies this constraint.
  # We pin the minimum not an exact version so patch updates work fine.

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      # bpg/proxmox = registry.opentofu.org/bpg/proxmox
      # This is the community Proxmox provider maintained by bpg-dev.
      # The most complete and actively maintained Proxmox provider available.

      version = "~> 0.112"
      # ~> 0.111 = >= 0.111.0 AND < 0.112.0
      # Allows patch releases but not the next minor version.
      # The bpg/proxmox provider ships breaking changes between minors
      # on 0.x so we pin tightly.
    }

    sops = {
      source  = "carlpett/sops"
      # carlpett/sops = registry.opentofu.org/carlpett/sops
      # Lets OpenTofu decrypt SOPS-encrypted files at plan/apply time.
      # Uses the age key at ~/.config/sops/age/keys.txt automatically.

      version = "~> 1.1"
      # ~> 1.1 = >= 1.1.0 AND < 1.2.0
      # Stable release, actively maintained.
    }

    tailscale = {
      source  = "tailscale/tailscale"
      # tailscale/tailscale = registry.opentofu.org/tailscale/tailscale
      # Official Tailscale provider maintained by Tailscale Inc.
      # Creates auth keys that register the VM automatically on apply.

      version = "~> 0.29"
      # ~> 0.17 = >= 0.17.0 AND < 0.18.0
      # Pins the minor version — Tailscale follows semver strictly.
    }
  }
}
