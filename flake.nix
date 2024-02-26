{
  nixConfig = {
    extra-substituters = "https://cache.garnix.io";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
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
                basePath = name;
              })
              langs;
          };
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
            ];
          };
          packages = rec {
            indexPage = pkgs.writeTextDir
              "index.html"
              ''
                <html>
                  <head>
                    <meta charset="utf-8" />
                    <title>Welcome to NixOS Asia</title>
                    <!-- meta http-equiv="refresh" content="0; URL=/en" /-->
                  </head>
                  <body>
                    <!--  TODO: Lang selector? -->
                    <div style="margin-top: 2em; text-align: center; font-size: 2em;">
                      <a href="/en">English</a> | <a href="/fr">Français</a>
                    </div>
                  </body>
                </html>
              '';
            site = pkgs.symlinkJoin {
              name = "nixos-asia-site";
              paths = [ indexPage ] ++ lib.mapAttrsToList
                (name: _: self'.packages.${name})
                langs;
            };
            default = site;
          };
          apps.preview.program = pkgs.writeShellApplication {
            name = "emanote-static-preview";
            runtimeInputs = [ pkgs.static-web-server ];
            text = ''
              set -x
              static-web-server -d ${self'.packages.default} "$@"
            '';
          };
          apps.default.program = self'.apps.en.program; # Alias to English site
          formatter = pkgs.nixpkgs-fmt;
        };
      flake.nixci.default = {
        nix-modules-1.dir = ./global/nix-modules/1;
        nix-modules-2.dir = ./global/nix-modules/2;
        nix-modules-3.dir = ./global/nix-modules/3;
        nix-modules-4.dir = ./global/nix-modules/4;
        nix-modules-5.dir = ./global/nix-modules/5;
      };
    };
}
