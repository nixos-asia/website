---
order: 3
---

# Install NixOS directly from a remote flake

>[!WARNING] WIP
> This tutorial has not been completed yet.

Unlike the previous tutorials ([[nixos-install-flake|1]]; [[nixos-install-disko|2]]), the goal here is to near-fully automate our NixOS install using one command (see the next section).

{#install}
## How to install

Boot your computer from any NixOS install live CD ([Minimal ISO image](https://nixos.org/download/#minimal-iso-image) is sufficient), and then from the terminal run:

>[!NOTE] Flake template? 
> Move this template to [flake-parts/templates](https://github.com/flake-parts/templates) and guide users as to how to [override](https://github.com/flake-parts/templates/issues/2) it (to set `system`, disk device and root user's authorized ssh key)?

```sh
# Assuming
# - your system is x86_64-linux
# - your harddrive device is /dev/sda
FLAKE="github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick"
DISK_DEVICE=/dev/sda
sudo nix \
    --extra-experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "$FLAKE" \
    --write-efi-boot-entries \
    --disk main "$DISK_DEVICE"
```

Here, `"github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick"` is [our own sample configuration](https://github.com/nixos-asia/website/tree/master/global/nixos-install-oneclick) flake. Feel free to substitute it with your own flake.

If everything goes well, you should see the installation successfully finish with a message like below:

```text
...
Random seed file /boot/loader/random-seed successfully written (32 bytes).
Successfully initialized system token in EFI variable with 32 bytes.
Created EFI boot entry "Linux Boot Manager".
installation finished!
```

1. Take note of the IP address of your machine using `ifconfig`.
1. Reboot your computer (or VM)! Expect to boot into NixOS.
1. Test ssh access using `ssh root@<ip-addr>`

## User management

The above flake is meant to be used on a server. As such, it authorizes root access through SSH keys.

- [ ] If you are setting up a desktop, you may have to ...

## Making further changes to the flake

- [ ] After install, how do we make further changes to the flake and apply that configuration?
  - Is the "device" in `disk-config.nix` still valid?