# Install Nix

Install #[[nix]] using [the unofficial installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):[^official]

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Before proceeding, run [Nix Health](https://flakular.in/health),

```sh
nix run nixpkgs#nix-health
```

[^official]: You *may* use the official installer, but since it doesn't include an uninstaller, you will have to manually uninstall ([macOS instructions here](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos)) when the time comes. Also, the official installer will not automatically enable [[flakes]].