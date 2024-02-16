# `writeShellApplication`

The recommended way to create [[drv]] using shell scripts.

https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellApplication

- The function generates a [[drv]] for a shell script specified as the value for `text` attribute. 
- `runtimeInputs`: packages to be made available to the shell application's PATH.
- Uses [shellcheck](https://github.com/koalaman/shellcheck) to statically analyze your bash script for issues.