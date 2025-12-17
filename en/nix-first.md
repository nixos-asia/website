---
order: 1
page:
  image: nix-tutorial/nix-first.png
---

# First steps with Nix

You have [[install|installed Nix]]. Now let's play with the `nix` command. 

In this tutorial we will learn how to use existing packages from the [[nixpkgs|nixpkgs]] repository and elsewhere. We will *not* be writing any Nix language code yet (we reserve that for the [[nix-rapid|next tutorial]]).

![[nix-first.png]]

{#run}
## Running a package

As of this writing, [[nixpkgs]] has over 80,000 packages. You can search them [here](https://search.nixos.org/packages). Search for "`cowsay`" and [you will find](https://search.nixos.org/packages?type=packages&query=cowsay) that it is available in Nixpkgs. 

We can download and run the [cowsay](https://en.wikipedia.org/wiki/Cowsay) package as follows:

```text
$ nix run nixpkgs#cowsay "G'day $USER"
 ____________
< G'day srid >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     || 
$
```

> [!info] `nix run`
> `nix run` command will run the specified package from the flake. Here `nixpkgs` is the [[flakes|flake]], followed by the letter `#`, which is followed by the package ([[drv]]) name `cowsay` that is outputted by that flake. See [[flake-url]] for details on the syntax.

{#shell}
## Transient shells

One of the superpowers of Nix is that it enables us to create *isolated* [[shell|shell]] environments containing just the packages we need. 

For example, here's how we create a temporary shell containing the "cowsay" and "[fortune](https://en.wikipedia.org/wiki/Fortune_(Unix))" packages:

```text
$ nix shell nixpkgs#cowsay nixpkgs#fortune 
❯
```

From here, you can verify that both the programs are indeed in `$PATH`. But where do they live?

```text
❯ which cowsay
/nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0/bin/cowsay
❯ which fortune
/nix/store/mfw77f008xy0zb7dqdyggw0xj2gd4jjv-fortune-mod-3.20.0/bin/fortune
❯ fortune | cowsay
 ________________________________
/ The longer the title, the less \
\ important the job.             /
 --------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

When you exit this shell (type `exit` or press Ctrl+D), `cowsay` and `fortune` will no longer be available in your path.

> [!tip] One-off command
> Instead of entering an interactive shell, you can also run commands one-off using the `-c` option.
> ```text
> nix shell nixpkgs#cowsay nixpkgs#fortune -c sh -c 'fortune | cowsay'
> ```

{#under-the-hood}
## Under the hood

You might have noticed the specific paths in the `which` output above, looking like `/nix/store/...-cowsay-...`. 

Technically, a Nix package is a special directory (a [[store-path]]) inside the **Nix Store** (`/nix/store`), built using instructions from a [[drv|Derivation]]. 

To inspect the contents of a package without running it or creating a shell, we can use `nix build`. This will realize the package in the store and print its path:

```text
$ nix build nixpkgs#cowsay --no-link --print-out-paths
/nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
```

We can then inspect this directory structure (using `tree`, which we can also run via Nix!):

```text
$ nix run nixpkgs#tree /nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
/nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
├── bin
│   ├── cowsay
│   └── cowthink -> cowsay
└── share
    └── cowsay
        ├── cows
        │   ├── DragonAndCow.pm
        │   ├── Example.pm
        │   ├── Frogs.pm
        │   ├── ...
```

> [!info] Nix Store & Store Paths
> `/nix/store` is a special directory representing the [[store]]. It is read-only and all components within it are immutable. Nix fundamentally is about manipulating these store paths in a *pure* and *reproducible* fashion.

{#install}
## Installing a package

> [!warning] Declarative package management
> This section explains how to install a package *imperatively*. For a better way of installing packages (*declaratively*), see [[hm-tutorial|home-manager]].

If you want to keep a package available permanently (not just in a transient shell), you can install it into your user profile using `nix profile install`:

```text
$ nix profile install nixpkgs#cowsay nixpkgs#fortune
$ which cowsay
/home/user/.nix-profile/bin/cowsay
```

`nix profile install` creates symlinks under `$HOME/.nix-profile`, pointing to the actual files in the Nix Store.

{#nixpkgs-pin}
## Where do packages come from?

So far we have been getting software from `nixpkgs`. What is that?

It is the specific identifier for the [[nixpkgs]] repository (https://github.com/nixos/nixpkgs) defined in your local [[registry]]:

```text
$ nix registry list | grep nixpkgs
global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
```

A registry is simply a shortcut mapping (like `nixpkgs`) to a full [[flake-url]] (like `github:NixOS/nixpkgs/nixpkgs-unstable`).

We can confirm which version of nixpkgs we are using:

```text
❯ nix flake metadata nixpkgs --json | nix run nixpkgs#jq -- -r .locked.rev
317484b1ead87b9c1b8ac5261a8d2dd748a0492d
```

> [!tip] Pinning nixpkgs
> By default, `nixpkgs` corresponds to a rolling branch (`nixpkgs-unstable`), which updates automatically. To [pin](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry-pin) it to a specific version, or to manage it declaratively, see [[hm-tutorial|home-manager]].

You are not required to use a registry. Without a registry, getting a package off nixpkgs would instead involve its fully qualified [[flake-url|URL]]:

```text
$ nix run github:NixOS/nixpkgs/nixpkgs-unstable#cowsay
...
```

{#external-software}
## Software from elsewhere

[[nixpkgs]] is the main repository, but Nix allows installing software from *anywhere*. You can run or install programs from any [[flakes|flake]] by specifying its [[flake-url|URL]].

For example, [Emanote](https://emanote.srid.ca) (which builds this website) can be run directly from its own GitHub repository:

```text
$ nix run github:srid/emanote
```

Or installed:

```text
$ nix profile install github:srid/emanote
```

## What's next

- [[nix-rapid|Next Tutorial]]: We will start writing our own simple Nix expressions and [[flakes|flakes]].
- [[hm-tutorial|Home Manager]]: If you want to manage your shell environment and packages declaratively (recommended for personal machines).
- [[nixos-tutorial|NixOS]]: If you are ready to configure your entire operating system with Nix.
