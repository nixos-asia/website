{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      # TODO: Change this to x86_64-linux if you are on Linux
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.writeShellApplication {
        name = "list-contents";
        runtimeInputs = [ pkgs.lsd ];
        text = ''
          lsd -l /
        '';
      };
    };
}
