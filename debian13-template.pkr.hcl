# source: proxmox-clone
source "proxmox-clone" "debian13" {
  url                      = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true # TODO: change later

  node        = var.proxmox_node
  vm_id       = var.vmid_start       # omit to let packer assign
  clone_vm_id = var.seed_template_id # clone from our debian13 seed template

  vm_name    = "${var.template_name}-build"
  qemu_agent = true
  memory     = var.memory_mb
  cores      = var.cpu_cores

  # disk & nic settings of the clone
  # (these inhereit from the close, change as needed)
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

  # stop the vm gracefully when provisioning is done
  shutdown_command = "sudo shutdown -P now"
  # give it time to shut down cleanly
  shutdown_timeout = "15m"
}

# build: provision, convert to template
build {
  sources = ["source.proxmox-clone.debian13"]

  # upload & run our provisioners
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

  # after shutdown, convert the built vm into a proxmox template with final name/description
  post-processor "shell-local" {
    inline = [
      "set -euo pipefail",
      # rename, set description, then convert to template
      "qm set ${source.vmid} --name ${var.template_name}",
      "qm set ${source.vmid} --description \"${var.template_description}\"",
      "qm template ${source.vmid}"
    ]
  }
}