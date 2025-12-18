---
order: 2
page:
  title: Home Manager Tutorial
---

# Home Manager Tutorial

In the [[nix-first|previous tutorial]], we learned how to use `nix` commands ad-hoc. In this tutorial, we will learn how to manage our user environment *declaratively* using [Home Manager](https://github.com/nix-community/home-manager).

We will build a configuration from scratch that provides a modern terminal experience, including:
- **Git**: Version control configuration.
- **Starship**: A fast, customizable shell prompt.
- **Direnv**: Automatic environment loading for your projects.

## Initial Setup

We will use [[flakes|Nix Flakes]] to configure Home Manager.

Create a new configuration directory (e.g., `~/.config/home-manager`) and create the following two files.

### 1. `flake.nix`

This file defines your inputs (dependencies) and outputs (configurations).

```nix
{
  description = "My Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux"; # Change to "aarch64-darwin" for Mac
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
```

> [!important] Architecture
> Make sure to update the `system` variable above to match your machine!
> - Linux (Intel/AMD): `x86_64-linux`
> - macOS (Apple Silicon): `aarch64-darwin`
> - macOS (Intel): `x86_64-darwin`
> Also replace `"user"` in `homeConfigurations."user"` with your actual username.

### 2. `home.nix`

This file will contain your actual configuration.

```nix
{ config, pkgs, ... }:

{
  home.username = "user"; # Replace with your username
  home.homeDirectory = "/home/user"; # Replace with your home directory path

  home.stateVersion = "23.11"; 

  programs.home-manager.enable = true;
}
```

### Apply configuration

Activate the configuration by running this inside `~/.config/home-manager`:

```bash
nix run home-manager/master -- switch --flake .
```

After the first run, you can simply run:

```bash
home-manager switch --flake .
```

## Configure Git

Let's configure `git` declaratively. Add this to `home.nix`:

```nix
  programs.git = {
    enable = true;
    userName  = "Your Name";
    userEmail = "your-email@example.com";
  };
```

## Shell Configuration (Starship)

We will use [Starship](https://starship.rs/) for a cross-shell prompt. Add the following to `home.nix`:

```nix
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
```

## Smart Environments (Direnv)

[Direnv](https://direnv.net/) loads environment variables automatically when you `cd` into directories.

```nix
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
```

> [!tip] nix-direnv
> `nix-direnv` is a crucial plugin that makes direnv fast and compatible with Nix shells.

## Common Packages

Install your favorite tools by adding them to `home.packages`.

```nix
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    fzf
    just
  ];
```

## Maintenance (Garbage Collection)

To keep your disk usage low, you can tell Nix to automatically delete old versions of your profile.

```nix
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 30d";
  };
```

## Advanced: Run without installing

If you want to run any package without installing it (similar to `nix run`), but using a simple command like `, cowsay`, you can set up `comma` with `nix-index`.

First, update your `flake.nix` to include `nix-index-database`:

```nix
  inputs = {
    # ... other inputs
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, nix-index-database, ... }:
    # ...
    # inside homeConfigurations."user":
        modules = [
          ./home.nix
          nix-index-database.hmModules.nix-index
        ];
    # ...
```

Then, enable it in `home.nix`:

```nix
  programs.nix-index.enable = true;
  home.packages = [ pkgs.comma ];
```

Now you can run: `, cowsay "Hello!"`

## Summary

You have now built a declarative user environment from scratch!

- `flake.nix`: Pins dependencies.
- `home.nix`: Describes configuration.

Next, you might want to look at managing your entire system with [[nixos-tutorial|NixOS]].
