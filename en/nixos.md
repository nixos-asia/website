# NixOS

NixOS is a Linux distribution based on the [[nix]] package manager. 

## Getting Started

1. [Download](https://nixos.org/download#download-nixos) and install NixOS
1. [[flakes|Flakify]] your NixOS configuration in `/etc/nixos/configuration.nix`
    - This can be done by as simple as adding a `/etc/nixos/flake.nix` file containing:
     ```nix
     {
       outputs = { self, nixpkgs }: {
         # replace 'joes-desktop' with your hostname here.
         nixosConfigurations.joes-desktop = nixpkgs.lib.nixosSystem {
           system = "x86_64-linux";
           modules = [ ./configuration.nix ];
         };
       };
     }
     ```
     See [here](https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS) for further information.
2. Convert your NixOS `flake.nix` to use [nixos-flake](https://community.flake.parts/nixos-flake)
   - Allows you to use [[home-manager]], as well as share config with [[nix-darwin]]
