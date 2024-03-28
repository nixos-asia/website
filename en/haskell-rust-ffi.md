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

TODO

## Call rust function from haskell

TODO

## Template

> [!warning] TODO
> Provide a link to the template and talk about the added benefits of formatting, lsp, etc.