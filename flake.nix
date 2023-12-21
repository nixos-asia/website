{
  nixConfig = {
    extra-substituters = "https://srid.cachix.org";
    extra-trusted-public-keys = "srid.cachix.org-1:3clnql5gjbJNEvhA/WQp7nrZlBptwpXnUk6JAv8aB2M=";
  };

  inputs = {
    emanote.url = "github:srid/emanote/folgezettel-sidebar"; # https://github.com/srid/emanote/pull/483
    nixpkgs.follows = "emanote/nixpkgs";
    flake-parts.follows = "emanote/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.emanote.flakeModule ];
      perSystem = { self', pkgs, system, ... }: {
        emanote = {
          # By default, the 'emanote' flake input is used.
          # package = inputs.emanote.packages.${system}.default;
          sites."default" = {
            layers = [ ./. ];
            layersString = [ "." ];
            port = 7788;
            prettyUrls = true;
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
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
