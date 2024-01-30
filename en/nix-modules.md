---
order: 3
---

# Understanding Nix modules

Learning to work with the [[modules|module system]] in [[nixpkgs|nixpkgs]] is a big stepping stone to writing easy to maintain and shareable Nix code. We will focus on that in this tutorial -- by understanding how to use `evalModules` from [[nixpkgs|nixpkgs]] to define and use our own modules. The next tutorial in this series will talk about how to do that using `flake-parts` for writing [[flakes|flakes]] and sharing the modules with others flakes. 

## A simple example

Consider the following Nix code, defined in a [[flakes|flake]]:

![[nix-modules/1/flake.nix]]

This is a simple flake that exposes a package that can be `nix run`ed to list the contents of the root directory. Now let's say we want to create many such packages, each with a slight difference. 

For example, 
- we want to create a package that when run will *list a different directory*. 
- Or another package that will *show a tree view rather than a linear list*. 

We can refactor our Nix expression to be a function that takes arguments for these variations:

![[nix-modules/2/flake.nix]]

The `lsdFor` returns a `lsd` wrapper package that behaves in accordance with the arguments we pass to it. The flake outputs three packages, including one for listing the user's home directory as well as their "Downloads" folder as a tree view.

Our flake is simple enough that it strictly doesn't require further refactoring. But on larger functions, having functions peppered throughout the project can be rather difficult to entangle. To this end, we'll see how to refactor the above to use the module system, and in the process we'll add more configurability to our `lsd` wrapper.

## Introducing the module system

A Nix module is a specification of various "options". When the user "import"s this module, they can specify values for these options. The module implementation (ie., the "config" attribute") will then use these values to produce the final expression to substitute in call site where the module gets imported. This is a mouthful, so let's get down the concrete details. To port our example, we need to define two options: `dir`, and `tree`. Moreover, we also need an attrset option that will allow us to specify the list of packages to put (`default`, `home`, `downloads`).

Here's our lsd module, defined in `lsd.nix` alongside the flake:

```nix
# lsd.nix
{ pkgs, lib, config, ... }:
{
  # The interface
  options = {
    lsd = lib.mkOption {
      type = lib.types.submodule {
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
      };
    };
  };

  # The implementation
  config = {
    packages.${pkgs.system} = lib.mapAttrs (name: cfg: 
      pkgs.writeShellApplication {
        name = "list-contents-${name}";
        runtimeInputs = [ pkgs.lsd ];
        text = ''
          lsd ${if cfg.tree then "--tree" else ""} "${cfg.dir}"
        '';
      }
    ) config.lsd;
  };
}
```

Let's use this from the [[repl]]:

```sh
❯ nix repl
Welcome to Nix 2.19.2. Type :? for help.

nix-repl> :lf nixpkgs
Added 15 variables.

nix-repl> pkgs = legacyPackages.aarch64-darwin

nix-repl> lib = pkgs.libpkgs

nix-repl> res = lib.evalModules { modules = [ ./lsd.nix { lsd.home.dir = "$HOME"; } ]; specialArgs = { inherit pkgs; }; }

nix-repl> res.config.packages
{ home = «derivation /nix/store/qaq05x83k92gh34a458ripv5hjs5wimk-list-contents-home.drv»; }

nix-repl> res.config.packages.home
«derivation /nix/store/qaq05x83k92gh34a458ripv5hjs5wimk-list-contents-home.drv»

nix-repl> :b res.config.packages.home

This derivation produced the following outputs:
  out -> /nix/store/acpkhiv6qsblpdkgqfjjgd46lh6cjw23-list-contents-home
```