{
  perSystem = { config, pkgs, self', ... }: {
    haskellProjects.default = {
      projectRoot = ./.;
      autoWire = [ "packages" "checks" "apps" ];
    };

    devShells.haskell = pkgs.mkShell {
      name = "hello-haskell";
      inputsFrom = [
        config.haskellProjects.default.outputs.devShell
      ];
    };
  };
}
