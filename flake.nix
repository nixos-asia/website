{
  nixConfig = {
    extra-substituters = "https://srid.cachix.org";
    extra-trusted-public-keys = "srid.cachix.org-1:3clnql5gjbJNEvhA/WQp7nrZlBptwpXnUk6JAv8aB2M=";
  };

  inputs = {
    emanote.url = "github:srid/emanote";
    nixpkgs.follows = "emanote/nixpkgs";
    flake-parts.follows = "emanote/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.emanote.flakeModule ];
      perSystem = { self', pkgs, lib, system, ... }:
        let
          langs = {
            en = { path = ./en; port = 7788; };
            fr = { path = ./fr; port = 7789; };
          };
        in
        {
          emanote = {
            sites = lib.mapAttrs
              (name: lang: {
                inherit (lang) port;
                layers = [ lang.path ./global ];
                layersString = [ name "global" ];
                prettyUrls = true;
                baseUrl = "/${name}/";
              })
              langs;
          };
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
            ];
          };
          packages.default = pkgs.runCommand "nixos-asia-site-all-langs"
            {
              buildInputs = [ ];
            } ''
            # TODO: Generalize this by iterating over `langs` list.
            mkdir -p $out/{en,fr}
            cp -r ${self'.packages.en}/* $out/en/
            cp -r ${self'.packages.fr}/* $out/fr/
            # TODO: Write index.html
          '';
          apps.preview.program = pkgs.writeShellApplication {
            name = "emanote-preview";
            runtimeInputs = [ pkgs.nodePackages.http-server ];
            text = ''
              set -x
              http-server ${self'.packages.default} "$@"
            '';
          };
          formatter = pkgs.nixpkgs-fmt;
        };
    };
}
