variable "proxmox_url" {
  type = string
} # proxmox url
variable "proxmox_token_id" {
  type = string
} # id for the token below
variable "proxmox_token" {
  type      = string
  sensitive = true
} # api token (datacenter -> permissions -> api tokens -> make one)
variable "proxmox_node" {
  type = string
} # node name
variable "proxmox_storage" {
  type = string
} # the proxmox vm/container storage - e.g., local-zfs 
variable "seed_template_id" {
  type = number
} # seed vmid e.g., 9000
variable "vmid_start" {
  type    = number
  default = 9100
} # packer will allocate, can be static
variable "cpu_cores" {
  type    = number
  default = 2
} # number of cpu cores
variable "memory_mb" {
  type    = number
  default = 2048
} # allocated RAM size

# name & description for the new final template
variable "template_name" {
  type    = string
  default = "debian13-base"
}
variable "template_description" {
  type    = string
  default = "debian 13 (genericcloud) + updates + qemu-guest-agent; cloud-init re-armed"
}