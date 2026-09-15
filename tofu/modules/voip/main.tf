# tofu/modules/voip/main.tf
# Defines the Asterisk VoIP VM on Proxmox.
# Two resources in order:
#   1. proxmox_download_file          — fetches the Debian 13 cloud image
#      from debian.org into Proxmox local storage once.
#   2. proxmox_virtual_environment_vm — creates the VM, attaches the image
#      as the root disk, and configures cloud-init.
#
# OpenTofu reads the dependency between these two automatically —
# the image download always completes before the VM is created.

# ── Debian 13 cloud image ─────────────────────────────────────────

resource "proxmox_download_file" "voip_debian13" {
  # proxmox_download_file is the current non-deprecated resource name.
  # proxmox_virtual_environment_download_file is the old alias —
  # both work today but the old name will be removed in provider v1.0.

  content_type = "iso"
  # Despite the name, Proxmox stores qcow2 cloud images alongside
  # ISO files in /var/lib/vz/template/iso/ on local storage.
  # "iso" is the correct content_type for both ISOs and cloud images.

  datastore_id = var.iso_storage
  # "local" — the built-in Proxmox storage at /var/lib/vz/
  # This is the only storage that accepts ISO and cloud image files.
  # vmdata (ZFS) only accepts VM disk images, not cloud images.

  node_name = var.node
  # Proxmox node that performs the download and stores the image.

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  # Official Debian cloud image for amd64 (x86-64).
  # "latest" is a symlink maintained by Debian that always points
  # to the current stable point release — no manual URL updates needed.
  # "genericcloud" is the correct variant for VM use — trimmed for
  # VMs only, smaller image, faster boot than the "generic" variant.

  file_name = "debian-13-genericcloud-amd64.img"
  # .img extension — Proxmox ISO storage only accepts .iso and .img
  # extensions. .qcow2 is rejected at the storage layer even though
  # the file contents are identical qcow2 format.
  # Using a fixed name prevents re-downloads when the "latest" symlink
  # moves to a new point release — the file_name stays stable.

  overwrite           = false
  # false = never re-download or clobber the file on future applies.

  overwrite_unmanaged = true
  # true = if the file already exists in Proxmox local storage but was
  # NOT created by this OpenTofu state (e.g. downloaded by another project
  # like cs3-hack-sqli), adopt it into this state without re-downloading.
  # Without this, OpenTofu errors when it finds a file it did not create.
  # The file contents are identical — no download occurs.
}

# ── VoIP VM ───────────────────────────────────────────────────────

resource "proxmox_virtual_environment_vm" "voip" {

  # ── Identity ───────────────────────────────────────────────────
  name      = var.vm_name
  node_name = var.node
  vm_id     = var.vm_id

  # ── Boot behaviour ─────────────────────────────────────────────
  started = true
  # Start the VM immediately after creation.

  on_boot = true
  # Automatically start this VM when the Proxmox node boots.
  # Ensures Asterisk is always running after a server reboot.

  # ── Firmware and chipset ───────────────────────────────────────
  machine = var.machine_type
  # q35 = modern Intel ICH9 chipset emulation.
  # Required to pair with ovmf UEFI.

  bios = var.bios
  # ovmf = UEFI firmware.
  # Debian 13 cloud images expect a UEFI environment to boot correctly.
  # Always pair ovmf with q35 machine type — they are a matched set.

  # ── CPU ────────────────────────────────────────────────────────
  cpu {
    cores = var.vm_cores
    type  = var.cpu_type
    # kvm64 = safe generic x86-64 baseline.
    # Allows live migration between nodes without CPU feature conflicts.
  }

  # ── Memory ─────────────────────────────────────────────────────
  memory {
    dedicated = var.vm_memory
    # 2048 MB = 2 GB dedicated RAM.
    # Asterisk idles at ~50 MB — 2 GB is generous and leaves room
    # for call recordings and log buffering.
  }

  # ── QEMU guest agent ───────────────────────────────────────────
  agent {
    enabled = var.qemu_agent
    timeout = "1s"
    # timeout = "1s" — do not wait for the agent to respond at
    # VM creation time. The fresh cloud image does not have
    # qemu-guest-agent installed yet. Ansible installs it on first run.
    # After that, the agent is available for graceful shutdown and
    # IP reporting in the Proxmox web UI.
  }

  # ── Display ────────────────────────────────────────────────────
  vga {
    type = var.vga
    # std = standard VGA, compatible with Proxmox noVNC console.
    # Break-glass access if SSH becomes unreachable.
  }

  # ── SCSI controller ────────────────────────────────────────────
  scsi_hardware = var.scsihw
  # virtio-scsi-pci = fastest paravirtualised SCSI controller.
  # Supports TRIM passthrough to ZFS and up to 256 disks per VM.

  # ── Root disk ──────────────────────────────────────────────────
  disk {
    datastore_id = var.vm_storage
    # "vmdata" — ZFS stripe pool on the two Samsung PM863a SSDs.

    file_id = proxmox_download_file.voip_debian13.id
    # References the downloaded Debian 13 image from above.
    # OpenTofu sees this dependency and ensures the download finishes
    # before attempting to create the VM.

    interface = "scsi0"
    # Primary boot disk slot.

    size    = var.vm_disk_size
    # 20 GB — cloud-init resizes the filesystem to fill this on first boot.

    discard = "on"
    # Passes TRIM from the Debian guest through to ZFS.
    # Prevents pool fragmentation as files are created and deleted.

    iothread = true
    # Dedicated I/O thread for this disk.
    # Prevents disk I/O from blocking vCPU threads under load.
  }

  # ── EFI disk ───────────────────────────────────────────────────
  efi_disk {
    datastore_id = var.vm_storage
    type         = "4m"
    # 4 MB EFI variable store — stores UEFI boot entries.
    # Without this the VM loses its boot entry on every power off.
  }

  # ── Network ────────────────────────────────────────────────────
  network_device {
    bridge = var.bridge
    # vmbr0 = management bridge on 192.168.80.0/24.
    # ATAs sit on the same network — no routing needed.

    model = var.nic_model
    # virtio = paravirtualised NIC, lowest CPU overhead.
  }

  # ── Cloud-init ─────────────────────────────────────────────────
  initialization {
    datastore_id = var.iso_storage
    # Must be "local" — cloud-init seed files (user-data, meta-data,
    # network-config) are stored as ISO images in local storage.
    # Proxmox mounts this as a virtual CD-ROM on first boot.
    # Using var.iso_storage ("local") not var.vm_storage ("vmdata")
    # because vmdata does not support ISO content type.
    # Without this explicit value the provider guesses "local-lvm"
    # which does not exist on this node — VM creation would fail.

    ip_config {
      ipv4 {
        address = var.vm_ip
        # Static IP in CIDR notation: 192.168.80.10/24
        gateway = var.vm_gateway
        # 192.168.80.1 — your existing router/OPNsense
      }
    }

    user_account {
      username = var.cloud_init_user
      # "debian" — the default user in Debian 13 cloud images.
      keys = [var.ssh_public_key]
      # SSH public key injected into /home/debian/.ssh/authorized_keys.
    }
  }

  # ── Boot order ─────────────────────────────────────────────────
  boot_order = ["scsi0"]
  # Boot from root disk only — prevents accidental PXE or CD-ROM boot.

  depends_on = [proxmox_download_file.voip_debian13]
  # Explicit dependency even though file_id already implies it.
  # Makes the dependency graph visible when reading the code —
  # anyone can see at a glance that the image must exist before the VM.
}
