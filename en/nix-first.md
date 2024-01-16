
# First steps with Nix

You have [[install|installed Nix]]. Now let's play with the `nix` command but without bothering to write any Nix expressions yet (we reserve that for the [[nix-rapid|next tutorial]]). In particular, we will learn how use to packages from the [[nixpkgs]] repository and elsewhere.

![[nix-first.png]]

## Running a package

As of this writing, [[nixpkgs]] has over 80,000 packages. You can search them [here](https://search.nixos.org/packages). Search for "`cowsay`" and you will find that it is available in Nixpkgs. We can download and run the [cowsay](https://en.wikipedia.org/wiki/Cowsay) package as follows:

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

## Shell environment

One of the powers of Nix is that it enables us to create *isolated* [[shell|shell]] environments containing just the packages we need. For eg., here's how we create a transient shell containing the "cowsay" and "[fortune](https://en.wikipedia.org/wiki/Fortune_(Unix))" packages:

```text
$ nix shell nixpkgs#cowsay nixpkgs#fortune 
❯
```

From here, you can verify that both the programs are indeed in `$PATH`

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

>[!info] Store Paths
> `/nix/store` is a special directory representing the [[store]]. The paths inside `/nix/store` are known as [[store-path]]. Nix fundamentally is, in large part, about manipulating these store paths in a *pure* and *reproducible* fashion.


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

## How is [[nixpkgs]] fetched

The [[nixpkgs]] flake is defined in the GitHub repository: https://github.com/nixos/nixpkgs. This information comes from the [[registry]]:


```text
$ nix registry list | grep nixpkgs
global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
```

>[!tip] Adding to registry
> You can add your own flakes to this [[registry|registry]] as well. See [the manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry-add)

We can find the Git revision of [[nixpkgs]] used by our [[registry|registry]] as follows:

```text
❯ nix flake metadata nixpkgs --json | nix run nixpkgs#jq -- -r .locked.rev
317484b1ead87b9c1b8ac5261a8d2dd748a0492d
```

From here, you can see the revision [on GitHub](https://github.com/NixOS/nixpkgs/commit/317484b1ead87b9c1b8ac5261a8d2dd748a0492d).

Notice that the registry specified only the branch (`nixpkgs-unstable`) from where the latest available revision is fetched. This repository is [cached locally and updated automatically](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry#description). 

> [!tip] Pinning nixpkgs
> To avoid automatic update, you can [pin](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry-pin) the registry entry. But in [[hm-tutorial|home-manager]], we will see a better way of doing it (through flake inputs).

## Using software outside of [[nixpkgs]]

[[nixpkgs]] is not the only way to get software packaged by Nix. Many programs are either *not* packaged in [[nixpkgs]], or they may be out of date. For example, [Emanote](https://emanote.srid.ca/start/install) (which is used to build this very website) can be executed or installed directly off its flake:

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