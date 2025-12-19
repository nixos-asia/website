-- Pipeline configuration for Vira <https://vira.nixos.asia/>

\ctx pipeline ->
  let
    isMaster = ctx.branch == "master"
  in
  pipeline
    { build.flakes =
        [ "."
        , "./global/nix-modules/1"
        , "./global/nix-modules/2"
        , "./global/nix-modules/3"
        , "./global/nix-modules/4"
        , "./global/nix-modules/5" { overrideInputs = [("flake4", "./global/nix-modules/4")] }
        ]
    , signoff.enable = True
    }
