# Uninstall Nix

1. Run `/nix/nix-installer uninstall`
    - NOTE: If that path above does not exist, [follow these instructions](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos) to manually uninstall Nix.
1. Reboot

>[!note] Problems while deleting `Nix Store` volume on macOS
> If the installer fails to delete the `/nix/store` volume, try rebooting your mac
> and running `/nix/nix-installer uninstall` again. If that path doesn't exist, delete manually by following last step from [here](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos).

