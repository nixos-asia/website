{ pkgs, lib, config, ... }:
{
  # The interface
  options = {
    lsd = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        options = {
          dir = lib.mkOption {
            type = lib.types.str;
            default = "/";
            description = "The directory to list";
          };
          tree = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to show a tree view";
          };
          long = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to show a long view";
          };
          package = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
          };
        };
      };
    };
  };

  # The implementation
  config =
    let
      cfg = config.lsd;
    in
    {
      lsd.package =
        pkgs.writeShellApplication {
          name = "list-contents";
          runtimeInputs = [ pkgs.lsd ];
          text = ''
            lsd ${if cfg.tree then "--tree" else ""} ${if cfg.long then "-l" else ""} "${cfg.dir}"
          '';
        };
    };
}
