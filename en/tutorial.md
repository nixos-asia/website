---
order: -100
---

# Tutorials

- [[nix-rapid]]#
- [[nixos]] tutorial series
  - [[nixos-install-flake]]#
  - [ ] ...
- [[nixify-haskell]]

## Scratch

- Nix series
- Ext nixpkgs using `nix *`
    - `nix run`, `nix shell`, `nix profile install` (fn - hm)
      - eg: run redis (or lsd with yaml)
  - Rapid introduction to flakes
  - evalModules
    - Example 1: generate [redis.conf](https://redis.io/docs/management/config-file/) and returns drv with conf file only
      - consider cluster
    - Example 2: ... returns shell script that runs redis with that conf file
      - add `package = pkgs.redis`; output would include writeShellApplication derivaiton
    - ultimately, people can just `nix run` it.
  - flake-parts
- System series
  - NixOS ...
    - install
    - basics:
    - services:
  - home-manager ...
    - Basics: install, packages, dotfiles, ..
    - Advanced: run services (ubuntu + macos)
      - try with our redis above
      - show official redis module (if there's any)
- Dev series
  - Haskell series