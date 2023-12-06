# Install Nix

Install #[[nix]] using [the unofficial installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):[^official]

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

After installing Nix, run the [Nix Health](https://github.com/juspay/nix-browser/tree/main/crates/nix_health) checks,

```sh
nix run nixpkgs#nix-health
```

Expect to see all results in either green (or yellow).

[^official]: You *can* use [the official installer](https://nixos.org/download). However, there are a couple of manual steps necessary:
    - As it [does not yet](https://discourse.nixos.org/t/anyone-up-for-picking-at-some-nix-onboarding-improvements/13152/4) include an uninstaller, you will have to manually uninstall Nix when the time comes ([[macos-upgrade|example]]). 
    - As it does not automatically enable [[flakes]], you will have to [manually enable it](https://nixos.wiki/wiki/Flakes).