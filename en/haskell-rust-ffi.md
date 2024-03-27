# Rust FFI in Haskell

This #[[tutorial|tutorial]] will show you how to use [[nix]] to simplify the workflow of using [[rust]] library as a dependency in your [[haskell]] project via [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface).

> [!info] Foreign Function Interface (FFI)
> This is not just limited between haskell and rust, it can be used between any two languages that can find a common ground to communicate with each other, in this case, C.

The end goal of this tutorial is to be able to call a rust function that returns "Hello, from rust!" from a haskell package. Let's get started with the rust library.

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

## Create a rust library

The template we just initialized is a binary project, let's follow the convention for a library project and use `lib.rs`:

```sh
mv src/main.rs src/lib.rs
```

`cargo run` will no longer work, but we can still `cargo build`.

As this is now a library, let's not worry about the arguments for it and just create a public function `hello` that returns a C-style string. Replace the contents of `src/lib.rs` with:

[[haskell-rust-ffi/lib.rs]]
![[haskell-rust-ffi/lib.rs]]

Read more about "Calling Rust code from C" [here](https://doc.rust-lang.org/nomicon/ffi.html#calling-rust-code-from-c).

The library now builds, but we don't have the dynamic library yet. Let's add a `crate-type` to the `Cargo.toml`:

```toml
[lib]
crate-type = ["cdylib"]
```

Now when you run `cargo build`, you should see a `librust_nix_template.dylib` (if you are on macOS) or `librust_nix_template.so` (if you are on Linux) in the `target/debug` directory.

## Initialize haskell project

TODO

## Add rust library as a dependency

TODO

## Call rust function from haskell

TODO

## Template

> [!warning] TODO
> Provide a link to the template and talk about the added benefits of formatting, lsp, etc.