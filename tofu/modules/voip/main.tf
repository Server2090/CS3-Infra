# tofu/modules/voip/main.tf
# Defines the Asterisk VoIP VM on Proxmox.
# Two resources in order:
#   1. proxmox_virtual_environment_download_file — fetches the Debian 13
#      cloud image from debian.org into Proxmox local storage once.
#   2. proxmox_virtual_environment_vm            — creates the VM, attaches
#      the image as the root disk, and configures cloud-init.
#
# OpenTofu reads the dependency between these two automatically —
# the image download always completes before the VM is created.

# ── Debian 13 cloud image ─────────────────────────────────────────

resource "proxmox_virtual_environment_download_file" "voip_debian13" {
  content_type = "iso"
  # Despite the name, Proxmox stores qcow2 cloud images alongside
  # ISO files in /var/lib/vz/template/iso/ on local storage.
  # "iso" is the correct content_type for both ISOs and cloud images.

  datastore_id = var.iso_storage
  # "local" — the built-in Proxmox storage at /var/lib/vz/
  # This is the only storage that accepts ISO and cloud image files.

  node_name = var.node
  # Proxmox node that performs the download and stores the image.
  # In a single-node setup this is always "pve".

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  # Official Debian cloud image for amd64 (x86-64).
  # "latest" is a symlink maintained by Debian that always points
  # to the current stable point release — no manual URL updates needed.
  # "genericcloud" is the correct variant for VM use:
  #   generic      = for bare metal and VMs, includes more drivers
  #   genericcloud = trimmed for VMs only, smaller image, faster boot
  #   nocloud      = no cloud-init, requires manual config — never use this

  file_name = "debian-13-genericcloud-amd64.qcow2"
  # Explicit filename so the file is predictable on disk regardless
  # of which point release the "latest" symlink resolves to.
  # Without this OpenTofu derives the name from the full URL which
  # can include a datestamp that changes with each Debian point release,
  # causing OpenTofu to think it needs to re-download on every apply.

  overwrite = false
  # false = skip the download if the file already exists in Proxmox.
  # Makes this resource idempotent — a second tofu apply does not
  # trigger a 1 GB download. Set to true only if you want to force
  # a fresh download of the latest image.
}

# ── VoIP VM ───────────────────────────────────────────────────────

