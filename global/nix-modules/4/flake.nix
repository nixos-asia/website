{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      # TODO: Change this to x86_64-linux if you are on Linux
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      lsdFor = settings:
        let
          result = lib.evalModules {
            modules = [
              ./lsd.nix
              settings
            ];
            specialArgs = { inherit pkgs; };
          };
        in
        result.config.lsd.package;
      # ⤵️ A common module for re-use in other modules (see below)
      common = {
        lsd = {
          long = lib.mkDefault true;
        };
      };
    in
    {
      inherit common; # For use in 5/flake.nix
      packages.${system} = {
        default = lsdFor {
          # ⤵️ Here, we import the common module
          imports = [ common ];
          lsd.dir = "/";
        };
        home = lsdFor {
          # ⤵️ Here, we import the common module
          imports = [ common ];
          lsd.dir = "$HOME";
        };
        downloads = lsdFor {
          # ⤵️ Here, we import the common module
          imports = [ common ];
          lsd = {
            dir = "$HOME/Downloads";
            tree = true;
          };
        };
      };
    };
}
