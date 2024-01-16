---
order: -1000
---

# Install Nix


>[!info] Linux
> If you prefer to use Linux, you may be interested in installing [[nixos]]. The following instructions are for users of other Linux distros as well as [[macos]].

Install #[[nix]] using [the unofficial installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):[^official]

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> [!tip] Graphical installer for [[macos]]
> The unofficial installer is also available as a graphical installer for [[macos]]. You can get get it [here](https://determinate.systems/posts/graphical-nix-installer).

After installing Nix, run the [Nix Health](https://github.com/juspay/nix-browser/tree/main/crates/nix_health) checks,

```sh
nix run nixpkgs#nix-health
```

Expect to see all results in either green (or yellow).

## Next Steps

Checkout [[nix-first]] and 

- [[dev]] if you are looking to use Nix for development.
- [[home-manager]] (and [[nix-darwin]] if you are on [[macos]]) if you would like to use Nix for more than packages and [[dev|devShells]].

[^official]: You *can* use [the official installer](https://nixos.org/download). However, there are a couple of manual steps necessary:
    - As it [does not yet](https://discourse.nixos.org/t/anyone-up-for-picking-at-some-nix-onboarding-improvements/13152/4) include an uninstaller, you will have to manually uninstall Nix when the time comes ([[macos-upgrade|example]]). 
    - As it does not automatically enable [[flakes]], you will have to [manually enable it](https://nixos.wiki/wiki/Flakes).