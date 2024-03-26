{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }: {
    # A bare NixOS configuration that can be ssh'ed to as root, with known password
    # For testing/demo purposes only.
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
          };
          networking.hostName = "oneclick";
          services.openssh.enable = true;

          # Add your key here
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQRxPoqlThDrkR58pKnJgmeWPY9/wleReRbZ2MOZRyd";
          ];

          system.stateVersion = "23.11";
        })
      ];
    };
  };
}
