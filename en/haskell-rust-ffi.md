# Rust FFI in Haskell

This #[[tutorial|tutorial]] will guide you through using [[nix]] to simplify the workflow of incorporating [[rust]] library as a dependency in your [[haskell]] project via [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface). If you are new to [[nix]] and [[flakes]], I recommend starting with the [[nix-tutorial]].

> [!info] Foreign Function Interface (FFI)
> This isn't solely restricted to Haskell and Rust, it can be used between any two languages that can establish a common ground to communicate, such as C.

The objective of this tutorial is to demonstrate calling a Rust function that returns `Hello, from rust!` from within a Haskell package. Let's begin by setting up the Rust library.

{#init-rust}
## Initialize Rust Project

Start by initializing a new Rust project using [rust-nix-template](https://github.com/srid/rust-nix-template):

```sh
git clone https://github.com/srid/rust-nix-template.git
cd rust-nix-template
```

Now, let's run the project:

```sh
nix develop
just run
```

{#rust-lib}
## Create a Rust Library

The template we've initialized is a binary project, but we need a library project. The library should export a function callable from Haskell. For simplicity, let's export a function named `hello` that returns a `C-style string`. To do so, create a new file named `src/lib.rs` with the following contents:

[[haskell-rust-ffi/lib.rs]]
![[haskell-rust-ffi/lib.rs]]

> [!info] Calling Rust code from C
> You can learn more about it [here](https://doc.rust-lang.org/nomicon/ffi.html#calling-rust-code-from-c).

Now, the library builds, but we need the dynamic library files required for FFI. To achieve this, let's add a `crate-type` to the `Cargo.toml`:

```toml
[lib]
crate-type = ["cdylib"]
```

After running `cargo build`, you should find a `librust_nix_template.dylib`[^hyphens-disallowed] (if you are on macOS) or `librust_nix_template.so` (if you are on Linux) in the `target/debug` directory.

[^hyphens-disallowed]: Note that the hyphens are disallowed in the library name; hence it's named `librust_nix_template.dylib`. Explicitly setting the name of the library with hyphens will fail while parsing the manifest with: `library target names cannot contain hyphens: rust-nix-template`

{#init-haskell}
## Initialize Haskell Project

Fetch `cabal-install` and `ghc` from the `nixpkgs` input of current flake and initialize a new Haskell project[^why-proj-nixpkgs]:

[^why-proj-nixpkgs]: This approach ensures reproducibility as `cabal init` uses the version of GHC to initialize the `base` package constraints.

```sh
nixpkgs_url="github:nixos/nixpkgs/$(nix flake metadata --json | nix run nixpkgs#jq -- '.locks.nodes.nixpkgs.locked.rev' -r)" && \
nix shell $nixpkgs_url#cabal-install $nixpkgs_url#ghc -c \
cabal init -n --exe -m --simple hello-haskell
```

{#nixify-haskell}
## Nixify Haskell Project

We will utilize [haskell-flake](https://community.flake.parts/haskell-flake) to nixify the Haskell project. Add the following to `./hello-haskell/default.nix`:

[[haskell-rust-ffi/hs/default.nix]]
![[haskell-rust-ffi/hs/default.nix]]

Additionally, add the following to `flake.nix`:

```nix
{
  inputs.haskell-flake.url = "github:srid/haskell-flake";

  outputs = inputs:
    # Inside `mkFlake`
    {
      imports = [
        ./hello-haskell
      ];
    };
}
```

Stage the changes:

```sh
git add hello-haskell
```

Now, you can run `nix run .#hello-haskell` to build and execute the Haskell project.

{#merge-devshell}
## Merge Rust and Haskell Development Environments

In the previous section, we created `devShells.haskell`. Let's merge it with the Rust development environment in `flake.nix`:

```nix
{
  # Inside devShells.default
  inputsFrom = [
    # ...
    self'.devShells.haskell
  ];
}
```

Now, re-enter the shell, and you'll have both Rust and Haskell development environments:

```sh
exit
nix develop
cd hello-haskell && cabal build
cd .. && cargo build
```

{#add-rust-lib}
## Add Rust Library as a Dependency

Just like any other dependency, you'll first add it to your `.cabal` file:

```cabal
executable hello-haskell
  -- ...
  extra-libraries: rust_nix_template
```

Try building it:

```sh
cd hello-haskell && cabal build
```

You'll likely encounter an error like this:

```sh
...
* Missing (or bad) C library: rust_nix_template
...
```

The easiest solution might seem to be `export LIBRARY_PATH=../target/debug`. However, this is not reproducible and would mean running an additional command to setup the prerequisite to build the Haskell package. Even worse if the rust project is in a different repository. 

Often, the easiest solution isn't the simplest. Let's use Nix to simplify this process.

When you use Nix, you set up all the prerequisites beforehand, which is why you'll encounter an error when trying to re-enter the devShell without explicitly specifying where the Rust project is:

```sh
...
error: function 'anonymous lambda' called without required argument 'rust_nix_template'
...
```

To specify the Rust project as a dependency, let's edit `hello-haskell/default.nix` to:

```nix
{
  # Inside haskellProjects.default
  settings = {
    rust_nix_template.custom = _: self'.packages.default;
  };
}
```

This process eliminates the need for manual Rust project building as it's wired as a prerequisite to the Haskell package.

{#call-rust}
## Call Rust function from Haskell

Replace the contents of `hello-haskell/app/Main.hs` with:

[[haskell-rust-ffi/hs/Main.hs]]
![[haskell-rust-ffi/hs/Main.hs]]

The implementation above is based on the [Haskell FFI documentation](https://wiki.haskell.org/Foreign_Function_Interface). Now, run the Haskell project:

```sh
nix run .#hello-haskell
```

You should see the output `Hello, from rust!`.

> [!note] MacOS caveat
> If you are on MacOS, the Haskell package will not run because `dlopen` will be looking for the `.dylib` file in the temporary build directory (`/private/tmp/nix-build-rust-nix...`). To fix this, you need to include [fixDarwinDylibNames](https://github.com/NixOS/nixpkgs/blob/af8fd52e05c81eafcfd4fb9fe7d3553b61472712/pkgs/build-support/setup-hooks/fix-darwin-dylib-names.sh) in `flake.nix`:
>
>```nix
>{
>  # Inside `perSystem.packages.default`
>  # ...
>  buildInputs = if pkgs.stdenv.isDarwin then [ pkgs.fixDarwinDylibNames ] else [ ];
>  postInstall = ''
>    ${if pkgs.stdenv.isDarwin then "fixDarwinDylibNames" else ""}
>  '';  
>}
>```

{#cabal-repl}
## Problems with `cabal repl`

`cabal repl` doesn't look for `NIX_LDFLAGS` to find the dynamic library, see why [here](https://discourse.nixos.org/t/shared-libraries-error-with-cabal-repl-in-nix-shell/8921/10). This can be worked around in `hello-haskell/default.nix` using:

```nix
{
  # Inside `devShells.haskell`
  shellHook = ''
    export LIBRARY_PATH=${config.haskellProjects.default.outputs.finalPackages.rust_nix_template}/lib
  '';
}
```

Re-enter the shell, and you're set:

```sh
❯ cd hello-haskell && cabal repl
Build profile: -w ghc-9.4.8 -O1
In order, the following will be built (use -v for more details):
 - hello-haskell-0.1.0.0 (exe:hello-haskell) (ephemeral targets)
Preprocessing executable 'hello-haskell' for hello-haskell-0.1.0.0..
GHCi, version 9.4.8: https://www.haskell.org/ghc/  :? for help
[1 of 2] Compiling Main             ( app/Main.hs, interpreted )
Ok, one module loaded.
ghci> main
Hello, from rust!
```

> [!note] What about `ghci`?
> If you use `ghci` you will need to link the library manually: `ghci -lrust_nix_template`. See the [documentation](https://downloads.haskell.org/ghc/latest/docs/users_guide/ghci.html#extra-libraries).

{#tpl}
## Template

You can find the template at <https://github.com/shivaraj-bh/haskell-rust-ffi-template>. This template also includes formatting setup with [[treefmt|treefmt-nix]] and VSCode integration.
