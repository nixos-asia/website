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
    in
    {
      packages.${system} = {
        default = lsdFor { lsd.dir = "/"; };
        home = lsdFor { lsd.dir = "$HOME"; };
        downloads = lsdFor { lsd.dir = "$HOME/Downloads"; lsd.tree = true; };
      };
    };
}
