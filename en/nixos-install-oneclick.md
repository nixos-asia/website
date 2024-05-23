---
order: 3
---

# Install NixOS directly from a remote flake

>[!WARNING] WIP
> This tutorial has not been completed yet.

Unlike the previous tutorials ([[nixos-install-flake|1]]; [[nixos-install-disko|2]]), the goal here is to near-fully automate our NixOS install using one command (see the next section)

{#install}
## How to install

Boot your computer from any NixOS install live CD ("minimal" version is sufficient), and then from the terminal run:

```sh
# Assuming 
# - your system is x86_64-linux
# - your harddrive device is /dev/sda
sudo nix \
    --extra-experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick" \
    --write-efi-boot-entries \
    --disk main /dev/sda
```

Here, `"github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick"` is [our own sample configuration](https://github.com/nixos-asia/website/tree/master/global/nixos-install-oneclick) flake. Feel free to substitute it with your own flake. 

If everything goes well, you should see the installation successfully finish with a message like this below:

```text
...
Random seed file /boot/loader/random-seed successfully written (32 bytes).
Successfully initialized system token in EFI variable with 32 bytes.
Created EFI boot entry "Linux Boot Manager".
installation finished!
```

- Take note of the IP address of your machine using `ifconfig`.
- Reboot your computer (or VM)! And you should boot into NixOS. 
- Test ssh access using `ssh root@<ip-addr>`

## User management

The above flake is meant to be used on a server. As such, it authorizes root access through SSH keys. 

- [ ] If you are setting up a desktop, you may have to ...