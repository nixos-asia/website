# Reinstall Nix

1. Reboot your system (to ensure that none of the processes are using the `/nix/store` volume)
1. Uninstall Nix:
    - Run `/nix/nix-installer uninstall`
    - If that path above does not exist, [follow these instructions](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos) to manually uninstall Nix.
3. [[install]]