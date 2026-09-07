# cs3-infra

Infrastructure as code for the CS3 Cyber Security Club's Proxmox server.

## Stack

- **Ansible** — host configuration, hardening, and Proxmox setup
- **OpenTofu** — VM provisioning
- **SOPS + age** — secret encryption

## Server

- Dell PowerEdge R440
- Proxmox VE (Debian trixie)
- 3.5TB ZFS stripe pool for VM storage (vmdata)
- 120GB ZFS OS pool (rpool)

## Structure

```
cs3-infra/
├── ansible/                   # Host configuration
│   ├── inventory/             # Hosts, group vars
│   ├── roles/
│   │   ├── common/            # Baseline Linux hardening
│   │   ├── proxmox/           # Shared Proxmox config
│   │   └── proxmox_cs3pve/    # R440-specific config
│   └── site.yml               # Master playbook
└── tofu/                      # VM provisioning
    ├── modules/               # VM module definitions
    └── main.tf                # Root entry point
```

## Prerequisites

- Ansible 2.19+
- OpenTofu 1.12+
- SOPS 3.13+
- age 1.2+
- age key at `~/.config/sops/age/keys.txt`

## Usage

### Configure the server

```bash
cd ansible
ansible-playbook site.yml
```

### Run a specific role only

```bash
ansible-playbook site.yml -t common_ufw
```

### Preview changes without applying

```bash
ansible-playbook site.yml --check --diff
```

### Provision VMs

```bash
cd tofu
tofu init
tofu plan
tofu apply
```

## Secrets

Secrets are encrypted with SOPS and age and are never committed to git.
To edit a secrets file:

```bash
sops ansible/inventory/group_vars/proxmox.sops.yml
```

## License

MIT — see [LICENSE](LICENSE)
