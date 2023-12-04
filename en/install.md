# Install Nix

Install Nix using [the DeterminateSystems installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Before proceeding, run [Nix Health](https://flakular.in/health),

```sh
nix run nixpkgs#nix-health
```
