{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.oneclick = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./disk-config.nix
        disko.nixosModules.disko
        ({ pkgs, ... }: {
          environment.systemPackages = [ pkgs.htop ];
          system.stateVersion = "23.11";
        })
      ];
    };
  };
}
