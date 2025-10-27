{
  inputs = {
    emanote.url = "github:srid/emanote/ui2025Oct";
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
                layers = [{ path = lang.path; pathString = name; } { path = ./global; pathString = "global"; }];
                prettyUrls = true;
                baseUrl = "/${name}/";
                basePath = name;
              })
              langs;
          };
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
              pkgs.nixd
              pkgs.just
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
    };
}
