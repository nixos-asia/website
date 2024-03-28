# Rust FFI in Haskell

This #[[tutorial|tutorial]] will show you how to use [[nix]] to simplify the workflow of using [[rust]] library as a dependency in your [[haskell]] project via [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface). If you are new to [[nix]], first go through the [[nix-tutorial]].

> [!info] Foreign Function Interface (FFI)
> This is not just limited to haskell and rust, it can be used between any two languages that can find a common ground to communicate with each other, in this case, C.

The end goal of this tutorial is to be able to call a rust function that returns `Hello, from rust!` from a haskell package. Let's get started with the rust library.

{#init-rust}
## Initialize rust project

Initialize a new rust project with [rust-nix-template](https://github.com/srid/rust-nix-template):

```sh
git clone https://github.com/srid/rust-nix-template.git
cd rust-nix-template
```

Let's run the project:

```sh
nix develop
just run
```

{#rust-lib}
## Create a rust library

The template we just initialized is a binary project, we will need a library project. The library must export a function that we can call from haskell, for simplicity, let's export a function `hello` that returns a `C-style string`. Create a new file `src/lib.rs` with contents:

[[haskell-rust-ffi/lib.rs]]
![[haskell-rust-ffi/lib.rs]]

Read more about **Calling Rust code from C** [here](https://doc.rust-lang.org/nomicon/ffi.html#calling-rust-code-from-c).

The library now builds, but we don't have the dynamic library files that are required for FFI. For this, let's add a `crate-type` to the `Cargo.toml`:

```toml
[lib]
crate-type = ["cdylib"]
```

Now when you run `cargo build`, you should see a `librust_nix_template.dylib` (if you are on macOS) or `librust_nix_template.so` (if you are on Linux) in the `target/debug` directory.

{#init-haskell}
## Initialize haskell project

Temporarily add to the `devShells.default` in `flake.nix`:

```nix
{
  # Inside devShells.default
  nativeBuildInputs = with pkgs; [
    # ...
    cabal-install
    ghc
  ];
}

```

Then, run:

```sh
nix develop -c cabal init -n --exe -m --simple hello-haskell
```

{#nixify-haskell}
## Nixify haskell project

We will use [haskell-flake](https://community.flake.parts/haskell-flake) to nixify the haskell project. Add the following to `./hello-haskell/default.nix`:

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

Now, `nix run .#hello-haskell` to build and run the haskell project.

{#merge-devshell}
## Merge Rust and Haskell development environments

We created `devShells.haskell` in the previous section. Let's merge it with the Rust development environment in `flake.nix`:

```nix
{
  # Inside devShells.default
  inputsFrom = [
    # ...
    self'.devShells.haskell
  ];
}
```

Re-enter the shell and you now have both Rust and Haskell development environments:

```sh
exit
nix develop
cd hello-haskell && cabal build
cd .. && cargo build
```

{#add-rust-lib}

## Add rust library as a dependency

As any other depedency, you will first add them to your `.cabal` file:

```cabal
executable hello-haskell
  -- ...
  extra-libraries: rust_nix_template
```

Try to build it:

```sh
cd hello-haskell && cabal build
```

And you will see an error like this:

```sh
...
* Missing (or bad) C library: rust_nix_template
...
```

The easiest thing to do would be to `export LIBRARY_PATH=../target/debug`. This would mean that building the rust project will always be an extra command you run in the setup/distribution process. And it only gets harder when you have more dependencies and are spread across repositories.

Even on trying to re-enter the `devShell`, the haskell package derivation will not resolve as it can't find `rust_nix_template`:

```sh
...
error: function 'anonymous lambda' called without required argument 'rust_nix_template'
...
```

Several times, easiest thing to do is not the simplest, let's use nix to simplify this process.

Edit `hello-haskell/default.nix` to:

```nix
{
  # Inside haskellProjects.default
  otherOverlays = [
    (_: _: {
      rust_nix_template = self'.packages.default;
    })
  ];
}
```

This will not require user to manually build the rust project because we have autowired it as a pre-requisite to the haskell package.

## Call rust function from haskell

Replace the contents of `hello-haskell/app/Main.hs` with:

[[haskell-rust-ffi/hs/Main.hs]]
![[haskell-rust-ffi/hs/Main.hs]]

The implementation above is based on the [Haskell FFI documentation](https://wiki.haskell.org/Foreign_Function_Interface). Now, run the haskell project:

```sh
nix run .#hello-haskell
```

You should see the output `Hello, from rust!`.

> [!note] MacOS caveat
> If you are on MacOS, the haskell package will not run because `dlopen` will be looking for the `.dylib` file in the temporary build directory (`/private/tmp/nix-build-rust-nix...`). To fix this, you will need [fixDarwinDylibNames](https://github.com/NixOS/nixpkgs/blob/af8fd52e05c81eafcfd4fb9fe7d3553b61472712/pkgs/build-support/setup-hooks/fix-darwin-dylib-names.sh) in `flake.nix`:
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

Re-enter the shell, and voila!

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
> If you use `ghci` you will have to link the library manually: `ghci -lrust_nix_template`. See the [documentation](https://downloads.haskell.org/ghc/latest/docs/users_guide/ghci.html#extra-libraries).

## Template

You can find the template at <https://github.com/shivaraj-bh/haskell-rust-ffi-template>. This template additionally comes with formatting setup with [[treefmt|treefmt-nix]] and VSCode integration.
