---
order: 3
---

# Install NixOS directly from a remote flake

>[!todo] To Write
> This tutorial has not been written yet. What you see below are just rough notes.

Boot from a NixOS install live CD, and then:

```sh
sudo nix --extra-experimental-features 'flakes nix-command' run github:nix-community/disko#disko-install -- --flake "github:nixos-asia/website/disko-install?dir=global/nixos-install-oneclick#oneclick" --write-efi-boot-entries --disk main /dev/sda
```