resource "proxmox_virtual_environment_vm" "voip" {

  # ── Identity ───────────────────────────────────────────────────
  name      = var.vm_name
  # Shown in the Proxmox web UI and used as the cloud-init hostname.
  # Will appear in your DNS as voip.cs3.lab once Ansible configures it.

  node_name = var.node
  # Which Proxmox node hosts this VM.

  vm_id = var.vm_id
  # Unique numeric ID for this VM across the entire Proxmox cluster.
  # Set in terraform.tfvars — must not clash with any existing VM ID.
  # Proxmox uses this ID for all internal references to the VM.

  # ── Firmware and chipset ───────────────────────────────────────
  machine = var.machine_type
  # q35 = modern Intel ICH9 chipset emulation.
  # Required to pair with ovmf UEFI. Also enables PCIe device support
  # if you ever need to pass through hardware to this VM later.

  bios = var.bios
  # ovmf = UEFI firmware (Open Virtual Machine Firmware).
  # Debian 13 cloud images expect a UEFI environment to boot correctly.
  # Always pair ovmf with q35 machine type — they are a matched set.

  # ── CPU ────────────────────────────────────────────────────────
  cpu {
    cores = var.vm_cores
    # 2 vCPU cores. Asterisk is single-threaded for call processing
    # but uses worker threads for I/O. 2 cores handles well over 100
    # concurrent calls — far beyond what two ATAs will ever generate.

    type = var.cpu_type
    # kvm64 = safe generic x86-64 CPU baseline.
    # If you ever add a second Proxmox node, VMs using kvm64 can
    # live-migrate between nodes without CPU feature compatibility issues.
    # Override to "host" only if you need maximum CPU performance and
    # are certain this VM will never migrate.
  }

  # ── Memory ─────────────────────────────────────────────────────
  memory {
    dedicated = var.vm_memory
    # Dedicated RAM in MB. 2048 = 2 GB.
    # "dedicated" means this RAM is reserved for the VM — Proxmox
    # will not give it to other VMs even when this VM is idle.
    # Asterisk idles at approximately 50 MB — 2 GB is very generous
    # but leaves room for call recordings and log buffering.
  }

  # ── QEMU guest agent ───────────────────────────────────────────
  agent {
    enabled = var.qemu_agent
    # The QEMU guest agent runs inside the VM and communicates with
    # Proxmox over a virtio serial channel.
    # It enables:
    #   - Proxmox web UI to show the VM's IP address
    #   - Graceful shutdown from the Proxmox UI (clean systemd shutdown)
    #   - Consistent snapshots (filesystem quiesce before snapshot)
    # Ansible installs qemu-guest-agent inside the VM after first boot.
  }

  # ── Display ────────────────────────────────────────────────────
  vga {
    type = var.vga
    # std = standard VGA, compatible with the Proxmox noVNC web console.
    # After Ansible completes you should never need the console —
    # everything is managed over SSH. It exists as a break-glass option
    # if SSH becomes unreachable.
  }

  # ── SCSI controller ────────────────────────────────────────────
  scsi_hardware = var.scsihw
  # virtio-scsi-pci = paravirtualised SCSI controller.
  # Fastest available disk option — the guest talks directly to the
  # hypervisor without emulating real hardware.
  # Supports TRIM passthrough to ZFS and scales to 256 disks per VM.

  # ── Root disk ──────────────────────────────────────────────────
  disk {
    datastore_id = var.vm_storage
    # "vmdata" — the ZFS stripe pool on your two Samsung PM863a SSDs.
    # Created and registered by the proxmox_cs3pve Ansible role.

    file_id = proxmox_virtual_environment_download_file.voip_debian13.id
    # References the downloaded Debian 13 image from the resource above.
    # OpenTofu sees this dependency and ensures the download resource
    # finishes before attempting to create the VM.
    # The provider imports the qcow2 image into the ZFS pool as the
    # VM's root disk, then resizes it to match the "size" value below.

    interface = "scsi0"
    # The virtual SCSI slot this disk occupies inside the VM.
    # scsi0 is the primary boot disk by convention.
    # Additional disks would use scsi1, scsi2, etc.

    size = var.vm_disk_size
    # Disk size in GB after import and resize.
    # The Debian 13 cloud image is approximately 2.7 GB expanded.
    # Setting size = 20 causes cloud-init to resize the filesystem
    # to fill all 20 GB on first boot — no manual partitioning needed.

    discard = "on"
    # Passes TRIM commands from the Debian guest through to ZFS.
    # When Debian deletes files, the freed blocks are returned to the
    # ZFS pool. Always enable on ZFS-backed disks to prevent pool
    # fragmentation over time.

    iothread = true
    # Gives this disk its own dedicated I/O processing thread.
    # Prevents disk I/O from blocking vCPU threads under load.
    # Always enable for single-disk VMs — no downside.
  }

  # ── EFI disk ───────────────────────────────────────────────────
  efi_disk {
    datastore_id = var.vm_storage
    # EFI variable store must live on the same storage pool as the
    # root disk so both are accessible at the same time.

    type = "4m"
    # 4 MB EFI variable store.
    # Stores UEFI boot entries so the VM remembers how to boot
    # after a reboot. Without this the VM loses its boot entry every
    # time it powers off. Always use "4m" for new VMs — "2m" is legacy.
  }

  # ── Network ────────────────────────────────────────────────────
  network_device {
    bridge = var.bridge
    # vmbr0 = management bridge.
    # The VM gets an interface on the 192.168.80.0/24 network —
    # the same network the Proxmox node and your ATAs reach.
    # This is why the ATAs can register with Asterisk without any
    # extra routing — they are all on the same Layer 3 network.

    model = var.nic_model
    # virtio = paravirtualised NIC driver.
    # The guest talks directly to the hypervisor's network stack —
    # no hardware emulation overhead.
    # Supported natively by Linux kernel 2.6.25+ — no driver install needed.
  }

  # ── Cloud-init ─────────────────────────────────────────────────
  # Cloud-init is a standard VM first-boot configuration system.
  # Proxmox injects these values into a virtual CD-ROM that Debian
  # reads on first boot. Cloud-init sets the hostname, creates the
  # user account, injects the SSH key, and configures the static IP —
  # all before Ansible ever connects.
  initialization {

    ip_config {
      ipv4 {
        address = var.vm_ip
        # Static IPv4 in CIDR notation — e.g. 192.168.80.10/24
        # The /24 suffix tells Debian the subnet mask (255.255.255.0)
        # so it knows which traffic stays local vs goes to the gateway.

        gateway = var.vm_gateway
        # Default route. All traffic not destined for 192.168.80.0/24
        # is forwarded here (your existing router/OPNsense).
      }
    }

    user_account {
      username = var.cloud_init_user
      # "debian" — the default unprivileged user in Debian 13 cloud images.
      # This account has passwordless sudo by default (cloud image convention).
      # Ansible connects as this user via SSH key after first boot.

      keys = [var.ssh_public_key]
      # List of SSH public keys written to /home/debian/.ssh/authorized_keys.
      # The matching private key on your Ansible control machine is used
      # to connect. The private key never appears in this file or in git.
    }
  }

  # ── Boot order ─────────────────────────────────────────────────
  boot_order = ["scsi0"]
  # Explicit boot order: boot from the root disk only.
  # Prevents the VM from accidentally booting from a CD-ROM or
  # trying PXE if the disk is temporarily unavailable.
}
