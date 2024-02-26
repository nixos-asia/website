{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ⤵️ 4/flake.nix is specified as input here, to allow us to reuse its
    # outputs.
    flake4.url = "path:../4";
  };
  outputs = { self, nixpkgs, flake4 }:
    let
      # TODO: Change this to x86_64-linux if you are on Linux
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      # ⤵️ We import the library from 4/flake.nix
      lsdLib = flake4.mkLib pkgs;
    in
    {
      packages.${system} = {
        # ⤵️ And use it here.
        default = lsdLib.lsdFor {
          imports = [ lsdLib.common ];
          lsd.dir = "/";
        };
        home = lsdLib.lsdFor {
          lsd.dir = "$HOME";
        };
        downloads = lsdLib.lsdFor {
          lsd = {
            dir = "$HOME/Downloads";
            tree = true;
          };
        };
      };
    };
}
