---
order: 2
---

# Declarative User Environments with Home Manager

In the [[nix-first|previous tutorial]], we learned how to use `nix` commands ad-hoc. We even installed packages with `nix profile install`. But there's a better way.

**The problem with imperative installs**: If you run `nix profile install nixpkgs#cowsay` today and set up a new machine tomorrow, you'll have to remember every package you installed. Your environment isn't reproducible.

**The declarative approach**: With #[[home-manager]], you describe your entire environment in a configuration file. Want to set up a new machine? Just copy your config and run one command. Everything is reproducible and version-controlled.

We will build a configuration from scratch that provides a modern terminal experience, including:
- **Git**: Version control with aliases and smart defaults.
- **Starship**: A fast, customizable shell prompt.
- **Zsh**: Enhanced shell with autosuggestions and syntax highlighting.
- **Direnv**: Automatic environment loading for your projects.

## Initial Setup

We will use [[flakes|Nix Flakes]] to configure Home Manager.

First, create the configuration directory:

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
```

Now create two files in this directory.

### 1. `flake.nix`

This file defines your inputs (dependencies) and outputs (configurations).

> [!note] Understanding the syntax
> If you want to learn about `flake.nix` structure and Nix language syntax, see the [[nix-rapid|Rapid Introduction to Nix]] tutorial.

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
      system = "aarch64-darwin"; # Change if not on Apple Silicon Mac
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."YOUR_USERNAME" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
```

> [!tip] Architecture
> Update the `system` variable to match your machine:
> - macOS (Apple Silicon): `aarch64-darwin`
> - macOS (Intel): `x86_64-darwin`
> - Linux: `x86_64-linux`
> 
> Replace `YOUR_USERNAME` with your actual username (run `whoami` to check).

### 2. `home.nix`

This file contains your actual configuration. Start with:

```nix
{ config, pkgs, ... }:

{
  # TODO: Change these to your actual username and home directory
  home.username = "YOUR_USERNAME";
  home.homeDirectory = "/Users/YOUR_USERNAME";

  # Don't change this after initial setup
  home.stateVersion = "25.05"; 

  # Ensure Nix binaries are in PATH
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # macOS uses Zsh by default, so we configure it here
  programs.zsh.enable = true;
}
```

> [!tip] Linux users
> If you use Bash instead of Zsh, replace `programs.zsh.enable` with `programs.bash.enable` throughout this tutorial.

### Apply configuration

Activate your configuration:

```bash
nix run home-manager/master -- switch
```

> [!note] What to expect
> The first run downloads Home Manager and builds your configuration. This may take a few minutes. You should see output ending with something like:
> ```
> Activating home-manager configuration for YOUR_USERNAME
> ...
> ```

**Important**: After activation, open a new terminal for changes to take effect.

From now on, whenever you modify your configuration, run:

```bash
home-manager switch
```

## Configure Git {#git}

Add the following inside the `{ ... }` block in `home.nix`, after `programs.home-manager.enable = true;`:

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
    ignores = [ "*~" "*.swp" ".DS_Store" ];
    aliases = {
      ci = "commit";
    };
  };
  
  # Terminal UI for Git
  programs.lazygit.enable = true;
```

Run `home-manager switch` and open a new terminal. Now `g status` works as `git status`!

## Shell Prompt (Starship) {#starship}

[Starship](https://starship.rs/) provides a fast, customizable prompt that shows git status, directory, and more.

Add to `home.nix`:

```nix
  programs.starship = {
    enable = true;
    settings = {
      # add_newline = false;
      gcloud.disabled = true;
    };
  };
```

After switching and opening a new terminal, your prompt will look different—showing your directory and git branch.

## Shell Enhancements {#shell}

We already enabled Zsh in the initial setup. Now let's enhance it with autosuggestions and syntax highlighting.

Add to `home.nix`:

```nix
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
  
  # Smart directory jumping - type `z <pattern>` instead of `cd`
  programs.zoxide.enable = true;
```

> [!tip] Zoxide
> After using `cd` to directories a few times, zoxide learns them. Then you can jump with `z docs` instead of `cd ~/projects/my-app/docs`.

## Smart Environments (Direnv) {#direnv}

[[direnv|Direnv]] loads environment variables automatically when you `cd` into directories. This is essential for Nix-based development.

Add to `home.nix`:

```nix
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
```

Now when you enter a project with a `flake.nix` and `.envrc` file containing `use flake`, the development environment loads automatically.

## Essential Programs {#programs}

Home Manager has [native support for many programs](https://github.com/nix-community/home-manager/tree/master/modules/programs) via `programs.*`. These modules don't just install the package—they also configure it, set up shell integration, and manage dotfiles. For example, `programs.fzf.enable` automatically adds keybindings to your shell.

Add to `home.nix`:

```nix
  programs = {
    # Better cat with syntax highlighting
    bat.enable = true;
    
    # Fuzzy finder - press Ctrl+R to search shell history
    fzf.enable = true;
    
    # JSON processor
    jq.enable = true;
    
    # System monitor
    btop.enable = true;
  };
```

## Additional Tools {#packages}

For packages without native Home Manager support, use `home.packages`. You can [search for packages here](https://search.nixos.org/packages). Add to `home.nix`:

```nix
  home.packages = with pkgs; [
    ripgrep  # Better grep
    fd       # Better find  
    sd       # Better sed
    tree     # Directory visualization
  ];
```

## Maintenance (Garbage Collection) {#gc}

Nix keeps old versions of your configuration (for rollbacks) and caches project devShells. Over time, this uses disk space. Enable automatic cleanup—don't worry, `nix-direnv` pins your active project shells so they won't be deleted:

```nix
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
```

## Complete Example

Here's a complete `home.nix` with everything we've covered:

```nix
{ config, pkgs, ... }:

{
  home.username = "YOUR_USERNAME";
  home.homeDirectory = "/Users/YOUR_USERNAME";
  home.stateVersion = "25.05";
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  programs.home-manager.enable = true;

  # Git
  home.shellAliases = {
    g = "git";
    lg = "lazygit";
  };
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your-email@example.com";
    ignores = [ "*~" "*.swp" ".DS_Store" ];
    aliases.ci = "commit";
  };
  programs.lazygit.enable = true;

  # Shell
  programs.starship = {
    enable = true;
    settings = {
      gcloud.disabled = true;
    };
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
  programs.zoxide.enable = true;

  # Development
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Tools
  programs.bat.enable = true;
  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.btop.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    sd
    tree
  ];

  # Maintenance
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}
```

## What's Next

- Explore more options: Run `man home-configuration.nix` or browse the [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- Version control: Initialize a git repository in `~/.config/home-manager` to track your configuration changes
- [[nixos-tutorial|NixOS]]: Manage your entire operating system with Nix
- [nixos-unified-template](https://github.com/juspay/nixos-unified-template): a fully-fledged home-manager template that configures what this tutorial shows, and more. It also supports NixOS.

## Advanced: Run without installing

Want to run any package without installing it? Set up [`comma`](https://github.com/nix-community/comma) to run commands like `, cowsay "Hello!"`.

Create this complete `flake.nix`:

```nix
{
  description = "My Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, nix-index-database, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."YOUR_USERNAME" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          nix-index-database.hmModules.nix-index
        ];
      };
    };
}
```

Add to `home.nix`:

```nix
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
```

Now `, cowsay "Hello!"` downloads and runs cowsay without installing it permanently.
