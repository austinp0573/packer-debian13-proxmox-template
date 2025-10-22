# source: proxmox-clone
source "proxmox-clone" "debian13" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true # TODO: change later
  scsi_controller          = "virtio-scsi-pci"

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
  ssh_username = "debian" # genericcloud defaults: debian user exists with key auth
  # cloud-init injected ssh key automatically, no password needed 
  ssh_timeout            = "20m"
  ssh_handshake_attempts = 40
}

# build: provision, convert to template
build {
  sources = ["source.proxmox-clone.debian13"]

  # upload & run provisioners
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
    inline = [
      "set -euo pipefail",
      "curl -ks -H 'Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token}' -X POST '${var.proxmox_url}/nodes/${var.proxmox_node}/qemu/${var.vmid_start}/config' --data-urlencode 'name=${var.template_name}' --data-urlencode 'description=${var.template_description}'",
      "curl -ks -H 'Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token}' -X POST '${var.proxmox_url}/nodes/${var.proxmox_node}/qemu/${var.vmid_start}/template'"
    ]
  }
}