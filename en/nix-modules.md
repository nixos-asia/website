---
order: 3
---

# Understanding Nix modules

Learning to work with the [[modules|module system]] in [[nixpkgs|nixpkgs]] is a big stepping stone to writing easy to maintain and shareable Nix code. We will focus on that in this tutorial -- by understanding how to use `evalModules` from [[nixpkgs|nixpkgs]] to define and use our own modules. The next tutorial in this series will talk about how to do that using `flake-parts` for writing [[flakes|flakes]] and sharing the modules with others flakes. 

>[!tip] Everything about the module system
> This tutorial introduces the reader to the Nix module system. To learn more about the module system, we recommend [this video from Tweag](https://www.youtube.com/watch?v=N7hFP_40DJo) as well the article "[Module system deep dive][doc]" from nix.dev.

[doc]: https://nix.dev/tutorials/module-system/module-system.html

## A simple example

Consider the following Nix code, defined in a [[flakes|flake]]:

![[nix-modules/1/flake.nix]]

This is a simple flake that exposes a package (a [[writeShellApplication]] [[drv]] wrapping [lsd](https://github.com/lsd-rs/lsd)), that can be [[nix-first|`nix run`ed]] to list the contents of the root directory. 

```sh
❯ nix run
drwxrwxr-x root admin 2.5 KB Tue Jan 30 15:19:06 2024  Applications
drwxr-xr-x root wheel 1.2 KB Sat Nov 18 23:43:59 2023  bin
dr-xr-xr-x root wheel 5.1 KB Wed Jan 17 09:21:57 2024  dev
lrwxr-xr-x root wheel  11 B  Sat Nov 18 23:43:59 2023  etc ⇒ private/etc
lrwxr-xr-x root wheel  25 B  Wed Jan 17 09:22:56 2024  home ⇒ /System/Volumes/Data/home
drwxr-xr-x root wheel 2.2 KB Mon Dec  4 02:08:02 2023  Library
drwxr-xr-x root wheel 224 B  Sat Jul 22 20:09:12 2023  nix
...
```

This program is hardcoded to do a certain thing: it can list the contents of the `/` directory. Now let's say we want to customize its behaviour but without having to modify the derivation itself.

In particular, we want our program to:
- *list a different directory*. 
- or, *show a tree view rather than a linear list*. 

Normally we can achieve this by refactoring our Nix expression to be a *function* (see `lsdFor` ⤵️) that takes arguments for these variations (`dir` and `tree` ⤵️), producing the appropriate [[drv|derivation]] as a result:

![[nix-modules/2/flake.nix]]

Now we can try out each of these variations:

```sh
❯ nix run .#home
 code      Documents   Keybase   Movies     org ...

❯ nix run .#downloads
 Downloads
├──  '$RECYCLE.BIN'
│   └──  desktop.ini
├──  2303.18223.pdf
├──  4.jpg
├──  '[ORIGINAL] PKD MASTERY GUIDE BOOK.pdf'
├──  'ACTUAL FREEDOM'
│   ├──  'ACTUAL FREEDOM (1).txt'
│   └──  "ACTUAL FREEDOM (Richard's Words Only).txt"
...
```

The `lsdFor` function returns a `lsd` wrapper package that behaves in accordance with the arguments we pass to it. The flake outputs three packages, including one for listing the user's home directory as well as their "Downloads" folder as a tree view.

>[!tip] Why introduce module system?
> Our above flake is simple enough that it strictly doesn't require further refactoring. However, in larger flakes, having functions peppered throughout the project can be rather difficult to entangle. To this end, we'll see how to refactor the above to use the module system, and in the process we'll add more configurability to our `lsd` wrapper.

{#introduce}
## Introducing the module system

A Nix *module* is a specification of various "options". When the user `import`s this module, they can assign these options. The module implementation (ie., the `config` attribute) will then use these values to produce the final expression to substitute in call site where the module gets imported. Modules can import each other in nested fashion; and option types can have certain merge semantics allowing you to define the same option across multiple modules.

This is a mouthful, so let's get down to the concrete details. To port our flake above, we need to define two options: `dir`, and `tree`. We will as well add a third option that is not user-setable but will be used set the resulting package.

Here's our lsd module, defined in `lsd.nix` alongside the flake:

![[nix-modules/3/lsd.nix]]

>[!info] Follow the comments
> We recommend that you follow the comments in the above Nix file to understand its structure. As always, consult [Module system deep dive][doc] to learn of all the details.

Let's evaluate it from the [[repl]]:

```sh
❯ nix repl
Welcome to Nix 2.19.2. Type :? for help.

nix-repl> :lf nixpkgs
Added 15 variables.

nix-repl> pkgs = legacyPackages.${builtins.currentSystem}

nix-repl> lib = pkgs.lib

nix-repl> res = lib.evalModules { modules = [ ./lsd.nix { lsd.dir = "$HOME"; } ]; specialArgs = { inherit pkgs; }; }

nix-repl> res.config.lsd.package
«derivation /nix/store/my26y1wp6801sslfvfzf21q41fzh8bch-list-contents.drv»

nix-repl> :b res.config.lsd.package
This derivation produced the following outputs:
  out -> /nix/store/m8phgz5ch7whqbs5pk991pc0cfczsghk-list-contents
```

Using `evalModules`, as we saw in the repl session, we can refactor our previous flake:

![[nix-modules/3/flake.nix]]

>[!tip] Hmm!
> You may notice that there's not much difference. If anything our new flake is *slightly* more complex, due to use of `evalModules`. The simplicity of the module system will become evident as you write more complex flakes, or if you want to share your modules or override them.

{#imports}
## Importing modules

Let's do something more interesting in the above flake. We'll create a "common settings" module, and then use that across the packages using the `imports` attribute. `evalModules` implements a type merge system that knows how to merge same attributes from multiple modules.

![[nix-modules/4/flake.nix]]

Compared to the 3rd flake, we have:

- In [[nix-modules/4/lsd.nix]]: a new option `long` to specify `-l` to lsd.
- In [[nix-modules/4/flake.nix]]: 
  - a new module `common` enabling the `long` option.
  - all packages now `imports` this common module, to derive the `long` option.

Now when you `nix run` these programs you will get similar output to the previous flake but with a long listing instead.

{#share}
## Sharing modules across flakes

