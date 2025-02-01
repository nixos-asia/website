
# Flake URL

A #[[flakes|flake]] can be referred to using an URL-like syntax.

## Examples

```sh
# A flake on a GitHub repo
github:srid/emanote

# A local flake at current directory
.

# Another way to refer to local flakes
path:/Users/srid/code/foo

# Full Git references is also possible:
git+https://github.com/juspay/services-flake?ref=dev
```

## Reference

- The URL-like syntax is documented [here](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#url-like-syntax).
