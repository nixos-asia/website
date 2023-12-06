
# Nix's sqlite database is corrupted/broken

If [[nix]] throws an error like:

```text
error: getting status of '/nix/store/....drv': No such file or directory
```

You can try to fix it by running:

```sh
nix-store --verify --repair
```