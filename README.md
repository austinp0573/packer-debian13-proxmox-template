# debian 13 proxmox template (packer)

this project builds a debian 13 (trixie) proxmox vm template using hashicorp packer and the official proxmox plugin
it clones a base debian 13 genericcloud image (the seed template) provisions updates and basic packages and prepares it as a cloud-init ready template

## requirements
- proxmox ve 8 or later
- debian 13 genericcloud qcow2 image
- hashicorp packer >= 1.9
- proxmox api token with template permissions

## usage
1. import the debian 13 genericcloud qcow2 into proxmox and convert it into a seed template (e.g. vmid 9000).
2. edit `secrets.auto.pkrvars.hcl` with your proxmox connection details.
3. run:
   ```bash
   packer init .
   packer fmt .
   packer validate .
   packer build .
   ```
4. the build will clone the seed template, run updates and package installs, and convert the result into a new template.

## file structure
```cpp
packer.pkr.hcl
secrets.auto.pkrvars.hcl
variables.pkr.hcl
debian13-template.pkr.hcl
provisioners/
  ├─ 10-base.sh
  └─ 90-cloudinit-clean.sh
.gitignore
```

## notes

the resulting template is cloud-init enabled

default packages include qemu-guest-agent, curl, git, htop, tmux, and vim-gtk3

adjust the scripts and variables as needed for your environment

altering the --cicustom cloud-init associated with the seed will disrupt the ssh connection required, don't do anything to the seed without understand the implications

TODO:
- explain seed template creation, improperly created/configured seed template would prevent the packer build from working
- add example secrets.auto.pkrvars.hcl
- adjust file structure to accurately reflect finished packer build


&nbsp;

**466f724a616e6574**