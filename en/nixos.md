# NixOS

NixOS is a Linux distribution based on the [[nix]] package manager. 

## Getting Started

1. [Download](https://nixos.org/download#download-nixos) and install NixOS
1. [[flakes|Flakify]] your NixOS configuration in `/etc/nixos/configuration.nix`
2. Convert your NixOS `flake.nix` to use [nixos-flake](https://community.flake.parts/nixos-flake) (optionally with [[home-manager]])
