{ 
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: 
    let
      # TODO: Change this to x86_64-linux if you are on Linux
      system = "aarch64-darwin"; 
      pkgs = nixpkgs.legacyPackages.${system};
      lsdFor = { dir, tree ? false }: pkgs.writeShellApplication {
        name = "list-contents";
        runtimeInputs = [ pkgs.lsd ];
        text = ''
          lsd ${if tree then "--tree" else ""} "${dir}"
        '';
      };
    in {
      packages.${system} = {
        default = lsdFor { dir = "/"; };
        home = lsdFor { dir = "$HOME"; };
        downloads = lsdFor { dir = "$HOME/Downloads"; tree = true; };
      };
    };
}
