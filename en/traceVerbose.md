
# `traceVerbose`

[Nix 2.10](https://nixos.org/manual/nix/stable/release-notes/rl-2.10) introduced a new function, `builtins.traceVerbose`, that works like `builtins.trace` but is no-op until the user explicitly enables it.

For eg., running `nix build` will not cause `traceVerbose` to have any effect. But if you run `nix build --trace-verbose`, then logs from `traceVerbose` will be printed to the console.

## Examples

- haskell-flake uses this to [provide conditional logging](https://community.flake.parts/haskell-flake/debugging)

#[[tips]]