---
order: -1000
---

# Install Nix


>[!info] Linux
> If you prefer to use Linux, you may be interested in [[nixos-tutorial|installing NixOS]]. The following instructions are for users of other Linux distros as well as [[macos|macOS]].

Install #[[nix]] using [the unofficial installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):[^official]

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --extra-conf "trusted-users = $(whoami)"
```

After installing Nix, open a new terminal and run the [Nix Health](https://github.com/juspay/nix-health) checks,

```sh
nix --accept-flake-config run github:juspay/omnix health
```

Expect to see all results in either green (or yellow).

## Next Steps

Checkout [[nix-first]] and 

- [[dev]] if you are looking to use Nix for development.
- [[home-manager]] (and [[nix-darwin]] if you are on [[macos]]) if you would like to use Nix for more than packages and [[dev|devShells]].

[^official]: You *can* use [the official installer](https://nixos.org/download). However, there are a couple of manual steps necessary:
    - As it [does not yet](https://discourse.nixos.org/t/anyone-up-for-picking-at-some-nix-onboarding-improvements/13152/4) include an uninstaller, you will have to manually uninstall Nix when the time comes ([[macos-upgrade|example]]). 
    - As it does not automatically enable [[flakes]], you will have to [manually enable it](https://nixos.wiki/wiki/Flakes).
