# A module can be an attrset, or a function returning an attrset.
#
# Our module here is of the latter kind. By default, certain arguments are
# automatically passed. You can specify additional arguments in `_module.args`.
{ pkgs, lib, config, ... }:
{
  # A module's "interface" is defined in `options`.
  options = {
    # The `lsd` option is of type sub-module; meaning, it can contain further
    # options and config.
    lsd = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        options = {
          # The `dir` option is of type string.
          #
          # If the user doesn't set it, its default value of "/" is used.
          dir = lib.mkOption {
            type = lib.types.str;
            default = "/";
            description = "The directory to list";
          };
          # The `tree` option is of type boolean.
          tree = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to show a tree view";
          };
          # The `package` option is of type package.
          #
          # It is not user-settable, hence `readOnly = true`. The value will be
          # set in the `config` implementation below.
          package = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
          };
        };
      };
    };
  };

  # A module's "implementation" is defined in `config`.
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
            lsd ${if cfg.tree then "--tree" else ""} "${cfg.dir}"
          '';
        };
    };
}
