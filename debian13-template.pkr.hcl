# source: proxmox-clone
source "proxmox-clone" "debian13" {
  proxmox_url = var.proxmox_url
  username    = var.proxmox_token_id
  token       = var.proxmox_token
  # insecure_skip_tls_verify = true # TODO: change later
  scsi_controller = "virtio-scsi-pci"

  node        = var.proxmox_node
  vm_id       = var.vmid_start       # omit to let packer assign
  clone_vm_id = var.seed_template_id # clone from our debian13 seed template
  vm_name     = "${var.template_name}-build"
  qemu_agent  = true
  memory      = var.memory_mb
  cores       = var.cpu_cores

  # disk & nic settings of the clone
  # (these inhereit from the clone, change as needed)
  # when hardware supports it, add vlan_tag = <id>
  # if ommitted, inhereits from the seed
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # communicator: the seed has cloud-init enabled; proxmox injects a one-time dhcp + ssh key for packer
  communicator = "ssh"

  # genericcloud defaults: debian user exists with key auth
  ssh_username = "debian"

  # cloud-init injected ssh key automatically, no password needed 
  ssh_timeout            = "10m"
  ssh_handshake_attempts = 60
  ssh_agent_auth         = false
  ssh_private_key_file   = var.ssh_private_key_file
}

# build: provision, convert to template
build {
  sources = ["source.proxmox-clone.debian13"]

  # upload & run provisioners
  provisioner "file" {
    source      = "provisioners/htoprc"
    destination = "/tmp/htoprc"
  }

  provisioner "file" {
    source      = "provisioners/10-base.sh"
    destination = "/tmp/10-base.sh"
  }

  provisioner "file" {
    source      = "provisioners/90-cloudinit-clean.sh"
    destination = "/tmp/90-cloudinit-clean.sh"
  }

  provisioner "shell" { inline = ["chmod +x /tmp/10-base.sh /tmp/90-cloudinit-clean.sh"] }
  provisioner "shell" { inline = ["sudo /tmp/10-base.sh"] }
  provisioner "shell" { inline = ["sudo /tmp/90-cloudinit-clean.sh"] }

  post-processor "shell-local" {
    keep_input_artifact = true
    inline = [<<-EOF
set -euo pipefail

PROX_SSH="${var.proxmox_node_ssh_user}@${var.proxmox_node}"          # or an IP/DNS of the node
SNIP_STORE="${var.proxmox_snippet_storage}"   # must be a directory storage (e.g., 'local')
SNIP_DIR="${var.proxmox_snippet_storage_path}"     # path for 'local' directory storage
VMID="${var.vmid_start}"                      # the built VM becomes the template
INJECTED_CLOUDINIT_FILENAME="${var.injected_cloudinit_filename}"

# 1) combine local cloud-init-secrets.env with cloud-init-template.yaml to get template that will be injected and enabled
# at the end for the subsequent vm-clones from that template
. ./cloud-init/cloud-init-secrets.env
envsubst < ./cloud-init/cloud-init-template.yaml > /tmp/$INJECTED_CLOUDINIT_FILENAME

# 2) securely deposit created cloud-init.yaml in the correct location on the proxmox host
ssh -o StrictHostKeyChecking=no "$PROX_SSH" "mkdir -p '$SNIP_DIR'"
scp -o StrictHostKeyChecking=no "/tmp/$INJECTED_CLOUDINIT_FILENAME" "$PROX_SSH:$SNIP_DIR/$INJECTED_CLOUDINIT_FILENAME"

# 3) set cicustom on the new vm template
ssh -o StrictHostKeyChecking=no "$PROX_SSH" \
  "qm set $VMID --cicustom user=$${SNIP_STORE}:snippets/$INJECTED_CLOUDINIT_FILENAME,network=$${SNIP_STORE}:snippets/net-dhcp.yaml"

# verify cloud-init content
ssh -o StrictHostKeyChecking=no "$PROX_SSH" "qm cloudinit dump $VMID user >/dev/null && qm cloudinit dump $VMID network >/dev/null"

# 4) rename and convert the just-built vm into the final template
ssh -o StrictHostKeyChecking=no "$PROX_SSH" \
  "qm set $VMID --ide2 local-zfs:cloudinit"
EOF
    ]
  }
}  