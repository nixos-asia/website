# Installing fonts using home-manager

Whethere you are on #[[macos|macOS]] or [[nixos|NixOS]], you can install and setup fonts in an unified fashion with [[nix|Nix]] using #[[home-manager|home-manager]].

To do this, add:

```nix
{
  home.packages = [
    # Fonts
    cascadia-code
  ];

  fonts.fontconfig.enable = true;
}
```

The above installs the [Cascadia Code](https://x.com/dhh/status/1791920107637354964) font. See [this issue](https://github.com/nix-community/home-manager/issues/605) for details.

>[!tip] Verify on macOS
> To confirm that the font was successfully installed on [[macos]], you can open the "Font Book" app and search for the font. They will have been installed into `$HOME/Library/Fonts/HomeManager` folder. 
