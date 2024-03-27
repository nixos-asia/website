---
order: 3
---

# Install NixOS directly from a remote flake

>[!WARNING] To Write
> This tutorial has not been written yet. What you see below are just rough notes.

Boot from a NixOS install live CD ("minimal" version is sufficient), and then:

```sh
# Assuming your system is x86_64-linux
sudo nix \
    --extra-experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick" \
    --write-efi-boot-entries \
    --disk main /dev/sda
```
