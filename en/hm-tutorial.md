---
order: 2
page:
  title: Home Manager Tutorial
---

# Home Manager Tutorial

In the [[nix-first|previous tutorial]], we learned how to use `nix` commands ad-hoc. In this tutorial, we will learn how to manage our user environment *declaratively* using [Home Manager](https://github.com/nix-community/home-manager).

We will build a configuration from scratch that provides a modern terminal experience, including:
- **Git**: Version control with aliases and smart defaults.
- **Starship**: A fast, customizable shell prompt.
- **Zsh**: Enhanced shell with autosuggestions and syntax highlighting.
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

> [!tip] Architecture
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

Let's configure Git with useful aliases and defaults. Add this to `home.nix`:

```nix
  # Shell aliases for Git
  home.shellAliases = {
    g = "git";
    lg = "lazygit";
  };

  programs.git = {
    enable = true;
    userName  = "Your Name";
    userEmail = "your-email@example.com";
    
    # Files to ignore globally
    ignores = [ "*~" "*.swp" ];
    
    # Git command aliases
    aliases = {
      ci = "commit";
    };
  };
  
  # Terminal UI for Git
  programs.lazygit.enable = true;
```

Now you can type `g status` instead of `git status`, and `lg` to launch lazygit!

## Shell Prompt (Starship)

[Starship](https://starship.rs/) provides a fast, customizable prompt that shows git status, directory, and more.

```nix
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
    };
  };
```

## Shell Enhancements

Make your shell more powerful with autosuggestions, syntax highlighting, and smart directory jumping.

```nix
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
  };
  
  # Smart directory jumping - type `z <pattern>` instead of `cd`
  programs.zoxide.enable = true;
```

> [!tip] Zoxide
> After using `cd` to directories a few times, zoxide learns them. Then you can jump with `z docs` instead of `cd ~/projects/my-app/docs`.

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

## Essential Programs

Home Manager has native support for many programs via `programs.*`. These provide better integration than just installing via `home.packages`.

```nix
  programs = {
    # Better cat with syntax highlighting
    bat.enable = true;
    
    # Fuzzy finder - press Ctrl+R to search shell history
    fzf.enable = true;
    
    # JSON processor
    jq.enable = true;
    
    # Beautiful system monitor
    btop.enable = true;
  };
```

## Additional Tools

For packages without native Home Manager support, use `home.packages`:

```nix
  home.packages = with pkgs; [
    # Unix tools
    ripgrep  # Better grep
    fd       # Better find  
    sd       # Better sed
    tree     # Directory visualization
    
    # Nix tools
    omnix    # Nix workflow helper
  ];
```

## Maintenance (Garbage Collection)

Automatically clean up old generations to save disk space.

```nix
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 30d";
  };
```

## Advanced: Run without installing

If you want to run any package without installing it using `, cowsay`, you can set up `comma` with `nix-index`.

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
  programs.nix-index-database.comma.enable = true;
```

Now you can run: `, cowsay "Hello!"`

## Summary

You have now built a declarative user environment from scratch!

- `flake.nix`: Pins dependencies.
- `home.nix`: Describes configuration.

Your setup now includes:
- Git with aliases and lazygit
- Starship prompt
- Zsh with autosuggestions  
- Zoxide for smart navigation
- Direnv for project environments
- Essential CLI tools (bat, fzf, ripgrep, etc.)
- Automatic garbage collection

Next, you might want to look at managing your entire system with [[nixos-tutorial|NixOS]].
