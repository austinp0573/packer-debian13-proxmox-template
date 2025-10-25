# proxmox url
variable "proxmox_url" {
  type = string
}

# id for the token below
variable "proxmox_token_id" {
  type = string
}

# api token (datacenter -> permissions -> api tokens -> make one)
variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_host" {
  type = string
}

variable "proxmox_ssh_user" {
  type    = string
  default = null
}

# ssh key packer will use
variable "ssh_private_key_file" {
  type = string
}

variable "ssh_pubkey_path" {
  type = string
}

variable "proxmox_node_ssh_user" {
  type = string
}

# node name
variable "proxmox_node" {
  type = string
}

# the proxmox vm/container storage - e.g., local-zfs
variable "proxmox_storage" {
  type = string
}

# add another var. for location of snippet storage
variable "proxmox_snippet_storage" {
  type        = string
  description = "proxmox storage ID used for snippets"
}

variable "proxmox_snippet_storage_path" {
  type = string
}

variable "injected_cloudinit_filename" {
  type = string
}

# seed vmid e.g., 9000
variable "seed_template_id" {
  type = number
}

# packer will allocate, can be static
variable "vmid_start" {
  type    = number
  default = 9100
}

# number of cpu cores
variable "cpu_cores" {
  type    = number
  default = 2
}

# allocated RAM size
variable "memory_mb" {
  type    = number
  default = 2048
}

# name & description for the new final template
variable "template_name" {
  type    = string
  default = "debian13-base"
}

variable "template_description" {
  type    = string
  default = "debian 13 (genericcloud) + updates + qemu-guest-agent; cloud-init re-armed"
}