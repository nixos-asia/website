# `buildRustPackage`

See official documentation on this function [here](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md).

{#override}
## Overriding Rust derivation

Due to the complexity of `buildRustPackage` you cannot *merely* use `overrideAttrs` to override a Rust derivation. For version changes in particular, you must also override the `cargoDeps` attribute ([see here](https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3)).

For example, to override `pkgs.just` to [a later release][just-zulip], 


```nix
self: super: {
  just = super.just.overrideAttrs (oa: rec {
    name = "${oa.pname}-${version}";
    version = "1.27.0";
    src = super.fetchFromGitHub {
      owner = "casey";
      repo = oa.pname;
      rev = "refs/tags/${version}";
      hash = "sha256-xyiIAw8PGMgYPtnnzSExcOgwG64HqC9TbBMTKQVG97k=";
    };
    # Overriding `cargoHash` has no effect; we must override the resultant
    # `cargoDeps` and set the hash in its `outputHash` attribute.
    cargoDeps = oa.cargoDeps.overrideAttrs (super.lib.const {
      name = "${name}-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-jMurOCr9On+sudgCzIBrPHF+6jCE/6dj5E106cAL2qw=";
    });

    doCheck = false;
  });
}
```


[just-zulip]: https://nixos.zulipchat.com/#narrow/stream/420166-offtopic/topic/just.20recipe.20grouping/near/440732100