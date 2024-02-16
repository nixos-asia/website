{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ⤵️ flake4 is specified as input
    flake4.url = "path:../4";
  };
  outputs = { self, nixpkgs, flake4 }:
    let
      # TODO: Change this to x86_64-linux if you are on Linux
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      lsdFor = settings:
        let
          result = lib.evalModules {
            modules = [
              # ⤵️ We import flake4's module directly here, by file path.
              (flake4 + /lsd.nix)
              # ⤵️ We can also reference the module directly.
              flake4.common
              settings
            ];
            specialArgs = { inherit pkgs; };
          };
        in
        result.config.lsd.package;
    in
    {
      packages.${system} = {
        default = lsdFor {
          lsd.dir = "/";
        };
        home = lsdFor {
          lsd.dir = "$HOME";
        };
        downloads = lsdFor {
          lsd = {
            dir = "$HOME/Downloads";
            tree = true;
          };
        };
      };
    };
}
