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
          boot.loader.grub = {
            efiSupport = true;
            efiInstallAsRemovable = true;
          };
          networking.hostname = "oneclick";
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQRxPoqlThDrkR58pKnJgmeWPY9/wleReRbZ2MOZRyd"
          ];
          system.stateVersion = "23.11";
        })
      ];
    };
  };
}
