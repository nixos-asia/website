# Copying packages to a remote Nix store

This is useful if your local machine is powerful and you have built a number of
packages on it, but want to re-use them on another machine, without using a Nix
cache or rebuilding them.

```sh
nix copy --to ssh-ng://admin@100.96.121.13 /nix/store/???
```

If you use [nixci], this looks like:

```sh
nixci . -- --option system aarch64-linux | xargs nix copy --to ssh-ng://admin@100.96.121.13
```

[nixci]: https://github.com/srid/nixci
