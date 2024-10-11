---
short-title: 2. Using flake-parts
---

# Modularize our flake using flake-parts

>[!warning] TODO: Write this! 
> For now, see the code: https://github.com/juspay/todo-app/pull/9

Things to highlight:

- [[flake-parts]] can be used as lightweight `forAllSystems` alternative
- allows us to split top-level flake.nix into small .nix files
- allows us to define [[nix-modules|our own modules]] and use them (just like [[nixos]] options)
- nuts and bolts:
  - perSystem, and its args (`self'`, etc.)
  - `debug` option and inspecting in repl
