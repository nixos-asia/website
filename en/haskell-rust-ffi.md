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

## Add rust library as a dependency

TODO

## Call rust function from haskell

TODO

## Template

> [!warning] TODO
> Provide a link to the template and talk about the added benefits of formatting, lsp, etc.