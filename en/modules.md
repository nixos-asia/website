# Module System

The #[[nixpkgs]] library provides a module system for [[nix]] expressions. See https://nixos.wiki/wiki/NixOS_modules for a detailed explanation.

## NixOS

[[nixos]] makes use of the module system to provide various functionality including services and programs. See https://search.nixos.org/options for a list of all available options.

## Flakes

This module system is not natively supported in [[flakes]]. However, flakes can define and use modules using [[flake-parts]].

## Links

- [Zero to Nix: Modules](https://zero-to-nix.com/concepts/nixos#modules)
