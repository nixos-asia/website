# Installing fonts using home-manager

Whether you are on #[[macos|macOS]] or [[nixos|NixOS]], you can install and setup fonts in an unified fashion with [[nix|Nix]] using #[[home-manager|home-manager]].

For e.g., to install the [Cascadia Code][cascadia] font:

```nix
{
  home.packages = [
    # Fonts
    cascadia-code
  ];

  fonts.fontconfig.enable = true;
}
```

See [this issue](https://github.com/nix-community/home-manager/issues/605) for details.

## Verify on macOS {#macos}

To confirm that the font was successfully installed on [[macos]], you can open the [Font Book][font-book] app and search for the font. They will have been installed into `~/Library/Fonts/HomeManager` folder. 

[cascadia]: https://x.com/dhh/status/1791920107637354964
[font-book]: https://support.apple.com/en-ca/guide/font-book/welcome/mac
