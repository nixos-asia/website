
# First steps with Nix

You have [[install|installed Nix]]. Now let's play with the `nix` command but without bothering to write any Nix expressions yet (we reserve that for the [[nix-rapid|next tutorial]]). In particular, we will learn how to use packages from the [[nixpkgs]] repository and elsewhere.

![[nix-first.png]]

## Running a package

As of this writing, [[nixpkgs]] has over 80,000 packages. You can search them [here](https://search.nixos.org/packages). Search for "`cowsay`" and [you will find](https://search.nixos.org/packages?type=packages&query=cowsay) that it is available in Nixpkgs. We can download and run the [cowsay](https://en.wikipedia.org/wiki/Cowsay) package as follows:

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

>[!info] `nix run`
> `nix run` command will run the specified package from the flake. Here `nixpkgs` is the [[flakes|flake]], followed by the letter `#`, which is followed by the package ([[drv]]) name `cowsay` that is outputted by that flake. See [[flake-url]] for details on the syntax.

## Looking inside a package

What is a Nix "package"? Technically, a Nix package is a special [[store-path]] built using instructions from a [[drv]], both of which reside in the [[store]]. To see what is contained by the `cowsay` package, look inside its [[store-path]]. To get the store path for a package (here, `cowsay`), run `nix build` as follows:

```text
$ nix build nixpkgs#cowsay --no-link --print-out-paths
/nix/store/8ij2wj5nh4faqwqjy1fqg20llawbi0d5-cowsay-3.7.0-man
/nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
```

The `cowsay` [[drv]] produces two output paths, the second of which is the cowsay binary package (the first one is the separate documentation path), and if you inspect that you will see the contents of it:

```text
$ lt /nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
 n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
├──  bin
│   ├──  cowsay
│   └──  cowthink ⇒ cowsay
└──  share
    └──  cowsay
        ├──  cows
        │   ├──  beavis.zen.cow
        │   ├──  blowfish.cow
        │   ├──  bong.cow
        │   ├── ...
```

>[!info] Nix Store & Store Paths
> `/nix/store` is a special directory representing the [[store]]. The paths inside `/nix/store` are known as [[store-path]]. Nix fundamentally is, in large part, about manipulating these store paths in a *pure* and *reproducible* fashion; [[drv]] are "recipes" that does this manipulation, and they too live in the [[store]].


## Shell environment

One of the powers of Nix is that it enables us to create *isolated* [[shell|shell]] environments containing just the packages we need. For eg., here's how we create a transient shell containing the "cowsay" and "[fortune](https://en.wikipedia.org/wiki/Fortune_(Unix))" packages:

```text
$ nix shell nixpkgs#cowsay nixpkgs#fortune 
❯
```

From here, you can verify that both the programs are indeed in `$PATH` as indicatex by the "bin" directory in their respective [[store-path|store paths]]:

```text
$ nix shell nixpkgs#cowsay nixpkgs#fortune 
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


## Installing a package

>[!warning] Declarative package management
> This section explains how to install a package *imperatively*. For a better way of installing packages (*declaratively*), see [[hm-tutorial|home-manager]].

Neither `nix run` nor `nix shell` will mutate your system environment, aside from changing the [[store]]. If you would like to *permanently* install a package somewhere under your $HOME directory, you can do so using `nix profile install`:

```text
$ nix profile install nixpkgs#cowsay nixpkgs#fortune
$ which cowsay
/home/user/.nix-profile/bin/cowsay
$ which fortune
/home/user/.nix-profile/bin/fortune
$ 
```

`nix profile install` installs symlinks under the `$HOME/.nix-profile` directory, which the Nix [[install|installer]] already added to your `$PATH`. For details, see the [Nix manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile-install).

These symlinks, ultimately, point to the package [[store-path]] outputs under the [[store]], viz.:

```text
$ readlink $(which fortune)
/nix/store/mfw77f008xy0zb7dqdyggw0xj2gd4jjv-fortune-mod-3.20.0/bin/fortune
```

Note that this is the same path used by both `nix build` and `nix shell`. Each specific package is uniquely identified by their [[store-path]]; changing any part of its [[drv|build recipe]] (including dependencies), changes that path. Hence, nix is reproducible.

## How is [[nixpkgs]] fetched

So far we have been retrieving and installing software from the [[nixpkgs]] flake, which is defined in the GitHub repository: https://github.com/nixos/nixpkgs. This information comes from the [[registry]]:


```text
$ nix registry list | grep nixpkgs
global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
```

A registry is simply a mapping of flake alias to [[flake-url]].

>[!tip] Adding to registry
> You can add your own flakes to this [[registry|registry]] as well. See [the manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry-add)

We can find the current Git revision of [[nixpkgs]] used by our [[registry|registry]] as follows:

```text
❯ nix flake metadata nixpkgs --json | nix run nixpkgs#jq -- -r .locked.rev
317484b1ead87b9c1b8ac5261a8d2dd748a0492d
```

From here, you can see the revision [on GitHub](https://github.com/NixOS/nixpkgs/commit/317484b1ead87b9c1b8ac5261a8d2dd748a0492d).

The discerning readers may have noticed that the registry specifies *only* the branch (`nixpkgs-unstable`), but not the specific revision. Nix registry internally [caches flakes locally and updates them automatically](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry#description), thus the specific Git revision of [[nixpkgs]] used may change over time!

> [!tip] Pinning nixpkgs
> To avoid the aforementioned automatic update, you can manually [pin](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry-pin) the registry entry for [[nixpkgs]]. In [[hm-tutorial|home-manager]], we will see [an automatic and declarative way](https://github.com/juspay/nix-dev-home/commit/99f304a6512f59194932b2010af5e270efdfebe8) of doing this (through flake inputs).

You are not required to use a registry. Without a registry, getting a package off nixpkgs would instead involve its fully qualified [[flake-url|URL]]:

```text
$ nix run github:NixOS/nixpkgs/nixpkgs-unstable#cowsay
...
```

## Using software outside of [[nixpkgs]]

[[nixpkgs]] is not the only way to get software packaged by Nix. As you have seen immediately above, you can install programs from *any* [[flakes|flake]] by specifying its [[flake-url|flake URL]] to the `nix ?` commands. For example, [Emanote](https://emanote.srid.ca/start/install) (which is used to build this very website) can be executed or installed directly off its flake [on GitHub](https://github.com/srid/emanote):

```text
$ nix run github:srid/emanote
...
```

You can of course also install it to your home directory:

```text
$ nix profile install github:srid/emanote
...
```

## What's next

- See [[nix-rapid]] where we will go over writing simple Nix expressions and [[flakes|flakes]]. 
- If you want to manage your system using Nix, see [[hm-tutorial]] (if you are on [[macos]] or non-NixOS Linux) or [[nixos-tutorial]] (if you are on [[nixos]]).