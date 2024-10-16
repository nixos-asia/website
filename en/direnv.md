# `direnv`: manage dev environments

`direnv` (along with [nix-direnv]) allows one to persist[^gc] nix #[[dev|development]] [[shell|shell]] environments and share them seamlessly with text editors and IDEs. It obviates having to run `nix develop` manually every time you open a new terminal. The moment you `cd` into your project directory, the devshell is automatically activated, thanks to `direnv`. 

[^gc]: [nix-direnv] prevents garbage collection of the devshell, so you do not have to re-download things again. direnv also enables activating the devshell in your current shell, without needing to use a customized bash.

>[!tip] Starship
> It is recommended to use [**starship**](https://starship.rs/) along with nix-direnv, because it gives a visual indication of the current environment. For example, if you are in a [[shell]], your terminal prompt automatically changes to something like this:
>
> ```sh
> srid on nixos haskell-template on  master [!] via λ 9.2.6 via ❄️  impure (ghc-shell-for-haskell-template-0.1.0.0-0-env)
> ❯
> ```

## Setup 

:::{class="flex items-center justify-center mb-8"}
<iframe width="560" height="315" src="https://www.youtube.com/embed/1joZLTgYLxY?si=ljZLcFAIhrJ7XawV" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
:::




If you use [[home-manager]], both `nix-direnv` and `starship` can be installed using the following configuration:

```nix
# home.nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
programs.starship = {
  enable = true;
};
```

>[!tip] Newcomer Tip
> If you have never used [[home-manager]] before, we recommend that you set it up by following the instrutions at https://github.com/juspay/nixos-unified-template (which is based on [nixos-unified](https://nixos-unified.org/), thus works on macOS and Linux).


### Text Editor configuration

#### VSCode

For VSCode, use [Martin Kühl's direnv extension](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv).

#### Doom Emacs

Doom Emacs has the [`:tools` `direnv` module](https://github.com/doomemacs/doomemacs/tree/master/modules/tools/direnv) to automatically load the devshell environment when you open the project directory.

## Add a `.envrc`

To enable direnv on Flake-based projects, add the following to your `.envrc`:

```text title=".envrc"
use flake
```

Now run `direnv allow` to authorize the current `.envrc` file. You can now `cd` into the project directory in a terminal and the devshell will be automatically activated.

### Reload automatically when some files change

#### [[haskell]] - when `.cabal` files change

Since both [[nixify-haskell-nixpkgs|nixpkgs]] and [haskell-flake](https://community.flake.parts/haskell-flake) use Nix expressions that read the `.cabal` file to get dependency information, you will want the devshell be recreated every time a `.cabal` file changes. This can be achieved using the `watch_file` function. Modify your `.envrc` to contain:

```text title=".envrc"
watch_file *.cabal
use flake
```

As a result of this whenever you change a `.cabal` file, direnv will reload the environment. If you are using VSCode, you will see a notification that the environment has changed, prompting you to restart it ([see example](https://github.com/nammayatri/nammayatri/tree/main/Backend#visual-studio-code)).

## External Links

- [Effortless dev environments with Nix and direnv](https://determinate.systems/posts/nix-direnv)

[nix-direnv]: https://github.com/nix-community/nix-direnv
[home-manager]: https://github.com/nix-community/home-manager
