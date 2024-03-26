{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.oneclick = nixpkgs.lib.nixosSystem {
      # TODO: can we parametrize this? Maybe via --override-input?
      system = "aarch64-linux";
      modules = [
        ./disk-config.nix
        disko.nixosModules.disko
        ({ pkgs, ... }: {
          environment.systemPackages = [ pkgs.htop ];
          boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
            grub = {
              efiSupport = true;
              # efiInstallAsRemovable = true;
            };
          };
          networking.hostName = "oneclick";
          services.openssh.enable = true;

          # Remove this after setting up users and keys
          services.openssh.settings.PermitRootLogin = "yes";
          users.users.root.initialHashedPassword = "root";

          system.stateVersion = "23.11";
        })
      ];
    };
  };
}
