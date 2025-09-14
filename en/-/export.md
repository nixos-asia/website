<!-- LLM PROMPT: This document contains all notes from an Emanote notebook.
Each note is separated by '===' delimiters and includes metadata headers.
- Source: The original file path in the notebook
- URL: The full URL where this note can be accessed
- Title: The note's title
- Wikilinks: All possible ways to reference this note using [[wikilink]] syntax

When referencing notes, you can use any of the wikilinks provided.
The base URL is: https://nixos.asia/en
-->

<!-- Source: blog.md -->
<!-- URL: https://nixos.asia/en/blog -->
<!-- Title: Blog -->
<!-- Wikilinks: [[blog]] -->

---
order: -50
feed:
  enable: true
  title: NixOS Asia Blog
---

# Blog

```query {.timeline}
path:./*
```


===

<!-- Source: blog/replacing-docker-compose.md -->
<!-- URL: https://nixos.asia/en/blog/replacing-docker-compose -->
<!-- Title: Replacing docker-compose with Nix for development -->
<!-- Wikilinks: [[blog/replacing-docker-compose]], [[replacing-docker-compose]] -->

---
author: shivaraj
date: 2023-03-05
page:
  image: blog/replacing-docker-compose/docker-to-nix.png
---

# Replacing docker-compose with Nix for development

Ever since I first started using [[nix|Nix]] for #[[dev|development]], I have enjoyed the [[why-dev|simplicity of setup]]: `nix develop`, make the code change and see it work. That's all well and good, but when your project keeps growing, you need to depend on external services like databases, message brokers, etc. And then, a quick search will tell you that [docker](https://www.docker.com/) is the way to go. You include it, [add one more step](https://github.com/nammayatri/nammayatri/tree/f056bb994fbf9adefa454319032ca35c34ea65bc/Backend#other-tools) in the setup guide, increasing the barrier to entry for new contributors. Not to mention, eating up all the system resources[^native-macos] on my not so powerful, company-provided MacBook.

This, along with the fact that we can provide one command to do more than just running external services (more about this at the end of the post), made us want to replace [docker-compose](https://docs.docker.com/compose/) with Nix in [Nammayatri](https://github.com/nammayatri/nammayatri) (Form now on, I'll use 'NY' as the reference for it).

> [!note] Nammayatri
> [NY](https://nammayatri.in) is an open-source auto rickshaw booking platform, based in India.

![[docker-to-nix.png]]

[^native-macos]: The high resource consumption is due to docker running the containers on a VM, there is an [initiative to run containers natively on macOS](https://github.com/macOScontainers/homebrew-formula), but it is still in alpha and [requires a lot of additional steps](https://github.com/macOScontainers/homebrew-formula?tab=readme-ov-file#installation) to setup. One such step is [disabling SIP](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection#3599244), which a lot of company monitored devices might not be allowed to do.

{#what-does-it-take}

## What does it take?

Turns out, there is not a lot of things that we need to do: we need to be able to run services natively, across platforms (so that my MacBook doesn't drain its battery running a database), and integrate with the existing [flake.nix](https://github.com/nammayatri/nammayatri/blob/main/flake.nix) (to avoid an extra step in the setup guide).

If you've ever used [[nixos|NixOS]] before, you might be familiar with the way services are managed. Let's take a quick look at an example to understand if that will help us arrive at a solution for our problem.

{#nixos-services}

## NixOS services

Running services in [[nixos|NixOS]] is a breeze. For example, [running a PostgreSQL Database](https://nixos.wiki/wiki/PostgreSQL) is as simple as adding one line to your configuration:

```nix
{
  services.postgresql.enable = true;
}
```

This starts the database natively, with a global data directory, without the need for a container. That's great. What we need, however, is the same simplicity but with a project-specific data directory, applicable to macOS and other Linux distributions.

{#nixos-like-services}

## Cross-platform NixOS-like services

In the last section, we saw how easy it is to run services in [[nixos|NixOS]]. We are looking for something similar for our development environment that runs across platforms. Additionally, the solution should:

- Allow for running multiple instances of the same service (NY uses multiple instances of PostgreSQL and Redis).
- Ensure that services and their data are project-specific.

These were the exact problems #[[services-flake]] was designed to solve. Along with running services natively, it also [integrates with your project's `flake.nix`](https://community.flake.parts/services-flake/start).

{#services-flake}

## services-flake

How does [[services-flake]] solve them?

- It uses [[flake-parts]] for the [[modules|module system]] (that's the simplicity aspect), and [[process-compose-flake]] for managing services, along with providing a TUI app to monitor them.
- To address the need for running multiple instances, services-flake exports a [`multiService` library function](https://github.com/juspay/services-flake/blob/e0a1074f8adb68c06b847d34b260454a18c0697c/nix/lib.nix#L7-L33).
- By default, the data of each service is stored under `./data/<service-name>`, where `./` refers to the path where the process-compose app, exported by the project [[flakes|flake]] is run (usually in the project root).

{#start}

## Let's get started

Now that we have all the answers, it's time to replace [docker-compose in NY](https://github.com/nammayatri/nammayatri/blob/f056bb994fbf9adefa454319032ca35c34ea65bc/Backend/nix/arion-configuration.nix) with [[services-flake]]. We will only focus on a few services to keep it simple; for more details, refer to the [PR](https://github.com/nammayatri/nammayatri/pull/3718).

:::{.center}
![[ny-services-flake.png]]
:::

{#postgresql}

### PostgreSQL

NY uses about 3 instances of PostgreSQL databases.

One of them is [exported by passetto](https://github.com/nammayatri/passetto/blob/nixify/process-compose.nix) (passetto is a Haskell application that encrypts data before storing it in postgres), and using it looks like:

```nix
{
  services.passetto.enable = true;
}
```

By leveraging the [[modules|module system]], we can hide the implementation details and only expose the `passetto` service to the user, enabling its use as shown above.

The other two instances are configured by the [postgres-with-replica module](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/nix/services/postgres-with-replica.nix). This module starts two services (`primary` and `replica` databases) and a [pg-basebackup](https://www.postgresql.org/docs/current/app-pgbasebackup.html) process (to synchronize `replica` with `primary` during initialization). For the user, it appears as follows:

```nix
{
  services.postgres-with-replica.enable = true;
}
```

{#redis}

### Redis

NY uses [Redis](https://redis.io/) as a cache and clustered version of it as a key-value database. Redis service comprises a single node, while the clustered version has 6 nodes (3 masters and 3 replicas). Adding them to the project is as simple as:

```nix
{
  services.redis.enable = true;
  services.redis-cluster.enable = true;
}
```

{#cool-things}

## Cool things

By no longer depending on Docker, we can now run the entire NY backend with one command, and it's all defined in a [single place](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/nix/services/nammayatri.nix). 

That's not all; we can also share the NY backend module to do much more, such as defining [load-test](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/load-test/default.nix) configurations and running them in CI/local environments, again, with just one command. In this case, we take the module to run the entire NY stack and then extend it to add a bunch of load-test processes before bringing the whole thing to an end (as the load-test ends).

This is what running them looks like:

```sh
# Run load-test
nix run github:nammayatri/nammayatri#load-test-dev

# Run the entire backend
nix run github:nammayatri/nammayatri#run-mobility-stack-nix
```

{#next}
## Up next

Sharing [[services-flake]] modules deserves a separate post, so we will delve into this topic more in the next post.


===

<!-- Source: buildRustPackage.md -->
<!-- URL: https://nixos.asia/en/buildRustPackage -->
<!-- Title: buildRustPackage -->
<!-- Wikilinks: [[buildRustPackage]] -->

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

===

<!-- Source: cache.md -->
<!-- URL: https://nixos.asia/en/cache -->
<!-- Title: Binary Cache -->
<!-- Wikilinks: [[cache]] -->

# Binary Cache

A binary cache provides cached binaries of built #[[nix]] [[drv]].

https://nixos.wiki/wiki/Binary_Cache

https://zero-to-nix.com/concepts/caching


===

<!-- Source: configuration-as-flake.md -->
<!-- URL: https://nixos.asia/en/configuration-as-flake -->
<!-- Title: Convert configuration.nix to be a flake -->
<!-- Wikilinks: [[configuration-as-flake]] -->

# Convert `configuration.nix` to be a flake

A problem with the default NixOS `configuration.nix` generated by the official installer is that it is not "pure" and thus not reproducible (see [here](https://www.tweag.io/blog/2020-07-31-nixos-flakes/#what-problems-are-we-trying-to-solve)), as it still uses a mutable Nix channel (which is generally [discouraged](https://zero-to-nix.com/concepts/channels#the-problem-with-nix-channel)). For this reason (among others), it is recommended to immediately switch to using #[[flakes]] for our NixOS configuration. Doing this is pretty simple. Just add a `flake.nix` file in `/etc/nixos`:

```sh
sudo nvim /etc/nixos/flake.nix
```

Add the following:

```nix
# /etc/nixos/flake.nix
{
  inputs = {
    # NOTE: Replace "nixos-23.11" with that which is in system.stateVersion of
    # configuration.nix. You can also use latter versions if you wish to
    # upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };
  outputs = inputs@{ self, nixpkgs, ... }: {
    # NOTE: 'nixos' is the default hostname set by the installer
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      # NOTE: Change this to aarch64-linux if you are on ARM
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
```

> [!note] Make sure to change a couple of things in the above snippet:
> - Replace `nixos-23.11` with the version from [`system.stateVersion`](https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion) in your `/etc/nixos/configuration.nix`. If you wish to upgrade right away, you can also use latter versions, or use `nixos-unstable` for the bleeding edge.
> - `x86_64-linux` should be `aarch64-linux` if you are on ARM

Now, `/etc/nixos` is technically a [[flakes|flake]]. We can "inspect" this flake using the `nix flake show` command:

```sh
$ nix flake show /etc/nixos
error: experimental Nix feature 'nix-command' is disabled; use '--extra-experimental-features nix-command' to override
```

Oops, what happened here? As flakes is a so-called "experimental" feature, you must manually enable it. We'll _temporarily_ enable it for now, and then enable it _permanently_ latter. The `--extra-experimental-features` flag can be used to enable experimental features. Let's try again:

```sh
$ nix --extra-experimental-features 'nix-command flakes' flake show /etc/nixos
warning: creating lock file '/etc/nixos/flake.lock'
error:
       … while updating the lock file of flake 'path:/etc/nixos?lastModified=1702156351&narHash=sha256-km4AQoP/ha066o7tALAzk4tV0HEE%2BNyd9SD%2BkxcoJDY%3D'

       error: opening file '/etc/nixos/flake.lock': Permission denied
```

Progress, but we hit another error---Nix understandably cannot write to root-owned directory (it tries to create the `flake.lock` file). One way to resolve this is to move the whole configuration to our home directory, which would also prepare the ground for storing it in [[git]]. We will do this in the next section.

> [!info] `flake.lock` 
> Nix commands automatically generate a (or update the) `flake.lock` file. This file contains the exacted pinned version of the inputs of the flake, which is important for reproducibility.

{#homedir}
## Move configuration to user directory

Move the entire `/etc/nixos` directory to your home directory and gain control of it:

```sh
$ sudo mv /etc/nixos ~/nixos-config && sudo chown -R $USER ~/nixos-config
```

Your configuration directory should now look like:

```sh
$ ls -l ~/nixos-config/
total 12
-rw-r--r-- 1 srid root 4001 Dec  9 16:03 configuration.nix
-rw-r--r-- 1 srid root  224 Dec  9 16:12 flake.nix
-rw-r--r-- 1 srid root 1317 Dec  9 15:43 hardware-configuration.nix
```

Now let's try `nix flake show` on it, and this time it should work:

```sh
$ cd ~/nixos-config
$ nix --extra-experimental-features 'nix-command flakes' flake show
warning: creating lock file '/home/srid/nixos-config/flake.lock'
path:/home/srid/nixos-config?lastModified=1702156518&narHash=sha256-nDtDyzk3fMfABicFuwqWitIkyUUw8BZ4SniPPyJNKjw%3D
└───nixosConfigurations
    └───nixos: NixOS configuration
```

Voila! Incidentally, this flake has a single output, `nixosConfigurations.nixos`, which is the NixOS configuration itself. 

>[!info] More on Flakes
> See [[nix-rapid]] for more information on flakes.

Once flake-ified, we can use the same command to activate the new configuration but we must additionally pass the `--flake` flag, viz.:

```sh
# The '.' is the path to the flake, which is current directory.
$ sudo nixos-rebuild switch --flake .
```

If everything went well, you should see something like this:

:::{.center}
![[nixos-rebuild-switch-flake.png]]
:::

Excellent, now we have a flake-ified NixOS configuration that is pure and reproducible! 

===

<!-- Source: dev.md -->
<!-- URL: https://nixos.asia/en/dev -->
<!-- Title: Nix for Development -->
<!-- Wikilinks: [[dev]] -->

# Nix for Development

While package management is the key purpose of #[[nix]], its [[drv|derivations]] can also be used to produce non-package types, such as development environments (aka. "devShell").

![[why-dev]]

## Language support

- [[haskell]]#
- [[rust]]#

## Tools

- [[direnv]]#

===

<!-- Source: direnv.md -->
<!-- URL: https://nixos.asia/en/direnv -->
<!-- Title: direnv: manage dev environments -->
<!-- Wikilinks: [[direnv]] -->

# `direnv`: manage dev environments

`direnv` (along with [nix-direnv]) allows one to persist[^gc] nix #[[dev|development]] [[shell|shell]] environments and share them seamlessly with text editors and IDEs. It obviates having to run `nix develop` manually every time you open a new terminal. The moment you `cd` into your project directory, the devshell is automatically activated, thanks to `direnv`. 

[^gc]: [nix-direnv] prevents garbage collection of the devshell, so you do not have to re-download things again. direnv also enables activating the devshell in your current shell, without needing to use a customized bash.

>[!tip] Starship
> It is recommended to use [**starship**](https://starship.rs/) along with nix-direnv, because it gives a visual indication of the current environment. For example, if you are in a [[shell]], your terminal prompt automatically changes to something like this:
>
> ```sh
> srid on nixos haskell-template on  master [!] via λ 9.2.6 via ❄️  impure (ghc-shell-for-haskell-template-0.1.0.0-0-env)
> ❯
> ```

## Setup 

:::{class="flex items-center justify-center mb-8"}
<iframe width="560" height="315" src="https://www.youtube.com/embed/1joZLTgYLxY?si=ljZLcFAIhrJ7XawV" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
:::




If you use [[home-manager]], both `nix-direnv` and `starship` can be installed using the following configuration:

```nix
# home.nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
programs.starship = {
  enable = true;
};
```

>[!tip] Newcomer Tip
> If you have never used [[home-manager]] before, we recommend that you set it up by following the instrutions at https://github.com/juspay/nixos-unified-template (which is based on [nixos-unified](https://nixos-unified.org/), thus works on macOS and Linux).


### Text Editor configuration

#### VSCode

For VSCode, use [Martin Kühl's direnv extension](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv).

#### Doom Emacs

Doom Emacs has the [`:tools` `direnv` module](https://github.com/doomemacs/doomemacs/tree/master/modules/tools/direnv) to automatically load the devshell environment when you open the project directory.

## Add a `.envrc`

To enable direnv on Flake-based projects, add the following to your `.envrc`:

```text title=".envrc"
use flake
```

Now run `direnv allow` to authorize the current `.envrc` file. You can now `cd` into the project directory in a terminal and the devshell will be automatically activated.

### Reload automatically when some files change

#### [[haskell]] - when `.cabal` files change

Since both [[nixify-haskell-nixpkgs|nixpkgs]] and [haskell-flake](https://community.flake.parts/haskell-flake) use Nix expressions that read the `.cabal` file to get dependency information, you will want the devshell be recreated every time a `.cabal` file changes. This can be achieved using the `watch_file` function. Modify your `.envrc` to contain:

```text title=".envrc"
watch_file *.cabal
use flake
```

As a result of this whenever you change a `.cabal` file, direnv will reload the environment. If you are using VSCode, you will see a notification that the environment has changed, prompting you to restart it ([see example](https://github.com/nammayatri/nammayatri/tree/main/Backend#visual-studio-code)).

## External Links

- [Effortless dev environments with Nix and direnv](https://determinate.systems/posts/nix-direnv)

[nix-direnv]: https://github.com/nix-community/nix-direnv
[home-manager]: https://github.com/nix-community/home-manager


===

<!-- Source: drv.md -->
<!-- URL: https://nixos.asia/en/drv -->
<!-- Title: Derivation -->
<!-- Wikilinks: [[drv]] -->

# Derivation

#[[nix]] derivations are instructions (recipes) for building a Nix package.

## Links

- https://zero-to-nix.com/concepts/derivations

===

<!-- Source: event.md -->
<!-- URL: https://nixos.asia/en/event -->
<!-- Title: Events -->
<!-- Wikilinks: [[event]] -->

# Events

We host events to bring together the community. Our primary venue is in [Bangalore].

## Upcoming events

```query {.timeline}
children:.
```


[Bangalore]: https://en.wikipedia.org/wiki/Bangalore


===

<!-- Source: event/nix-dev-home.md -->
<!-- URL: https://nixos.asia/en/event/nix-dev-home -->
<!-- Title: Using home-manager to manage dotfiles, packages, services -->
<!-- Wikilinks: [[event/nix-dev-home]], [[nix-dev-home]] -->

---
date: 2023-03-05
author: srid
page:
  image: event/nix-dev-home/screenshot.png
---

# Using `home-manager` to manage dotfiles, packages, services

:::{.center}
| When                                                  | Where                                             |
| ----------------------------------------------------- | ------------------------------------------------- |
| Tuesday, March 5, 2025 at 4:30PM | [Online Meetup][hasgeek] |
:::

[Sridhar Ratnakumar][srid] will demonstrate using [[nix|Nix]] to declaratively manage your **dotfiles, programs and services** using [[home-manager|home-manager]], thus replacing the likes of legacy software like homebrew. The goal is to create an **one-click environment** to setup an user environment on any system, be it a Macbook or a Linux machine.

Among the various examples, we will showcase how to configure Neovim declaratively in Nix, and have it work across platforms. In addition, we will show how to use [[direnv|direnv]] to develop projects uniformly across different machines.

RSVP links:

- [Functional Programming India][hasgeek]

See also:

- [Juspay's home-manager template](https://github.com/juspay/nix-dev-home)

![[nix-dev-home/screenshot.png]]

[srid]: https://x.com/sridca

[hasgeek]: https://hasgeek.com/fpindia/nixos-asia-home-manager/


===

<!-- Source: event/services-flake-meetup.md -->
<!-- URL: https://nixos.asia/en/event/services-flake-meetup -->
<!-- Title: services-flake: Services simplified for Dev/CI workflows -->
<!-- Wikilinks: [[event/services-flake-meetup]], [[services-flake-meetup]] -->

---
date: 2025-01-04
author: shivaraj-bh
page:
  image: event/services-flake-meetup/screenshot.png
---

# services-flake: Services simplified for Dev/CI workflows

:::{.center}
| When                                                  | Where                                             |
| ----------------------------------------------------- | ------------------------------------------------- |
| Saturday, Jan 4, 2025 at 5 PM IST | [Online meetup][jitsi]  |
:::

[Shivaraj B H][shivaraj-bh] will demonstrate using [[services-flake]] to declaratively manage service dependencies (for example, databases) of your project in the [[nix|Nix]] development environment and re-use the same configuration for testing in your CI workflow. This talk builds upon [my lightning talk from NixCon 2024][nixcon-talk], diving deeper into the topic with additional insights.

The talk serves as a video demonstration of the **Part-4** in the [[nixify-haskell]] series.

RSVP links:

- [Functional Programming India][hasgeek]

See also:

- [FP India Advent 2025](https://functionalprogramming.in/advent/2025.html)

![[services-flake-meetup/screenshot.png]]

[jitsi]: https://meet.jit.si/services-flake

[hasgeek]: https://hasgeek.com/fpindia/shivaraj-talks-about-about-nix-service-flake/

[shivaraj-bh]: https://x.com/shivaraj_bh_

[nixcon-talk]: https://talks.nixcon.org/nixcon-2024/talk/review/UTZQ8YZHKSMTUPRSC83TKALDUYNL9BCX



===

<!-- Source: event/srid-nix-dev.md -->
<!-- URL: https://nixos.asia/en/event/srid-nix-dev -->
<!-- Title: Getting Started with Nix for Haskell & Rust -->
<!-- Wikilinks: [[event/srid-nix-dev]], [[srid-nix-dev]] -->

---
date: 2023-01-23
author: srid
page:
  image: event/srid-nix-dev/vscode-haskell-template.png
---

# Getting Started with Nix for Haskell & Rust

:::{.center}
| When                             | Where                                             |
| -------------------------------- | ------------------------------------------------- |
| Tuesday, January 23, 2024 at 4PM | [IndiQube Garden, Bengaluru][map-indiqube-garden] |
:::

[Sridhar Ratnakumar][srid] will demonstrate the delights of using [[nix|Nix]] to [[dev|develop]] [[rust|Rust]] as well as [[haskell|Haskell]] projects without needing to do any manual global setup on your system. We'll start from a pristine [[macos|macOS]] machine as well as a pristine Linux machine to get our [[dev|development environment]] up and running in no time, all the way up to [LSP] support in [[vscode|VSCode]].

RSVP links:

- [The Bangalore Haskell User Group](https://www.meetup.com/the-bangalore-haskell-user-group/events/298349003)

![[vscode-haskell-template.png]]

[srid]: https://x.com/sridca
[map-indiqube-garden]: https://www.google.com/maps/place/12%C2%B056'12.0%22N+77%C2%B037'17.5%22E/@12.936661,77.62153,17z/data=!3m1!4b1!4m4!3m3!8m2!3d12.936661!4d77.62153?entry=ttu
[LSP]: https://langserver.org/


===

<!-- Source: flake-parts.md -->
<!-- URL: https://nixos.asia/en/flake-parts -->
<!-- Title: flake-parts -->
<!-- Wikilinks: [[flake-parts]] -->


# flake-parts

`flake-parts` brings the #[[modules|NixOS module system]] to #[[flakes|flakes]], thus providing a cleaner and simpler way to write otherwise complex flakes.

- Official site: https://flake.parts/ 
- Module documentation: https://community.flake.parts/


===

<!-- Source: flake-url.md -->
<!-- URL: https://nixos.asia/en/flake-url -->
<!-- Title: Flake URL -->
<!-- Wikilinks: [[flake-url]] -->


# Flake URL

A #[[flakes|flake]] can be referred to using an URL-like syntax.

## Examples

```sh
# A flake on a GitHub repo
github:srid/emanote

# A local flake at current directory
.

# Another way to refer to local flakes
path:/Users/srid/code/foo

# Full Git references is also possible:
git+https://github.com/juspay/services-flake?ref=dev
```

## Reference

- The URL-like syntax is documented [here](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#url-like-syntax).


===

<!-- Source: flakes.md -->
<!-- URL: https://nixos.asia/en/flakes -->
<!-- Title: Flakes -->
<!-- Wikilinks: [[flakes]] -->


# Flakes

Flakes is a necessary abstraction of top of #[[nix]] that improves on usability and reproducibility. Flakes is [production ready despite being marked as experimental](https://determinate.systems/posts/experimental-does-not-mean-unstable).

```query
children:.
```

## Links

- https://nixos.wiki/wiki/Flakes

===

<!-- Source: git.md -->
<!-- URL: https://nixos.asia/en/git -->
<!-- Title: Git -->
<!-- Wikilinks: [[git]] -->

# Git

Git is the most commonly used version control system for #[[dev|software development]].

## Declarative configuration

Git can be declaratively configured in [[nix]] via [[home-manager]]. [Here is](https://github.com/srid/nixos-config/blob/master/home/git.nix) an example:

```nix
{
  programs.git = {
    enable = true;
    userName = "john";
    userEmail = "john@doe.com";
    ignores = [ "*~" "*.swp" ];
    extraConfig = {
      init.defaultBranch = "master";
    };
  };
}
```

## Git related pages

```query
children:.
```


===

<!-- Source: gotchas.md -->
<!-- URL: https://nixos.asia/en/gotchas -->
<!-- Title: Gotchas -->
<!-- Wikilinks: [[gotchas]] -->

# Gotchas

#[[nix]] can behave unexpectedly in certain cases.

```query
children:.
```



===

<!-- Source: gotchas/macos-upgrade.md -->
<!-- URL: https://nixos.asia/en/gotchas/macos-upgrade -->
<!-- Title: Nix is broken after macOS upgrade -->
<!-- Wikilinks: [[gotchas/macos-upgrade]], [[macos-upgrade]] -->


# Nix is broken after macOS upgrade

Upgrading #[[macos]] is known to break [[nix]]. When this happens, just uninstall Nix and then #[[install|install]] it again.

1. Uninstall Nix
    - Run `/nix/nix-installer uninstall`
    - If that path above does not exist, [follow these instructions](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos) to manually uninstall Nix.
1. Reboot your Mac
1. [[install]]



===

<!-- Source: gotchas/nested-devshells.md -->
<!-- URL: https://nixos.asia/en/gotchas/nested-devshells -->
<!-- Title: Nested devShells can cause problems -->
<!-- Wikilinks: [[gotchas/nested-devshells]], [[nested-devshells]] -->

# Nested devShells can cause problems

cf. 
- https://github.com/NixOS/nix/issues/10388
- https://github.com/NixOS/nix/issues/6140


===

<!-- Source: gotchas/new-file.md -->
<!-- URL: https://nixos.asia/en/gotchas/new-file -->
<!-- Title: Nix does not recognize a new file I added -->
<!-- Wikilinks: [[gotchas/new-file]], [[new-file]] -->


# Nix does not recognize a new file I added

Often you'll see an error like this,

```text
error: getting status of '/nix/store/vlks3d7fr5ywc923pvqacx2bkzm1782j-source/foo': No such file or directory
```

This usually means you have not staged this new file/ directory to the Git
index. When using #[[flakes]], Nix will not see [untracked] files/ directories by default. To resolve this, just `git add -N` the untracked file/ directory.

>[!info] For further information
> https://github.com/NixOS/nix/issues/8389

[untracked]: https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository


===

<!-- Source: gotchas/sqlite-corruption.md -->
<!-- URL: https://nixos.asia/en/gotchas/sqlite-corruption -->
<!-- Title: Nix’s sqlite database is corrupted/broken -->
<!-- Wikilinks: [[gotchas/sqlite-corruption]], [[sqlite-corruption]] -->


# Nix's sqlite database is corrupted/broken

If [[nix]] throws an error like:

```text
error: getting status of '/nix/store/....drv': No such file or directory
```

You can try to fix it by running:

```sh
nix-store --verify --repair
```

===

<!-- Source: haskell-rust-ffi.md -->
<!-- URL: https://nixos.asia/en/haskell-rust-ffi -->
<!-- Title: Rust FFI in Haskell -->
<!-- Wikilinks: [[haskell-rust-ffi]] -->

---
page:
  image: haskell-rust-ffi/haskell-rust-ffi-banner.png
---

# Rust FFI in Haskell

This #[[tutorial|tutorial]] will guide you through using [[nix]] to simplify the workflow of incorporating [[rust]] library as a dependency in your [[haskell]] project via [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface). If you are new to [[nix]] and [[flakes]], we recommend starting with the [[nix-tutorial]].

> [!info] Foreign Function Interface (FFI)
> This isn't solely restricted to Haskell and Rust, it can be used between any two languages that can establish a common ground to communicate, such as C.

The objective of this tutorial is to demonstrate calling a Rust function that returns `Hello, from rust!` from within a Haskell package. Let's begin by setting up the Rust library.

:::{.center}
![[haskell-rust-ffi-banner.png]]
:::

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

The template we've initialized is a binary project, but we need a library project. The library should export a function callable from Haskell. For simplicity, let's export a function named `hello` that returns a `C-style string`. To do so, create a new file named `src/lib.rs` with the following contents and `git add src/lib.rs`:

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

Fetch `cabal-install` and `ghc` from the `nixpkgs` in [flake registry](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry.html) and initialize a new Haskell project:

```sh
nix shell nixpkgs#ghc nixpkgs#cabal-install -c cabal -- init -n --exe -m --simple hello-haskell -d base --overwrite
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
        inputs.haskell-flake.flakeModule
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

Just like any other dependency, you'll first add it to your `hello-haskell/hello-haskell.cabal` file:

```text
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

The easiest solution might seem to be `export LIBRARY_PATH=../target/debug`. However, this is not reproducible and would mean running an additional command to setup the prerequisite to build the Haskell package. Even worse if the Rust project is in a different repository. 

Often, the easiest solution isn't the simplest. Let's use Nix to simplify this process.

When you use Nix, you set up all the prerequisites beforehand, which is why you'll encounter an error when trying to re-enter the devShell without explicitly specifying where the Rust project is:

```sh
...
error: function 'anonymous lambda' called without required argument 'rust_nix_template'
...
```

To specify the Rust project as a dependency, we [setup haskell-flake dependency overrides](https://community.flake.parts/haskell-flake/dependency) by editing `hello-haskell/default.nix` to:

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

> [!note] macOS caveat
> If you are on [[macos]], the Haskell package will not run because `dlopen` will be looking for the `.dylib` file in the temporary build directory (`/private/tmp/nix-build-rust-nix...`). To fix this, you need to include [fixDarwinDylibNames](https://github.com/NixOS/nixpkgs/blob/af8fd52e05c81eafcfd4fb9fe7d3553b61472712/pkgs/build-support/setup-hooks/fix-darwin-dylib-names.sh) in `flake.nix`:
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

You can find the template at <https://github.com/shivaraj-bh/haskell-rust-ffi-template>. This template also includes formatting setup with [[treefmt|treefmt-nix]] and [[vscode]] integration.


===

<!-- Source: haskell.md -->
<!-- URL: https://nixos.asia/en/haskell -->
<!-- Title: Haskell -->
<!-- Wikilinks: [[haskell]] -->


# Haskell

For nixifying Haskell projects, see our tutorial series [[nixify-haskell]]

For a comprehensive list of ways to nixify Haskell projects, see https://nixos.wiki/wiki/Haskell

```query
children:.
```

[haskell-flake]: https://github.com/srid/haskell-flake


===

<!-- Source: hm-tutorial.md -->
<!-- URL: https://nixos.asia/en/hm-tutorial -->
<!-- Title: home-manager Tutorial Series -->
<!-- Wikilinks: [[hm-tutorial]] -->


# home-manager Tutorial Series

A tutorial series on #[[home-manager]],

- [ ] Setting it up using https://github.com/juspay/nixos-unified-template
- [ ] Basics (packages, dotfiles)
- [ ] Services (macOS and Ubuntu)


===

<!-- Source: home-manager.md -->
<!-- URL: https://nixos.asia/en/home-manager -->
<!-- Title: home-manager -->
<!-- Wikilinks: [[home-manager]] -->

Use #[[nix]] to manage your user environment.

https://github.com/nix-community/home-manager

## Getting Started

Follow the README of https://github.com/juspay/nixos-unified-template

To view help from terminal,

```sh
$ man home-configuration.nix
```

## Sub-pages

```query
children:.
```


===

<!-- Source: howto.md -->
<!-- URL: https://nixos.asia/en/howto -->
<!-- Title: HOWTO -->
<!-- Wikilinks: [[howto]] -->

# HOWTO

How to do various things with [[nix]]:

```query
children:.
```


===

<!-- Source: howto/git-profiles.md -->
<!-- URL: https://nixos.asia/en/howto/git-profiles -->
<!-- Title: Separate Git “profiles” -->
<!-- Wikilinks: [[howto/git-profiles]], [[git-profiles]] -->

# Separate Git "profiles"

You want to override #[[git|Git]] config (such as commit author email) for only certain repos, such as those under a certain folder. This is useful when dealing with corporate policies, which often block commit pushes that doesn't comfort to certain standards, such as using work email address in the commit email. Those using Bitbucket's [Control Freak](https://marketplace.atlassian.com/apps/1217635/control-freak-commit-checkers-and-jira-hooks-for-bitbucket?tab=overview&hosting=cloud) may be familiar with this error throw in response `git push`:

```text
remote:
remote: Control Freak - Commit 484b773a7e6d2ed8 rejected: bad committer metadata.
remote: -----
remote: Committer "John Doe <john.doe@gmail.com>" does not exactly match
remote: a Bitbucket user record. The closest match is:
remote:
remote:     "john.doe <john.doe@somecompany.com>"
```


{#git-config}
## Git config has a solution 

Git provides a way to solve the above problem -- by specifying configuration unique to repos whose paths match a given filepattern.  This is achieved using [the `includeIf` section](https://git-scm.com/docs/git-config#_includes) in Git config. But how do we configure this *through* Nix?

{#hm}
## Configuring in home-manager

When using #[[home-manager]], you can add the following to your `programs.git` module:

```nix
programs.git = {
  # Bitbucket git access and policies
  includes = [{
    condition = "gitdir:~/mycompany/**";
    contents = {
      user.email = "john.doe@mycompany.com";
    };
  }];
}
```

With this, any commit you make to repos under the `~/mycompany` directory will use that email address as its commit author email.

## Examples

- [srid/nixos-config: juspay.nix](https://github.com/srid/nixos-config/blob/f5388e798737d63eae4f88508f57fea0dd0b4192/home/juspay.nix)


===

<!-- Source: howto/hm-fonts.md -->
<!-- URL: https://nixos.asia/en/howto/hm-fonts -->
<!-- Title: Installing fonts using home-manager -->
<!-- Wikilinks: [[howto/hm-fonts]], [[hm-fonts]] -->

# Installing fonts using home-manager

Whether you are on #[[macos|macOS]] or [[nixos|NixOS]], you can install and setup fonts in an unified fashion with [[nix|Nix]] using #[[home-manager|home-manager]].

For e.g., to install the [Cascadia Code][cascadia] font:

```nix
{
  home.packages = [
    # Fonts
    cascadia-code
  ];

  fonts.fontconfig.enable = true;
}
```

See [this issue](https://github.com/nix-community/home-manager/issues/605) for details.

## Verify on macOS {#macos}

To confirm that the font was successfully installed on [[macos]], you can open the [Font Book][font-book] app and search for the font. They will have been installed into `~/Library/Fonts/HomeManager` folder. 

[cascadia]: https://x.com/dhh/status/1791920107637354964
[font-book]: https://support.apple.com/en-ca/guide/font-book/welcome/mac


===

<!-- Source: howto/local-flake-input.md -->
<!-- URL: https://nixos.asia/en/howto/local-flake-input -->
<!-- Title: Use a local directory as flake input -->
<!-- Wikilinks: [[howto/local-flake-input]], [[local-flake-input]] -->


# Use a local directory as flake input

A [[flake-url]] can not only be [[git]] repositories. They can also refer to local paths. If you have two projects `~/code/foo` and `~/code/bar`, and `bar` depends on `foo`, you can use the following `flake.nix` in `bar` to have it refer to the local `foo` project:

```nix
{
  inputs = {
    foo.url = "path:/Users/me/code/foo";
  };
  outputs = inputs: { ... };
}
```

>[!warning] `flake.lock`
> Whenever you modify files under `~/code/foo`, you must run update the `flake.lock` hash in `~/code/bar` by running:
>
> ```sh
> nix flake update foo
> ```
>
> The alternative is to pass `--override-input foo ~/code/foo` to `nix build` or `nix develop` commands; this will override the hash for "foo" in the `flake.lock` file.


===

<!-- Source: howto/nix-package.md -->
<!-- URL: https://nixos.asia/en/howto/nix-package -->
<!-- Title: Use a specific version of nix -->
<!-- Wikilinks: [[howto/nix-package]], [[nix-package]] -->

# Use a specific version of `nix`

You can choose to run a specific version of `nix` CLI. Now, there are several ways to do it. You can either choose to run a specific version temporarily via `nix run` or pin it permanently in your `home-manager`, `NixOS` or `nix-darwin` configuration.

## Temporarily (via `nix run`)

>[!warning] WIP

## Pinning

>[!warning] WIP

### On home-manager

>[!warning] WIP

### On NixOS

>[!warning] WIP

### On nix-darwin

>[!warning] WIP

===

<!-- Source: howto/remote-cp.md -->
<!-- URL: https://nixos.asia/en/howto/remote-cp -->
<!-- Title: Copying packages to a remote Nix store -->
<!-- Wikilinks: [[howto/remote-cp]], [[remote-cp]] -->

# Copying packages to a remote Nix store

This is useful if your local machine is powerful and you have built a number of
packages on it, but want to re-use them on another machine, without using a Nix
cache or rebuilding them.

```sh
nix copy --to ssh-ng://admin@100.96.121.13 /nix/store/???
```

If you use [nixci], this looks like:

```sh
nixci . -- --option system aarch64-linux | xargs nix copy --to ssh-ng://admin@100.96.121.13
```

[nixci]: https://github.com/srid/nixci


===

<!-- Source: howto/uninstall-nix.md -->
<!-- URL: https://nixos.asia/en/howto/uninstall-nix -->
<!-- Title: Uninstall Nix -->
<!-- Wikilinks: [[howto/uninstall-nix]], [[uninstall-nix]] -->

# Uninstall Nix

1. Run `/nix/nix-installer uninstall`
    - NOTE: If that path above does not exist, [follow these instructions](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos) to manually uninstall Nix.
1. Reboot

>[!note] Problems while deleting `Nix Store` volume on macOS
> If the installer fails to delete the `/nix/store` volume, try rebooting your mac
> and running `/nix/nix-installer uninstall` again. If that path doesn't exist, delete manually by following last step from [here](https://nixos.org/manual/nix/stable/installation/uninstall.html#macos).



===

<!-- Source: ifd.md -->
<!-- URL: https://nixos.asia/en/ifd -->
<!-- Title: Import From Derivation (IFD) -->
<!-- Wikilinks: [[ifd]] -->

# Import From Derivation (IFD)

[[nix|Nix]] expressions are *evaluated* to produce #[[drv|derivations]] (among other values). These derivations when *realized* usually produce the compiled binary packages. Sometimes, realizing a derivation can produce a Nix expression representing another derivation. This generated Nix expression too needs to be *evaluated* to its derivation before it can be *realized*. This secondary evaluation is achieved by `import`ing from the derivation being evaluated, and is called "import from derivation" or IFD. 

For detailed explanation, see [this blog post](https://blog.hercules-ci.com/2019/08/30/native-support-for-import-for-derivation/).


===

<!-- Source: index.md -->
<!-- URL: https://nixos.asia/en/ -->
<!-- Title: NixOS Asia -->
<!-- Wikilinks: [[index]] -->

# NixOS Asia

> [!tip] Welcome to NixOS Asia
> NixOS Asia is a community of [[nix]] and [[nixos]] users, promulgated initially from the Indian subcontinent.


## Explore this website

<!--

NOTE to editors:

Here, you must establish `[[..]]#` style folgezettel links which will shape our
sidebar navigation.

-->

- Start from [[install|here]] if you are new to Nix.
- Then, checkout our [[tutorial]]#
- For further reading, read [[howto]]# and [[blog]]#
- Most other pages are usually under [[topics]]#
- You can browse the rest of the content  in [the index](-/all).

## Community

You can participate in the community discussion through the following venues.

- [Zulip](https://nixos.zulipchat.com/): Zulip is a hybrid of "chat" and "forum".[^log]
- [Discord](https://discord.gg/z5rHpFa7NN)
- [Telegram](https://t.me/nixosasia)
- [Twitter / X](https://twitter.com/nixos_asia): We'll post all announcements here.
- [GitHub](https://github.com/nixos-asia)

[^log]: Public chat logs are available at [chat.nixos.asia](https://chat.nixos.asia/)

Also consider taking a look at our sister community, [Functional Programming India](https://functionalprogramming.in/).

{#contribute}
## Looking to contribute?

View *good first issues* involving [Nix][gfi-nix] or [Rust][gfi-rust].

[gfi-nix]: https://github.com/search?q=user%3Asrid+user%3Ajuspay+user%3Anixos-asia+user%3Aflake-parts+repo%3APlatonic-Systems%2Fprocess-compose-flake+created%3A%3E%3D2024+label%3A%22good+first+issue%22+language%3ANix+is%3Aopen&type=issues&ref=advsearch

[gfi-rust]: https://github.com/search?q=user%3Asrid+user%3Ajuspay+user%3Anixos-asia+user%3Aflake-parts+-repo%3Ajuspay%2Fhyperswitch+-repo%3Ajuspay%2Fsuperposition+repo%3APlatonic-Systems%2Fprocess-compose-flake+created%3A%3E%3D2024+label%3A%22good+first+issue%22+language%3ARust+is%3Aopen&type=issues&ref=advsearch

## Events

See [[event]].


===

<!-- Source: install.md -->
<!-- URL: https://nixos.asia/en/install -->
<!-- Title: Install Nix -->
<!-- Wikilinks: [[install]] -->

---
order: -1000
---

# Install Nix


>[!info] Linux
> If you prefer to use Linux, you may be interested in [[nixos-tutorial|installing NixOS]]. The following instructions are for users of other Linux distros as well as [[macos|macOS]].

Install #[[nix]] using [the unofficial installer](https://github.com/DeterminateSystems/nix-installer#the-determinate-nix-installer):[^official][^graphical]

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --no-confirm --extra-conf "trusted-users = $(whoami)"
```

After installing Nix, open a new terminal and run the [`om health`](https://omnix.page/om/health) checks,

```sh
nix run nixpkgs#omnix -- health
```

Expect to see all results in either green (or yellow).

## Next Steps

Checkout [[nix-first]] and 

- [[dev]] if you are looking to use Nix for development.
- [[home-manager]] (and [[nix-darwin]] if you are on [[macos]]) if you would like to use Nix for more than packages and [[dev|devShells]].

[^official]: You *can* use [the official installer](https://nixos.org/download). However, there are a couple of manual steps necessary:
    - As it [does not yet](https://discourse.nixos.org/t/anyone-up-for-picking-at-some-nix-onboarding-improvements/13152/4) include an uninstaller, you will have to manually uninstall Nix when the time comes ([[macos-upgrade|example]]). 
    - As it does not automatically enable [[flakes]], you will have to [manually enable it](https://nixos.wiki/wiki/Flakes).

[^graphical]: Do **not** use the graphical installer, as it will install the **proprietary** `nixd` daemon. See [here](https://old.reddit.com/r/NixOS/comments/1ndh3yd/dropping_upstream_nix_from_determinate_nix/ndgzqc8/?context=3) for details.


===

<!-- Source: jobs.md -->
<!-- URL: https://nixos.asia/en/jobs -->
<!-- Title: Nix Jobs -->
<!-- Wikilinks: [[jobs]] -->

---
order: 100
---

# Nix Jobs

A list of currently available [[nix|Nix]] jobs. 

{#juspay}
## Juspay - Nix Engineer (Remote)

>[!info] 
> Posted on May 21, 2024
>
> Hired on Jun 21, 2024

[Juspay] is looking to add a 3rd member to our Nix team. The position is **full-time and remote**.

The role primarily involves nixifying our internal projects - which are written mostly in Haskell, but also Rust, PureScript, ReScript, Python and several other languages and tools. We use [flake-parts](https://community.flake.parts/) wherever possible to provide a simpler Developer Experience. To get a sense of what you will mostly be working on, see the Nix in [nammayatri]. The role can potentially involve some Rust work as well. Contributing to Open Source is encouraged; you may view **our Open Source Nix projects** [on GitHub][oss].

The ideal candidate is:

- Motivated about writing Nix
- Cares about improving Developer Experience
- Communicates clearly & writes good documentation[^this]

To apply, send the Nix contributions you are most proud of (along with your résumé) by [email](mailto:sridhar.ratnakumar@juspay.in) or [X DM](https://x.com/sridca).


[Juspay]: https://juspay.in/careers/
[nammayatri]: https://github.com/nammayatri/nammayatri
[oss]: https://github.com/orgs/juspay/repositories?type=source&q=nix+sort%3Astars

[^this]: In additional to internal documentation, you will be encouraged to post [[tutorial|tutorials]] and write [[blog|blog posts]] on this very website.


===

<!-- Source: macos.md -->
<!-- URL: https://nixos.asia/en/macos -->
<!-- Title: macOS -->
<!-- Wikilinks: [[macos]] -->

---
order: 10
---

# macOS

[[nix]] is supported on macOS. 

>[!warning] Darwin support in nixpkgs
> macOS support in [[nixpkgs]] is not of same quality and priority as Linux. See https://github.com/NixOS/nixpkgs/issues/145230 & https://github.com/NixOS/nixpkgs/issues/116341

```query
children:.
```

===

<!-- Source: modules.md -->
<!-- URL: https://nixos.asia/en/modules -->
<!-- Title: Module System -->
<!-- Wikilinks: [[modules]] -->

# Module System

The #[[nixpkgs]] library provides a module system for [[nix]] expressions. To learn it, see our tutorial: [[nix-modules]]#.

## NixOS

[[nixos]] makes use of the module system to provide various functionality including services and programs. See https://search.nixos.org/options for a list of all available options.

## Flakes

This module system is not natively supported in [[flakes]]. However, flakes can define and use modules using [[flake-parts]].

## Links

- [Zero to Nix: Modules](https://zero-to-nix.com/concepts/nixos#modules)


===

<!-- Source: nix-darwin.md -->
<!-- URL: https://nixos.asia/en/nix-darwin -->
<!-- Title: nix-darwin -->
<!-- Wikilinks: [[nix-darwin]] -->

[nix-darwin](https://github.com/LnL7/nix-darwin) brings [[nixos]] like configuration to #[[macos]], allowing you to install packages (among doing other things) purely through #[[nix]].

===

<!-- Source: nix-first.md -->
<!-- URL: https://nixos.asia/en/nix-first -->
<!-- Title: First steps with Nix -->
<!-- Wikilinks: [[nix-first]] -->

---
order: 1
page:
  image: nix-tutorial/nix-first.png
---

# First steps with Nix

You have [[install|installed Nix]]. Now let's play with the `nix` command but without bothering to write any Nix expressions yet (we reserve that for the [[nix-rapid|next tutorial]]). In particular, we will learn how to use packages from the [[nixpkgs|nixpkgs]] repository and elsewhere.

![[nix-first.png]]

{#run}
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

{#inside-package}
## Looking inside a package

What is a Nix "package"? Technically, a Nix package is a special [[store-path]] built using instructions from a [[drv]], both of which reside in the [[store]]. To see what is contained by the `cowsay` package, look inside its [[store-path]]. To get the store path for a package (here, `cowsay`), run `nix build` as follows:

```text
$ nix build nixpkgs#cowsay --no-link --print-out-paths
/nix/store/8ij2wj5nh4faqwqjy1fqg20llawbi0d5-cowsay-3.7.0-man
/nix/store/n1lnrvgl43k6zln1s5wxcp2zh9bm0z63-cowsay-3.7.0
```

The `cowsay` [[drv]] produces two output paths, the second of which is the cowsay binary package (the first one is the separate documentation path), and if you inspect that[^tree] you will see the contents of it:

[^tree]: Incidentally, we use the [tree](https://en.wikipedia.org/wiki/Tree_\(command\)) command, rather than `ls`, to look at the directory tree, using the package from [[nixpkgs]] of course (since it may not already be installed).

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

>[!info] Nix Store & Store Paths
> `/nix/store` is a special directory representing the [[store]]. The paths inside `/nix/store` are known as [[store-path]]. Nix fundamentally is, in large part, about manipulating these store paths in a *pure* and *reproducible* fashion; [[drv]] are "recipes" that does this manipulation, and they too live in the [[store]].

{#shell}
## Shell environment

One of the powers of Nix is that it enables us to create *isolated* [[shell|shell]] environments containing just the packages we need. For eg., here's how we create a transient shell containing the "cowsay" and "[fortune](https://en.wikipedia.org/wiki/Fortune_(Unix))" packages:

```text
$ nix shell nixpkgs#cowsay nixpkgs#fortune 
❯
```

From here, you can verify that both the programs are indeed in `$PATH` as indicated by the "bin" directory in their respective [[store-path|store paths]]:

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

>[!tip] One-off command
> Instead of creating a shell environment, you can also run commands one-off using the `-c` option. The above session can equally be achieved using: 
> ```text
> nix shell nixpkgs#cowsay nixpkgs#fortune -c sh -c 'fortune | cowsay'
> ```

{#install}
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

{#nixpkgs-pin}
## How is [[nixpkgs|nixpkgs]] fetched

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

{#external-software}
## Using software outside of [[nixpkgs|nixpkgs]]

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


===

<!-- Source: nix-modules.md -->
<!-- URL: https://nixos.asia/en/nix-modules -->
<!-- Title: Introduction to module system -->
<!-- Wikilinks: [[nix-modules]] -->

---
order: 3
page:
  image: nix-tutorial/nix-modules.png
---

# Introduction to module system

Using the [[modules|module system]] is a key stepping stone to writing maintainable and shareable [[nix|Nix]] code. In this tutorial, we'll write a configuration system for the simple [lsd] command, thus *introducing* the reader to the Nix [[modules|module system]], so that they benefit from features such as configuration type checking, option documentation, and modularity. To learn more about the module system, we recommend [this video from Tweag](https://www.youtube.com/watch?v=N7hFP_40DJo) as well the article "[Module system deep dive][doc]" from nix.dev.

![[nix-tutorial/nix-modules.png]]

We shall begin by understanding the low-levels: how to use `evalModules` from [[nixpkgs|nixpkgs]] to define and use our own modules from scratch, using the aforementioned `lsd` use-case. The next tutorial in this series will go one high-level up and talk about how to work with modules across [[flakes|flakes]], using [[flake-parts]].

[doc]: https://nix.dev/tutorials/module-system/deep-dive

## A simple example

Consider the following Nix code, defined in a [[flakes|flake]]:

[[nix-modules/1/flake.nix]]
![[nix-modules/1/flake.nix]]

>[!info] Source code for this tutorial
> All source code for the Nix in this tutorial is available [here](https://github.com/nixos-asia/website/tree/master/global/nix-modules).

This is a simple flake that exposes a package (a [[writeShellApplication]] [[drv]] wrapping [lsd]), that can be [[nix-first|`nix run`ed]] to list the contents of the root directory. 

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

This program is hardcoded to do a certain thing: it can list the contents of the `/` directory. Now let's say we want to configure its behaviour but without having to modify the derivation itself.

In particular, we want our program to:
- *list a different directory*. 
- or, *show a tree view rather than a linear list*. 

Normally we can achieve this by refactoring our Nix expression to be a *function* (see `lsdFor` ⤵️) that takes arguments for these variations (`dir` and `tree` ⤵️), producing the appropriate [[drv|derivation]] as a result:

[[nix-modules/2/flake.nix]]
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

>[!tip] Case for the `lsd` module
> Our above flake is simple enough that it strictly doesn't require further refactoring. However, in larger flakes, having functions peppered throughout the project can be rather difficult to entangle; besides, we want to modular overrides and type checking, along with documentation. To this end, we'll see how to refactor the above to use the module system, and in the process we'll add more configurability to our `lsd` wrapper.

{#introduce}
## Introducing the module system

1. A Nix *module* is a specification of various `options`. 
1. When the user `imports` this module, they can assign these options. 
1. The module implementation (ie., the `config` attribute) will then use these values to produce the final expression to substitute in call site where the module gets imported. 

Modules can import each other in nested fashion; and option types can have certain merge semantics allowing you to define the same option across multiple modules.

This is a mouthful, so let's get down to the concrete details. To port our flake above, we need to define two options: `dir`, and `tree`. We will as well add a third option that is not user-setable but will be used set the resulting package.

Here's our lsd module, defined in `lsd.nix` alongside the flake. Follow along the code comments:

[[nix-modules/3/lsd.nix]]
![[nix-modules/3/lsd.nix]]

>[!info] Follow the comments
> We recommend that you follow the comments in the above Nix file to understand its structure. As always, consult [Module system deep dive][doc] to learn of all the details.

Note:

- `mkOption` is used create the option *types*
- Types used here: *str*, *bool*, *package* and *submodule*
  - A "submodule" is a nested module, with its own options/ imports and config.
- `config` gives the implementation when the user sets the options.
  - In our case, we 'output' the result in the `package` option (which cannot be set by the user, due to `readOnly = true`).

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

[[nix-modules/3/flake.nix]]
![[nix-modules/3/flake.nix]]

>[!tip] Hmm!
> You may notice that there's not much difference. If anything our new flake is *slightly* more complex, due to use of `evalModules`. The simplicity of the module system will become evident as you write more complex flakes, or if you want to share your modules or override them.

{#imports}
## Importing modules

Let's do something more interesting in the above flake. We'll create a "common settings" module, and then use that across the packages using the `imports` attribute. `evalModules` implements a type merge system that knows how to merge same attributes from multiple modules.

[[nix-modules/4/flake.nix]]
![[nix-modules/4/flake.nix]]

Compared to the 3rd flake, we have:

- In [[nix-modules/4/lsd.nix]]: a new option `long` to specify `-l` to lsd.
- In [[nix-modules/4/flake.nix]]: 
  - a new module `common` enabling the `long` option.
  - all packages now `imports` this common module, to derive the `long` option.
  - a `mkLib` functions that we will export for reuse from another flake (see below)

Now when you `nix run` these programs you will get similar output to the previous flake but with a long listing instead.

{#share}
## Sharing modules across flakes

We will create a 5th flake that re-uses module from the 4th flake above. This is a contrived example, but it demonstrates how you can share modules across flakes.

[[nix-modules/5/flake.nix]]
![[nix-modules/5/flake.nix]]

Note that,

- [[nix-modules/4/flake.nix]] outputs a `mkLib` function that gives us the `common` module along with the `lsdFor` function.
- In [[nix-modules/5/flake.nix]], we access these for re-use, thus relieving our 5th flake of having to define `lsd.nix` and the `common` module.

Our 5th flake is fairly simple, due to hiding all the implementation in an external flake (4th flake). The 5th flake contains only the "what" and not the "how" of our `lsd` packages; it tells us what to configure, hiding the implementation in an input flake (4th flake).

{#end}
## Where to go from here?

You have just read a quick introduction to the module system, in particular how to define, use and share them in [[flakes]]. To learn more about the module system, we recommend [this video from Tweag](https://www.youtube.com/watch?v=N7hFP_40DJo) as well the article "[Module system deep dive][doc]" from nix.dev. Look out for the next tutorial in this series, where we will talk about [[flake-parts]].

[lsd]: https://github.com/lsd-rs/lsd


===

<!-- Source: nix-rapid.md -->
<!-- URL: https://nixos.asia/en/nix-rapid -->
<!-- Title: Rapid Introduction to Nix -->
<!-- Wikilinks: [[nix-rapid]] -->

---
order: 2
page:
  image: nix-tutorial/nix-rapid.png
---

# Rapid Introduction to Nix


The goal of this mini-tutorial is to introduce you to [[nix|Nix]] the language, including [[flakes|flakes]], as quickly as possible while also preparing the motivated learner to dive deeper into [the whole Nix ecosystem][zero-to-nix]. At the end of this introduction, you will be able to create a #[[flakes|flake.nix]] that builds a package and provides a [[dev|developer environment]] shell.

![[nix-rapid.png]]

>[!tip] Purely functional
> If you are already experienced in [purely functional programming](https://en.wikipedia.org/wiki/Purely_functional_programming), it is highly recommended to read [Nix - taming Unix with functional programming](https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/) to gain a foundational perspective into Nix being purely functional but in the context of *file system* (as opposed to values stored in memory).
> 
> > [..] we can treat the file system in an operating system like memory in a running program, and equate package management to memory management

{#pre}
## Pre-requisites

- **Install Nix**: Nix can be [[install|installed on Linux and macOS]]. If you are using [[nixos]], it already comes with Nix pre-installed.
- **Play with Nix**: Before writing Nix expressions, it is useful to get a feel for working with the `nix` command. See [[nix-first]]

## Attrset

>[!info] To learn more
> - [Official manual](https://nixos.org/manual/nix/stable/language/values.html#attribute-set)
> - [nix.dev on attrsets](https://nix.dev/tutorials/nix-language#attribute-set)

The [Nix programming language][nix-lang] provides a lot of general constructs. But at its most basic use, it makes heavy use of *nested hash maps* otherwise called an "attrset". They are equivalent to [`Map Text a`](https://hackage.haskell.org/package/containers-0.6.7/docs/Data-Map-Strict.html#t:Map) in Haskell. The following is a simple example of an attrset:

```nix
{
  foo = {
    bar = 1;
  };
}
```

We have an outer attrset with a single key `foo`, whose value is another attrset with a single key `bar` and a value of `1`.

## repl 

Nix expressions can be readily evaluated in the [[repl|Nix repl]]. To start the repl, run `nix repl`. 

```sh
$ nix repl
Welcome to Nix 2.12.0. Type :? for help.

nix-repl>
```

You can then evaluate expressions:

```nix
nix-repl> 2+3
5

nix-repl> x = { foo = { bar = 1; }; }

nix-repl> x
{ foo = { ... }; }

nix-repl> x.foo
{ bar = 1; }

nix-repl> x.foo.bar
1

nix-repl>
```

## [[flakes|Flakes]]

>[!info] To learn more
> - [Serokell Blog: Basic flake structure](https://serokell.io/blog/practical-nix-flakes#basic-flake-structure)

A Nix [[flakes|flake]] is defined in the `flake.nix` file, which denotes an attrset containing two keys `inputs` and `outputs`. *Outputs* can reference *inputs*. Thus, changing an *input* can change the *outputs*. The following is a simple example of a flake:

```nix
{
  inputs = { };

  outputs = inputs: {
    foo = 42;
  };
}
```

This flake has zero `inputs`. `outputs` is a [function][nix-function] that takes the (realised) inputs as an argument and returns the final output attrset. This output attrset, in our example, has a single key `foo` with a value of `42`.

We can use the [`nix flake show`][nix-flake-show] command to see the output structure of a flake:

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675373998&narHash=sha256-ifNiFGU1VV784kVcssn2rXIil%2feHfMLhPfmvaELefwA=
└───foo: unknown
$
```

We can use [`nix eval`][nix-eval] to evaluate any output. For example,

```sh
$ nix eval .#foo
42
```

### Graph

A flake can refer to other flakes in its inputs. Phrased differently, a flake's outputs can be used as inputs in other flakes. The most common example is the [[nixpkgs]] flake which gets used as an input in most flakes. Intuitively, you may visualize a flake to be a node in a larger [graph], with inputs being the incoming arrows and outputs being the outgoing arrows.

[graph]: https://en.wikipedia.org/wiki/Directed_graph

### Inputs

> [!info] To learn more
> - [[flake-url|URL-like syntax]] used by the `url` attribute

Let's do something more interesting with our `flake.nix` by adding the [[nixpkgs]] input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    # Note: If you are macOS, substitute `x86_64-linux` with `aarch64-darwin`
    foo = inputs.nixpkgs.legacyPackages.x86_64-linux.cowsay;
  };
}
```

>[!note] About `nixpkgs-unstable`
> The `nixpkgs-unstable` branch is frequently updated, hence its name, but this doesn't imply instability or unsuitability for use.

The [[nixpkgs]] flake has an output called `legacyPackages`, which is indexed by the platform (called "system" in Nix-speak), further containing all the packages for that system. We assign that package to our flake output key `foo`. 

>[!tip] You can use [[repl|`nix repl`]] to explore the outputs of any flake, using TAB completion:
> 
> ```sh
> $ nix repl --extra-experimental-features 'flakes repl-flake' github:nixos/nixpkgs/nixpkgs-unstable
> Welcome to Nix 2.12.0. Type :? for help.
> 
> Loading installable 'github:nixos/nixpkgs/nixpkgs-unstable#'...
> Added 5 variables.
> nix-repl> legacyPackages.aarch64-darwin.cowsay
> «derivation /nix/store/0s2vdpkpdiljmh8y06xgdw5vg2cqfs0m-cowsay-3.7.0.drv»
> 
> nix-repl>
> ```

### Predefined outputs

Nix commands treat [certain outputs as special](https://nixos.wiki/wiki/Flakes#Output_schema). These are:

| Output      | Nix command       | Description                  |
| ----------- | ----------------- | ---------------------------- |
| `packages`  | `nix build`       | [[drv]] output               |
| `devShells` | `nix develop`     | [Development](dev.md) shells |
| `apps`      | `nix run`         | Runnable applications        |
| `checks`    | `nix flake check` | Tests and checks             |

All of these predefined outputs are further indexed by the "system" value. 

#### Packages 

>[!info] To learn more
> - [`pkgs.stdenv.mkDerivation`](https://nixos.org/manual/nixpkgs/stable/#sec-using-stdenv) can be used to build a custom package from scratch

`packages` is the most often used output. Let us extend our previous `flake.nix` to use it:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    foo = 42;
    packages.x86_64-linux = {
      cowsay = inputs.nixpkgs.legacyPackages.x86_64-linux.cowsay;
    };
  };
}
```

Here, we are producing an output named `packages` that is an attrset of systems (currently, only `x86_64-linux`) to attrsets of packages. We are definining exactly one package, `cowsay`, for the `x86_64-linux` system. 

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675374260&narHash=sha256-FRven09fX3hutGa8+dagOCSQKVYAsHI6BsnCSEQ7PG8=
├───foo: unknown
└───packages
    └───aarch64-darwin
        └───cowsay: package 'cowsay-3.7.0'
```

Notice that `nix flake show` recognizes the *type* of `packages`. With `foo`, it couldn't (hence type is `unknown`) but with `packages`, it can (hence type is "package").

The `packages` output is recognized by `nix build`.

```sh
$ nix build .#cowsay
```

The [`nix build`][nix-build] command takes as argument a value of the form `<flake-url>#<package-name>`. By default, `.` (which is a [[flake-url|flake URL]]) refers to the current flake. Thus, `nix build .#cowsay` will build the `cowsay` package from the current flake under the current system. `nix build` produces a `./result` symlink that points to the Nix store path containing the package:

```sh
$ ./result/bin/cowsay hello
 _______
< hello >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

If you run `nix build` without arguments, it will default to `.#default`.

#### Apps

A flake app is similar to a flake package except it always refers to a runnable program. You can expose the cowsay executable from the cowsay package as the default flake app:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    apps.x86_64-linux = {
      default = {
        type= "app";
        program = "${inputs.nixpkgs.legacyPackages.x86_64-linux.cowsay}/bin/cowsay";
      } ;
    };
  };
}
```

Now, you can run `nix run` to run the cowsay app, which is equivalent to doing `nix build .#cowsay && ./result/bin/cowsay` in the previous flake.

{#demo}
#### Interlude: demo

<script async id="asciicast-591420" src="https://asciinema.org/a/591420.js" data-speed="3" data-preload="true" data-theme="solarized-light" data-rows="30" data-idleTimeLimit="3"></script>

#### DevShells

> [!info] To learn more
> - [Official Nix manual][mkShell]
> - [NixOS Wiki](https://nixos.wiki/wiki/Development_environment_with_nix-shell)

Like `packages`, another predefined flake output is `devShells` - which is used to provide a [[dev|development]] shell aka. a nix [[shell|shell]] or devshell. A devshell is a sandboxed environment containing the packages and other shell environment you specify. nixpkgs provides a function called [`mkShell`][mkShell] that can be used to create devshells.

As an example, we will update our `flake.nix` to provide a devshell that contains the [jq](https://github.com/stedolan/jq) tool.

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };
  outputs = inputs: {
    foo = 42;
    devShells = {  # nix develop
      aarch64-darwin = {
        default =
          let 
            pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          in pkgs.mkShell {
            packages = [
              pkgs.jq
            ];
          };
      };
    };
  };
}
```

`nix flake show` will recognize this output as a "development environmenet":

```sh
$ nix flake show
path:/Users/srid/code/nixplay?lastModified=1675448105&narHash=sha256-dikTfYD1wbjc+vQ+IUTMXWv%2fm%2f7qb91Hk3ip5MNefeU=
├───devShells
│   └───aarch64-darwin
│       └───default: development environment 'nix-shell'
└───foo: unknown
```

Just as `packages` can be built using `nix build`, you can enter the devshell using [`nix develop`][nix-develop]:

```sh
$ nix develop
❯ which jq
/nix/store/33n0kx526i5dnv2gf39qv1p3a046p9yd-jq-1.6-bin/bin/jq
❯ echo '{"foo": 42}' | jq .foo
42
❯ 
```

Typing `Ctrl+D` or `exit` will exit the devshell.

## Conclusion

This mini tutorial provided a rapid introduction to Nix flakes, enabling you to get started with writing simple flake for your projects. Consult the links above for more information. There is a lot more to Nix than the concepts presented here! You can also read [Zero to Nix][zero-to-nix] for a highlevel introduction to all things Nix and flakes.

## See also

- [A (more or less) one page introduction to Nix, the language](https://github.com/tazjin/nix-1p)
- [Nix - taming Unix with functional programming](https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/)

[zero-to-nix]: https://zero-to-nix.com/
[nix-lang]: https://nixos.org/manual/nix/stable/language/index.html
[nix-flake-show]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-show.html
[nix-eval]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-eval.html
[nix-function]: https://nixos.org/manual/nix/stable/language/constructs.html#functions
[mkShell]: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
[exa]: https://github.com/ogham/exa
[nix-build]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html
[nix-develop]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-develop.html
[NixOS]: https://nixos.org/


===

<!-- Source: nix-tutorial.md -->
<!-- URL: https://nixos.asia/en/nix-tutorial -->
<!-- Title: Nix Tutorial Series -->
<!-- Wikilinks: [[nix-tutorial]] -->

---
order: -10
---

# Nix Tutorial Series

- [x] [[nix-first]]#
- [x] [[nix-rapid]]#
- [x] [[nix-modules]]#
- [ ] `flake-parts` tutorial


===

<!-- Source: nix.md -->
<!-- URL: https://nixos.asia/en/nix -->
<!-- Title: Nix -->
<!-- Wikilinks: [[nix]] -->

# Nix

Nix is a [purely functional](https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/) package manager that also enables reproducible development environments.

The Linux distro [[nixos]] comes with Nix pre-installed. You can [[install]] manually on other platforms.

```query
children:.
```

===

<!-- Source: nixify-haskell-flake.md -->
<!-- URL: https://nixos.asia/en/nixify-haskell-flake -->
<!-- Title: Simplify Haskell Nix configuration using haskell-flake -->
<!-- Wikilinks: [[nixify-haskell-flake]] -->

---
short-title: 2. Using haskell-flake
---

# Simplify Haskell Nix configuration using haskell-flake

>[!warning] TODO: Write this! 
> For now, see the code: https://github.com/juspay/todo-app/pull/16

Things to highlight:

- haskell-flake reduces a bunch of lines to pretty much 1
- whilst still allowing all the things you can do with raw nixpkgs infra
- it can also support other package sets, like horizon
- example projects (since todo-app has empty configuration)


===

<!-- Source: nixify-haskell-nixpkgs.md -->
<!-- URL: https://nixos.asia/en/nixify-haskell-nixpkgs -->
<!-- Title: Nixifying a Haskell project using nixpkgs -->
<!-- Wikilinks: [[nixify-haskell-nixpkgs]] -->

---
short-title: 1. Using nixpkgs only
---

# Nixifying a Haskell project using nixpkgs

Welcome to the [[nixify-haskell]] series, where we start our journey by integrating a Haskell application, particularly one using a PostgreSQL database, into a single-command deployable package. By the end of this article, you'll have a [[flakes|flake.nix]] file that's set to build the project, establish the [[dev|development environment]], and execute the Haskell application along with all its dependent services like PostgreSQL and [PostgREST]. We'll be using [todo-app](https://github.com/juspay/todo-app/tree/903c769d4bda0a8028fe3775415e9bdf29d80555) as a running case study throughout the series, demonstrating the process of building a Haskell project and effectively managing runtime dependencies, such as databases and other services, thereby illustrating the streamlined and powerful capabilities Nix introduces to Haskell development.

[PostgREST]: https://postgrest.org/en/stable

>[!warning] Pre-requisites
> - A basic understanding of the [[nix]] and [[flakes]] is assumed. See [[nix-rapid]]
> - To appreciate why Nix is a great choice for Haskell development, see [[why-dev]]

## Nixify Haskell package

Let's build a simple flake for our Haskell project, `todo-app`. Start by cloning the [todo-app](https://github.com/juspay/todo-app/tree/903c769d4bda0a8028fe3775415e9bdf29d80555) repository and checking out the specified commit.

```sh
git clone https://github.com/juspay/todo-app.git
cd todo-app
git checkout 076185e34f70e903b992b597232bc622eadfcd51
``` 

Here's a brief look at the `flake.nix` for this purpose: 

```nix title="flake.nix" 
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      overlay = final: prev: {
        todo-app = final.callCabal2nix "todo-app" ./. { };
      };
      myHaskellPackages = pkgs.haskellPackages.extend overlay;
    in
    {
      packages.${system}.default = myHaskellPackages.todo-app;
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/todo-app";
      };
    };
}
```

Now, let's dissect it.

### haskellPackages

The [official manual](https://nixos.org/manual/nixpkgs/stable/#haskell) explains the Haskell's infrastructure in [[nixpkgs]] detail. For our purposes, the main things to understand are:

- `pkgs.haskellPackages` is an attribute set containing all Haskell packages within `nixpkgs`.
- We can "extend" this package set to add our own Haskell packages. This is what we do when creating `myHaskellPackages`.
- We add the `todo-app` package to `myHaskellPackages` (a package set derived from `pkgs.haskellPackages`), and then use that when defining the flake package, `packages.${system}.default`, below.

>[!tip] Exploring `pkgs.haskellPackages`
>
> You can use [[repl]] to explore any flake's output.  In the repl session below, we locate and build the `aeson` package:
>
> ```nix
> nix repl github:nixos/nixpkgs/nixpkgs-unstable
> nix-repl> pkgs = legacyPackages.${builtins.currentSystem}
> 
> nix-repl> pkgs.haskellPackages.aeson
> «derivation /nix/store/sjaqjjnizd7ybirh94ixs51x4n17m97h-aeson-2.0.3.0.drv»
> 
> nix-repl> :b pkgs.haskellPackages.aeson
> 
> This derivation produced the following outputs:
>   doc -> /nix/store/xjvm45wxqasnd5p2kk9ngcc0jbjhx1pf-aeson-2.0.3.0-doc
>   out -> /nix/store/1dc6b11k93a6j9im50m7qj5aaa5p01wh-aeson-2.0.3.0
> ```


### callCabal2nix

We used `callCabal2nix` function from [[nixpkgs]] to build the `todo-app` package above. This functio generates a Haskell package [[drv]] from its source, utilizing the ["cabal2nix"](https://github.com/NixOS/cabal2nix) program to convert a cabal file into a Nix derivation.


### Overlay

> [!info]
> - [NixOS Wiki on Overlays](https://nixos.wiki/wiki/Overlays)
> - [Overlay implementation in fixed-points.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/fixed-points.nix)>

To _extend_ the `pkgs.haskellPackages` package set above, we had to pass what is known as an "overlay". This allows us to either override an existing package or add a new one. 

In the repl session below, we extend the default Haskell package set to override the `shower` package to be built from the Git repo instead:

```nix
nix-repl> :b pkgs.haskellPackages.shower

This derivation produced the following outputs:
  doc -> /nix/store/crzcx007h9j0p7qj35kym2rarkrjp9j1-shower-0.2.0.3-doc
  out -> /nix/store/zga3nhqcifrvd58yx1l9aj4raxhcj2mr-shower-0.2.0.3

nix-repl> myHaskellPackages = pkgs.haskellPackages.extend 
    (self: super: {
       shower = self.callCabal2nix "shower" 
         (pkgs.fetchgit { 
            url = "https://github.com/monadfix/shower.git";
            rev = "2d71ea1"; 
            sha256 = "sha256-vEck97PptccrMX47uFGjoBVSe4sQqNEsclZOYfEMTns="; 
         }) {}; 
    })

nix-repl> :b myHaskellPackages.shower

This derivation produced the following outputs:
  doc -> /nix/store/vkpfbnnzyywcpfj83pxnj3n8dfz4j4iy-shower-0.2.0.3-doc
  out -> /nix/store/55cgwfmayn84ynknhg74bj424q8fz5rl-shower-0.2.0.3
```

Notice how we used `callCabal2nix` to build a new Haskell package from the source (located in the specified Git repository).



{#together}
### Putting It All Together
<script async id="asciicast-591422" src="https://asciinema.org/a/591422.js" data-speed="3" data-preload="true" data-theme="solarized-light" data-rows="30" data-idleTimeLimit="3"></script>

{#devshell}
## Nixifying Development Shells

Our existing flake lets us _build_ `todo-app`. But what if we want to _develop_ it? Typically, Haskell development involves tools like [cabal](https://cabal.readthedocs.io/) and [ghcid](https://github.com/ndmitchell/ghcid). These tools require a GHC environment with the packages specified in the `build-depends` of our cabal file. This is where `devShell` comes in, providing an isolated environment with all packages required by the project.

Here's the `flake.nix` for setting up a development shell:

```nix title="flake.nix"
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      overlay = final: prev: {
        todo-app = final.callCabal2nix "todo-app" ./. { };
      };
      myHaskellPackages = pkgs.haskellPackages.extend overlay;
    in
    {
      devShells.${system}.default = myHaskellPackages.shellFor {
        packages = p : [
          p.todo-app
        ];
        nativeBuildInputs = with myHaskellPackages; [
          ghcid
          cabal-install
        ];
      };
    };
}
```

### shellFor

A Haskell [[dev|devShell]] can be provided in one of the two ways. The default way is to use the (language-independent) `mkShell` function (Generic shell). However to get full IDE support, it is best to use the (haskell-specific) `shellFor` function, which is an abstraction over [`mkShell`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell) geared specifically for Haskell development shells

- Every Haskell package set (such as `pkgs.haskellPackages`), exposes [`shellFor`](https://nixos.wiki/wiki/Haskell#Using_shellFor_.28multiple_packages.29) function, which returns a devShell with GHC package set configured with the Haskell packages in that package set.
- As arguments to `shellFor` - generally, we only need to define two keys `packages` and `nativeBuildInputs`. 
  - `packages` refers to *local* Haskell packages (that will be compiled by cabal rather than Nix). 
  - `nativeBuildInputs` refers to programs to make available in the `PATH` of the devShell.

### Let's run!
<script async id="asciicast-591426" src="https://asciinema.org/a/591426.js" data-speed="3" data-preload="true" data-theme="solarized-light" data-rows="30" data-idleTimeLimit="3"></script>

{#ext-deps}
## Nixifying External Dependencies

We looked at how to package a Haskell package, and thereon how to setup a development shell. Now we come to the final part of this tutorial, where we will see how to package external dependencies (like Postgres). We will demonstrate how to initiate a Postgres server using Nix without altering the global system state.

Here's the `flake.nix` for making `nix run .#postgres` launch a Postgres server:

```nix title="flake.nix"
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    apps.${system}.postgres = {
      type = "app";
      program = 
        let
          script = pkgs.writeShellApplication {
            name = "pg_start";
            runtimeInputs = [ pkgs.postgresql ];
            text = 
            ''
              # Initialize a database with data stored in current project dir
              [ ! -d "./data/db" ] && initdb --no-locale -D ./data/db

              postgres -D ./data/db -k "$PWD"/data
            '';
          };
        in "${script}/bin/pg_start";
    };
  };
}
```

This flake defines a flake app that can be run using `nix run`. This app is simply a shell script that starts a Postgres server. [[nixpkgs]] provides the convenient [[writeShellApplication]] function to generate such a script. Note that `"${script}"` provides the path in the `nix/store` where the application is located.

### Run it!
<script async id="asciicast-591427" src="https://asciinema.org/a/591427.js" data-speed="3" data-preload="true" data-theme="solarized-light" data-rows="30" data-idleTimeLimit="3"></script>

{#combine}
## Combining All Elements


Now it's time to consolidate all the previously discussed sections into a single `flake.nix`. Additionally, we should incorporate the necessary apps for `postgrest` and `createdb`. `postgrest` app will start the service and `createdb` will handle tasks such as loading the database dump, creating a database user, and configuring the database for postgREST.

```nix title="flake.nix"
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      overlay = final: prev: {
        todo-app = final.callCabal2nix "todo-app" ./. { };
      };
      myHaskellPackages = pkgs.haskellPackages.extend overlay;
    in
    {
      packages.${system}.default = myHaskellPackages.todo-app;

      devShells.${system}.default = myHaskellPackages.shellFor {
        packages = p: [
          p.todo-app
        ];
        buildInputs = with myHaskellPackages; [
          ghcid
          cabal-install
          haskell-language-server
        ];
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/todo-app";
        };
        postgres = {
          type = "app";
          program =
            let
              script = pkgs.writeShellApplication {
                name = "pg_start";
                runtimeInputs = [ pkgs.postgresql ];
                text =
                  ''
                    # Initialize a database with data stored in current project dir
                    [ ! -d "./data/db" ] && initdb --no-locale -D ./data/db

                    postgres -D ./data/db -k "$PWD"/data
                  '';
              };
            in
            "${script}/bin/pg_start";
        };
        createdb = {
          type = "app";
          program =
            let
              script = pkgs.writeShellApplication {
                name = "createDB";
                runtimeInputs = [ pkgs.postgresql ];
                text =
                  ''
                    # Create a database of your current user
                    if ! psql -h "$PWD"/data -lqt | cut -d \| -f 1 | grep -qw "$(whoami)"; then
                      createdb -h "$PWD"/data "$(whoami)"
                    fi

                    # Load DB dump
                    psql -h "$PWD"/data < db.sql

                    # Create configuration file for postgrest
                    echo "db-uri = \"postgres://authenticator:mysecretpassword@localhost:5432/$(whoami)\"
                    db-schemas = \"api\"
                    db-anon-role = \"todo_user\"" > data/db.conf
                  '';
              };
            in
            "${script}/bin/createDB";
        };
        postgrest = {
          type = "app";
          program =
            let
              script = pkgs.writeShellApplication {
                name = "pgREST";
                runtimeInputs = [ myHaskellPackages.postgrest ];
                text =
                  ''
                    postgrest ./data/db.conf
                  '';
              };
            in
            "${script}/bin/pgREST";
        };
      };
    };
}
```

For the complete souce code, visit [here](https://github.com/juspay/todo-app/tree/tutorial/1). 

>[!note] `forAllSystems`
> The source code uses [`forAllSystems`](https://zero-to-nix.com/concepts/flakes#system-specificity), which was not included in the tutorial above to maintain simplicity. Later, we will obviate `forAllSystems` and simplify the flake further using [[flake-parts]].

### Video Walkthrough
<script async id="asciicast-591435" src="https://asciinema.org/a/591435.js" data-speed="3" data-preload="true" data-theme="solarized-light" data-rows="30" data-idleTimeLimit="3"></script>


## Conclusion

This tutorial pratically demonstrated [[why-dev|why Nix is a great choice for Haskell development]]:

- **Instantaneous Onboarding**: There is no confusion about how to setup the development environment. It is `nix run .#postgres` to start the postgres server,
`nix run .#createdb` to setup the database and `nix run .#postgrest` to start the Postgrest web server. This happens in a reproducible way, ensuring every
developer gets the same environment.
- **Boosted Productivity**: The commands mentioned in the previous points in conjunction with `nix develop` is all that is needed to make a quick change
and see it in effect.
- **Multi-Platform Support**: All the commands mentioned in the previous points will work in the same way across platforms.

In the next tutorial part, we will modularize this `flake.nix` using [[flake-parts]].


===

<!-- Source: nixify-haskell-parts.md -->
<!-- URL: https://nixos.asia/en/nixify-haskell-parts -->
<!-- Title: Modularize our flake using flake-parts -->
<!-- Wikilinks: [[nixify-haskell-parts]] -->

---
short-title: 2. Using flake-parts
---

# Modularize our flake using flake-parts

>[!warning] TODO: Write this! 
> For now, see the code: https://github.com/juspay/todo-app/pull/9

Things to highlight:

- [[flake-parts]] can be used as lightweight `forAllSystems` alternative
- allows us to split top-level flake.nix into small .nix files
- allows us to define [[nix-modules|our own modules]] and use them (just like [[nixos]] options)
- nuts and bolts:
  - perSystem, and its args (`self'`, etc.)
  - `debug` option and inspecting in repl


===

<!-- Source: nixify-haskell.md -->
<!-- URL: https://nixos.asia/en/nixify-haskell -->
<!-- Title: Nixify Haskell projects -->
<!-- Wikilinks: [[nixify-haskell]] -->


# Nixify Haskell projects

This is a #[[tutorial|tutorial]] series on nixifying #[[haskell]] projects. In part 1, we will begin with using nothing but [[nixpkgs]]. In the latter parts, we'll use simplifiy our project Nix code through [haskell-flake] which builds on top of the Haskell infrastructure in [[nixpkgs]].[^other] 

1. [x] [[nixify-haskell-nixpkgs]]#
2. [ ] [[nixify-haskell-parts]]#
3. [ ] [[nixify-haskell-flake]]#
4. [ ] [[nixify-services-flake]]#

[^other]: There are also other approaches (like [haskell.nix](https://github.com/input-output-hk/haskell.nix), [stacklock2nix](https://github.com/cdepillabout/stacklock2nix)).

[haskell-flake]: https://github.com/srid/haskell-flake


===

<!-- Source: nixify-services-flake.md -->
<!-- URL: https://nixos.asia/en/nixify-services-flake -->
<!-- Title: Integrating external services using services-flake -->
<!-- Wikilinks: [[nixify-services-flake]] -->

---
short-title: 4. Using services-flake
---

# Integrating external services using services-flake

>[!warning] TODO: Write this! 
> For now, see the code: https://github.com/juspay/todo-app/pull/22

Things to highlight:

- `services-flake` provides pre-defined configurations for many services, reducing a bunch of lines to just `services.<service>.<instance>.enable = true;`
- Data directory for all services in `services-flake` is local to the project working directory, by default
- Best practices:
  - Use Unix sockets for local development and CI to avoid binding to ports (which is global to the interface)
  - Write integration tests using the reserved `test` process in `process-compose-flake`.


===

<!-- Source: nixos-install-disko.md -->
<!-- URL: https://nixos.asia/en/nixos-install-disko -->
<!-- Title: Install NixOS with disko disk partitioning -->
<!-- Wikilinks: [[nixos-install-disko]] -->

---
order: 2
page:
  image: nixos-install-disko/nixos-disko-config.jpeg
---

# Install NixOS with `disko` disk partitioning

In this second tutorial, we will walk you through the process of installing [[nixos|NixOS]]. Unlike [[nixos-install-flake|the first installation tutorial]], we will use the command line to install NixOS manually, except for using [disko] to specify disk partitions declaratively in [[nix|Nix]] itself. This is the first step toward our [[nixos-install-oneclick|next tutorial]], where we will automate the entire installation process.


[disko]: https://github.com/nix-community/disko

{#prepare}
## Prepare to install NixOS


>[!note] Minimal ISO image
> This tutorial doesn't use a [[nixos-install-flake|graphical installer]]. Instead, it uses the minimal ISO image. This is primarily because we don't want the installer to partion the disk for us. We will use [disko](https://github.com/nix-community/disko) to do that.

- Download the latest NixOS ISO from [here](https://nixos.org/download#download-nixos). Choose the "Minimal ISO image" for your architecture.
- Create a bootable USB flash drive ([instructions here](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)) 

Boot your computer from this USB flash drive, and expect to be greeted with a command line interface (CLI):

:::{.center}
![[nixos-installer-cli.jpeg]]
:::

{#partition}
## Partition the disk

Before installing NixOS, let's define our partition layout in Nix. We will follow [the official disko documentation](https://github.com/nix-community/disko/blob/master/docs/quickstart.md) and include screenshots wherever necessary. Finally, we will use flakes to manage the configuration.

{#disk-config}
### Choosing the disk configuration

Instead of creating our partition layout from scratch, we can choose one of the examples Disko itself provides (see [here](https://github.com/nix-community/disko/tree/master/example)). We will use the [hybrid](https://github.com/nix-community/disko/blob/master/example/hybrid.nix) example as it will work for both BIOS and UEFI systems.

Retrieve the disk configuration to a temporary location, calling it `disko-config.nix` (we will use it latter):

```bash
curl https://raw.githubusercontent.com/nix-community/disko/master/example/hybrid.nix -o /tmp/disko-config.nix
```

{#disk-config-edit}
### Modify the disk configuration

The above downloaded Nix file uses a hardcoded disk device. So, we need to replace it with the device name of the disk we want to install [[nixos]] on. We can use `lsblk` to find it.


:::{.center}
![[nixos-lsblk.jpeg]]
:::

In this case, the device name is `vda`. The device file is located at `/dev/vda`. We will use this to modify `disko-config.nix` we downloaded earlier.

:::{.center}
![[nixos-disko-config.jpeg]]
:::

### Run the partitioning script

The disko flake provides an app that will take our partitioning scheme defined in Nix file above, partition the specified disk device and mount it at `/mnt`. We want this to happen prior to installing NixOS. Let's do that now:

```bash
sudo nix \
  --experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko /tmp/disko-config.nix
```

Once the command completes, you should see the disk partitioned and mounted at `/mnt`:

:::{.center}
![[nixos-disko-post-partition.jpeg]]
:::

{#configuration}
## Generate initial NixOS configuration

With the disk partitioned, we are ready to follow the usual NixOS installation process. The first step is to generate the initial NixOS configuration under `/mnt`.

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```

> [!tip] Why `--no-filesystems` and `--root`?
> - The [fileSystems](https://search.nixos.org/options?channel=23.11&show=fileSystems&from=0&size=50&sort=relevance&type=packages&query=fileSystems) configuration will automatically be added by `disko`'s [nixosModule](https://nixos.wiki/wiki/NixOS_modules) (see below). Therefore, we use `--no-filesystems` to avoid generating it here. 
> - `--root` is to specify the mountpoint to generate `configuration.nix` and `hardware-configuration.nix` in. Here, our configuration will be generated in `/mnt/etc/nixos`.

{#flakeify}
## Flakeify the configuration

Before we can utilize `disko` in our generated configuration, we will [[configuration-as-flake|convert our configuration to a flake]]. This is a simple process of adding a `flake.nix` file in `/mnt/etc/nixos`:

```bash
# /mnt/etc/nixos/flake.nix
{
  inputs = {
    # NOTE: Replace "nixos-23.11" with that which is in system.stateVersion of
    # configuration.nix. You can also use latter versions if you wish to
    # upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };
  outputs = inputs@{ self, nixpkgs, ... }: {
    # NOTE: 'nixos' is the default hostname set by the installer
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      # NOTE: Change this to aarch64-linux if you are on ARM
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
```

> [!note] Make sure to change a couple of things in the above snippet:
> - Replace `nixos-23.11` with the version from [`system.stateVersion`](https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion) in your `/mnt/etc/nixos/configuration.nix`. If you wish to upgrade right away, you can also use latter versions, or use `nixos-unstable` for the bleeding edge.
> - `x86_64-linux` should be `aarch64-linux` if you are on ARM

For details, see [[configuration-as-flake]].

{#add-disko}
## Add the `disko` nixosModule

Our NixOS configuration still does not know anything about filesystems. Let's teach it just that by using the previously downloaded disko example. We do this by adding the `disko` flake input, importing its NixOS module before importing our `/tmp/disko-config.nix`.

1. Add the `disko` flake input in `/mnt/etc/nixos/flake.nix`:

    ```nix
    # In `/mnt/etc/nixos/flake.nix`
    {
      inputs = {
        disko.url = "github:nix-community/disko";
        disko.inputs.nixpkgs.follows = "nixpkgs";
      };
    }
    ```
    >[!info] Why the "follows"?
    > `disko.inputs.nixpkgs.follows = "nixpkgs";` is to ensure that `disko` uses the same version of `nixpkgs` as specified in the current flake. This avoids having two different sources of `nixpkgs` and saves space.

1. Add the `disko` nixosModule:

    ```nix
    {
      # In `outputs` of `/mnt/etc/nixos/flake.nix`
      nixosConfigurations.nixos = {
        # ...
        modules = [
          ./configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };
    }
    ```
    :::{.center}
    ![[nixos-flake-with-disko.jpeg]]
    :::

1. Move the `disko-config.nix` to the flake directory:

    ```bash
    mv /tmp/disko-config.nix /mnt/etc/nixos
    ```

1. Add the disk configuration and use GRUB:

    ```nix
    {
      # In `/mnt/etc/nixos/configuration.nix`
      imports = [
        ./hardware-configuration.nix
        ./disko-config.nix
      ];
      #boot.loader.systemd-boot.enable = true;
      #boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.efiInstallAsRemovable = true;
    }
    ```
    :::{.center}
    ![[nixos-configuration-nix-with-disko-config.jpeg]]
    :::

    >[!info]
    > The boot loader configuration above is compatible with both BIOS and UEFI systems. Additionally, BIOS also requires [boot.loader.grub.device](https://search.nixos.org/options?channel=23.11&show=boot.loader.grub.device&from=0&size=50&sort=relevance&type=packages&query=boot.loader.grub.device) to be set which is done by `disko`'s `nixosModule`.

Let's check that our final configuration is correct by using [[repl]]. In particular, we test the `fileSystems` set by `disko`:

```sh
# First, create a flake.lock
sudo nix --experimental-features "nix-command flakes" flake lock

# Start repl
nix --experimental-features "nix-command flakes" repl
```

:::{.center}
![[nixos-disko-filesystems.jpeg]]
:::

If you see something similar to the above, everything's good and we are ready to perform the actual installation.

{#install}
## Install NixOS

With our NixOS configuration in place, we will use the `nixos-install` program to install NixOS:

```bash
sudo nixos-install --root /mnt --flake '/mnt/etc/nixos#nixos'
# NOTE: You will be prompted to set the root password at this point.
sudo reboot
```

Once rebooted, you should be greeted with the NixOS login screen, allowing you to login to the machine using the root password you had set.

{#bonus}
## Bonus steps

This tutorial focused mostly on [disko], but left some of the things covered in [[nixos-install-flake|the previous tutorial]] which you might want to consider:

- [Move configuration to home dir](configuration-as-flake.md#homedir)
- [Store the configuration on Git](nixos-install-flake.md#git)
- [Enable flakes](nixos-install-flake.md#enable-flakes)

{#video}
## Video walkthrough

<center>
<blockquote class="twitter-tweet" data-media-max-width="560"><p lang="en" dir="ltr">Video demo of the install ⤵️ <a href="https://t.co/KJLntZ6CrY">pic.twitter.com/KJLntZ6CrY</a></p>&mdash; Sridhar Ratnakumar (@sridca) <a href="https://twitter.com/sridca/status/1759599633397920219?ref_src=twsrc%5Etfw">February 19, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</center>

{#end}
## Recap & next steps

You now have a reproducible disk partitioning scheme. This does come at the cost of a few extra manual steps, but you can automate them with a script. Which is what we will do in [[nixos-install-oneclick|the next tutorial]]. We will use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) to automate the steps above and eliminate the need for a USB flash drive (assuming you have a working Linux system or are booted into a rescue image).


===

<!-- Source: nixos-install-flake.md -->
<!-- URL: https://nixos.asia/en/nixos-install-flake -->
<!-- Title: Install NixOS with Flake configuration on Git -->
<!-- Wikilinks: [[nixos-install-flake]] -->

---
order: 1
page:
  image: nixos-install-flake/nixos-install-flake.png
---

# Install NixOS with Flake configuration on Git

This tutorial will walk you through the steps necessary to install [[nixos|NixOS]], enable [[flakes|flakes]] while tracking the resulting system configuration in a [[git|Git]] repository.

>[!info] Welcome to the tutorial series on [[nixos]]
> This page is the first in a planned series of tutorials aimed towards onboarding Linux/macOS users into comfortably using [[nixos]] as their primary operating system.

![[nixos-install-flake.png]]

{#prepare}
## Prepare to install NixOS

- Download the latest NixOS ISO from [here](https://nixos.org/download#download-nixos). Choose the GNOME (or Plasma) graphical ISO image for the appropriate CPU architecture. 
- Create a bootable USB flash drive ([instructions here](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)) and boot the computer from it.

NixOS will boot into a graphical environment with the installer already running. 

:::{.center}
![[nixos-installer.png]]
:::

Go through the installation wizard; it is fairly similar to other distros. Once NixOS install is complete, reboot into your new system. You will be greeted with a login screen. 

- Login as the user you created with the password you set during installation. 
- Then open the "Console" application from the "Activities" menu.

{#edit}
## Your first `configuration.nix` change


Your systems configuration includes everything from partition layout to kernel version to packages to services. It is defined in `/etc/nixos/configuration.nix`. The `/etc/nixos` directory looks like this:

```sh
$ ls -l /etc/nixos
-rw-r--r-- 1 root root 4001 Dec  9 16:03 configuration.nix
-rw-r--r-- 1 root root 1317 Dec  9 15:43 hardware-configuration.nix

```

>[!info] What is `hardware-configuration.nix`?
> Hardware specific configuration (eg: disk partitions to mount) are defined in `/etc/nixos/hardware-configuration.nix` which is `import`ed, as a [[modules|module]], by `configuration.nix`.

All system changes require a change to this `configuration.nix`. For example, in order to "install" or "uninstall" a package, we would edit this `configuration.nix` and activate it. Let's do this now to install the [neovim](https://neovim.io/) text editor. NixOS includes the nano editor by default:

```sh
sudo nano /etc/nixos/configuration.nix
```

>[!tip] Nix language
> These `*.nix` files are written in the [[nix]] language.

In the text editor, make the following changes:

- Add `neovim` under `environment.systemPackages`
- [Optional] uncomment `services.openssh.enable = true;` to enable the SSH server

Press <kbd>Ctrl+X</kbd> to exit nano.

Your `configuration.nix` should now look like:

```nix
# /etc/nixos/configuration.nix
{
  ...
  environment.systemPackages = with pkgs; [
    neovim
  ];
  ...
  services.openssh.enable = true;
  ...
}
```

Once the `configuration.nix` file has been saved to disk, you must activate that new configuration using the [nixos-rebuild](https://nixos.wiki/wiki/Nixos-rebuild) command:

```sh
sudo nixos-rebuild switch
```

This will take a few minutes to complete―as it will have to fetch neovim and its dependencies from the official [[cache|binary cache]] (`cache.nixos.org`). Once it is done, you should expect to see something like this:

:::{.center}
![[nixos-rebuild-switch.png]]
:::

You can confirm that neovim is installed by running `which nvim`:

```sh
$ which nvim
/run/current-system/sw/bin/nvim
```

>[!tip] Remote access
> Now that you have OpenSSH enabled, you may do the rest of the steps from another machine by ssh'ing to this machine.

{#flakeify}
## Flakeify

![[configuration-as-flake]]

Let's [[configuration-as-flake|store our whole configuration]]# in a [[git]] repository.

{#git}
## Store the configuration in Git

First we need to install [[git]]: 
- add `git` to `environment.systemPackages`, and 
- activate your new configuration using `sudo nixos-rebuild switch --flake .`. 
 
Then, create a Git repository for your configuration:


```sh
$ cd ~/nixos-config
$ git config --global user.email "srid@srid.ca"
$ git config --global user.name "Sridhar Ratnakumar"
$ git init && git add . && git commit -m init
```

You may now [create a repository](https://docs.github.com/en/get-started/quickstart/create-a-repo) on GitHub or your favourite Git host, and push your configuration repo to it. 

>[!info] Benefits of storing configuration on Git
> - If you buy a new computer, and would like to reproduce your NixOS setup, all you have to do is clone your configuration repo, adjust your `hardware-configuration.nix` and run `sudo nixos-rebuild switch --flake .`. 
> - Version controlling configuration changes makes it straightforward to point out problems and/or rollback to previous state.


{#enable-flakes}
## Enable flakes

As a final step, let's permanently enable [[flakes]] on our system, which is particularly useful if you do a lot of [[dev|software development]]. This time, instead of editing `configuration.nix` again, let's do it in a separate [[modules|module]] (for no particular reasons other than pedagogic purposes). Remember the `modules` argument to `nixosSystem` function in our `flake.nix`? It is a list of modules, so we can add a second module there:

```diff
diff --git a/flake.nix b/flake.nix
index cc77fb9..4e84bdf 100644
--- a/flake.nix
+++ b/flake.nix
@@ -8,7 +8,14 @@
     # NOTE: 'nixos' is the default hostname
     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
-      modules = [ ./configuration.nix ];
+      modules = [
+        ./configuration.nix
+        {
+          nix = {
+            settings.experimental-features = [ "nix-command" "flakes" ];
+          };
+        }
+      ];
     };
   };
 }
```

>[!tip] NixOS options
> You can see all the available options for NixOS in the [NixOS options](https://search.nixos.org/options) search engine.

As before, we must activate the new configuration using `sudo nixos-rebuild switch --flake .`. Once that is done, we can verify that flakes is enabled by re-running `nix flake show` but without the `--extra-experimental-features` flag:

```sh
$ nix flake show
warning: Git tree '/home/srid/nixos-config' is dirty
git+file:///home/srid/nixos-config
└───nixosConfigurations
    └───nixos: NixOS configuration
```

## Recap

You have successfully installed NixOS. The entire system configuration is also stored in a Git repo, and can be reproduced at will during either a reinstallation or a new machine purchase. You can make changes to your configuration, commit them to Git, and push it to GitHub. Additionally we enabled [[flakes]] permanently, which means you can now use all the modern `nix` commands, such as running a package directly from [[nixpkgs]] (same version pinned in `flake.lock` file):

:::{.center}
![[nixos-pony.png]]
:::


{#end}
## Up Next

In [[nixos-install-disko|the next tutorial]], we will automate the install process a bit by declaratively specifying our disk partitioning in Nix.



===

<!-- Source: nixos-install-oneclick.md -->
<!-- URL: https://nixos.asia/en/nixos-install-oneclick -->
<!-- Title: Install NixOS directly from a remote flake -->
<!-- Wikilinks: [[nixos-install-oneclick]] -->

---
order: 3
---

# Install NixOS directly from a remote flake

>[!WARNING] WIP
> This tutorial has not been completed yet.

Unlike the previous tutorials ([[nixos-install-flake|1]]; [[nixos-install-disko|2]]), the goal here is to near-fully automate our NixOS install using one command (see the next section).

{#install}
## How to install

Boot your computer from any NixOS install live CD ([Minimal ISO image](https://nixos.org/download/#nixos-iso) is sufficient), and then from the terminal run:

>[!NOTE] Flake template? 
> Move this template to [flake-parts/templates](https://github.com/flake-parts/templates) and guide users as to how to [override](https://github.com/flake-parts/templates/issues/2) it (to set `system`, hostname and root user's authorized ssh key)?

```sh
# Assuming
# - your system is x86_64-linux
# - your harddrive device is /dev/sda
FLAKE="github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick"
DISK_DEVICE=/dev/sda
sudo nix \
    --extra-experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "$FLAKE" \
    --write-efi-boot-entries \
    --disk main "$DISK_DEVICE"
```

Here, `"github:nixos-asia/website?dir=global/nixos-install-oneclick#oneclick"` is [our own sample configuration](https://github.com/nixos-asia/website/tree/master/global/nixos-install-oneclick) flake. Feel free to substitute it with your own flake.

If everything goes well, you should see the installation successfully finish with a message like below:

```text
...
Random seed file /boot/loader/random-seed successfully written (32 bytes).
Successfully initialized system token in EFI variable with 32 bytes.
Created EFI boot entry "Linux Boot Manager".
installation finished!
```

1. Take note of the IP address of your machine using `ifconfig`.
1. Reboot your computer (or VM)! Expect to boot into NixOS.
1. Test ssh access using `ssh root@<ip-addr>`

## User management

The above flake is meant to be used on a server. As such, it authorizes root access through SSH keys.

- [ ] If you are setting up a desktop, you may have to ...

## Making further changes to the flake

- [ ] After install, how do we make further changes to the flake and apply that configuration? Can we simplify this?


This worked:

```sh
[root@oneclick:~]# git clone https://github.com/nixos-asia/website.git

[root@oneclick:~]# cd website/global/nixos-install-oneclick/

[root@oneclick:~/website/global/nixos-install-oneclick]# sudo nixos-rebuild switch --flake .
```


===

<!-- Source: nixos-tutorial.md -->
<!-- URL: https://nixos.asia/en/nixos-tutorial -->
<!-- Title: NixOS Tutorial Series -->
<!-- Wikilinks: [[nixos-tutorial]] -->

---
order: -7
---

# NixOS Tutorial Series

- [x] **Installation**

  Choose from *one of* the following ways to install [[nixos]]:
    
  | Tutorial                        | Description                                                             |
  | ------------------------------- | ----------------------------------------------------------------------- |
  | [x] [[nixos-install-flake]]#    | Install NixOS the easy way, using graphical installer                   |
  | [x] [[nixos-install-disko]]#    | Partially automated install; disko used for automatic disk partitioning |
  | [ ] [[nixos-install-oneclick]]# | Fully automated install using an *existing* configuration               |
- [ ] Basics
- [ ] Services

===

<!-- Source: nixos.md -->
<!-- URL: https://nixos.asia/en/nixos -->
<!-- Title: NixOS -->
<!-- Wikilinks: [[nixos]] -->

# NixOS

NixOS is a Linux distribution based on the [[nix]] package manager. 

## Getting Started

See [[nixos-tutorial]]#

```query
children:.
```

===

<!-- Source: nixpkgs.md -->
<!-- URL: https://nixos.asia/en/nixpkgs -->
<!-- Title: nixpkgs -->
<!-- Wikilinks: [[nixpkgs]] -->

nixpkgs (<https://github.com/NixOS/nixpkgs>) is a monorepo containing a collection of #[[nix]] packages. It also includes various utility Nix functions (like [[writeShellApplication]]#), as well as the [[nixos]] Linux distribution (including the [[modules]]).

In [[flakes|flakes]], nixpkgs is the most commonly used input.

## Links

- [Zero to Nix: nixpkgs](https://zero-to-nix.com/concepts/nixpkgs)


===

<!-- Source: process-compose-flake.md -->
<!-- URL: https://nixos.asia/en/process-compose-flake -->
<!-- Title: process-compose-flake -->
<!-- Wikilinks: [[process-compose-flake]] -->

# process-compose-flake

[process-compose-flake](https://community.flake.parts/process-compose-flake) is a #[[flake-parts]] module for [process-compose](https://github.com/F1bonacc1/process-compose).


===

<!-- Source: registry.md -->
<!-- URL: https://nixos.asia/en/registry -->
<!-- Title: Flake registry -->
<!-- Wikilinks: [[registry]] -->


# Flake registry

Global registry of #[[flakes|Nix flakes]]

https://github.com/NixOS/flake-registry



===

<!-- Source: repl.md -->
<!-- URL: https://nixos.asia/en/repl -->
<!-- Title: nix repl -->
<!-- Wikilinks: [[repl]] -->

# nix repl

`nix repl` starts an interactive environment for evaluating #[[nix]] expressions

https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-repl.html

## Tips

- To load a [[flakes|flake]], use `:lf <flake-url>`

===

<!-- Source: rust.md -->
<!-- URL: https://nixos.asia/en/rust -->
<!-- Title: Rust -->
<!-- Wikilinks: [[rust]] -->


# Rust

There are several ways to provide packaging and [[dev|development enviornment]] for Rust projects.

Here's a simple template to begin with:
- https://github.com/srid/rust-nix-template

## `buildRustPackage`

If you just want to package a Rust program, use [[buildRustPackage]]#.

## Crane

You may also be interested in using [crane] for advanced projects. Some example projects that do this:

| Project                                         | Description   |
| ----------------------------------------------- | ------------- |
| https://github.com/srid/dioxus-desktop-template | A desktop app |
| https://github.com/srid/nixci                   | A CLI app     |

[crane]: https://crane.dev/

===

<!-- Source: services-flake.md -->
<!-- URL: https://nixos.asia/en/services-flake -->
<!-- Title: services-flake -->
<!-- Wikilinks: [[services-flake]] -->


# services-flake

[services-flake](https://community.flake.parts/services-flake) provides declarative, composable, and reproducible services for [[dev|Nix development environment]], and is based on #[[flake-parts|flake-parts]]. Enabling users to have [[nixos|NixOS]]-like service on [[macos|macOS]] and Linux.


===

<!-- Source: shell.md -->
<!-- URL: https://nixos.asia/en/shell -->
<!-- Title: Nix Shell -->
<!-- Wikilinks: [[shell]] -->


# Nix Shell


A non-flake version of documentation on #[[nix]] shell can be found [here](https://nix.dev/tutorials/first-steps/declarative-shell).


===

<!-- Source: store-path.md -->
<!-- URL: https://nixos.asia/en/store-path -->
<!-- Title: Store path -->
<!-- Wikilinks: [[store-path]] -->


# Store path

https://zero-to-nix.com/concepts/nix-store#store-paths

===

<!-- Source: store.md -->
<!-- URL: https://nixos.asia/en/store -->
<!-- Title: Nix Store -->
<!-- Wikilinks: [[store]] -->


# Nix Store

The directory used by #[[nix|Nix]] to store [[store-path|store paths]]# (including [[drv|derivations]]).

https://zero-to-nix.com/concepts/nix-store


===

<!-- Source: topics.md -->
<!-- URL: https://nixos.asia/en/topics -->
<!-- Title: Topics -->
<!-- Wikilinks: [[topics]] -->


# Topics

In addition to [[tutorial]], we also have [atomic](https://neuron.zettel.page/atomic) notes on various concepts. Here are the top-level entry points to them:

- [[nix]]#
- [[nixos]]#
- [[macos]]#


===

<!-- Source: traceVerbose.md -->
<!-- URL: https://nixos.asia/en/traceVerbose -->
<!-- Title: traceVerbose -->
<!-- Wikilinks: [[traceVerbose]] -->


# `traceVerbose`

[Nix 2.10](https://nixos.org/manual/nix/stable/release-notes/rl-2.10) introduced a new function, `builtins.traceVerbose`, that works like `builtins.trace` but is no-op until the user explicitly enables it.

For eg., running `nix build` will not cause `traceVerbose` to have any effect. But if you run `nix build --trace-verbose`, then logs from `traceVerbose` will be printed to the console.

## Examples

- haskell-flake uses this to [provide conditional logging](https://community.flake.parts/haskell-flake/debugging)

#[[howto]]


===

<!-- Source: treefmt.md -->
<!-- URL: https://nixos.asia/en/treefmt -->
<!-- Title: Auto formatting using treefmt-nix -->
<!-- Wikilinks: [[treefmt]] -->

# Auto formatting using `treefmt-nix`

[treefmt](https://github.com/numtide/treefmt) provides an interface to run multiple [code formatters](https://en.wikipedia.org/wiki/Prettyprint) at once, so you don't have to run them manually for each file type in your #[[dev|development]] project.

## Writing the Nix to configure treefmt in your project

### Add treefmt and flake-root to your inputs

The [`flake-root`](https://github.com/srid/flake-root) #[[flake-parts]] module is needed to find the root of your project based on the presence of a file, by default it is `flake.nix`. 

```nix
{
  # Inside `inputs`
  treefmt-nix.url = "github:numtide/treefmt-nix";
  flake-root.url = "github:srid/flake-root";
}
```

### Import `flakeModule` output of treefmt and flake-root

```nix
{
  # Inside outputs' `flake-parts.lib.mkFlake` 
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.flake-root.flakeModule
  ];
}
```

### Configure your formatter

To actually enable the individual formatters you want to configure treefmt. The example configuration below only consists of formatters required by a haskell project using nix. Refer to [treefmt-doc](https://numtide.github.io/treefmt/formatters/) for more formatters.

```nix
{
  # Inside mkFlake's `perSystem`
  treefmt.config = {
    inherit (config.flake-root) projectRootFile;
    # This is the default, and can be overriden.
    package = pkgs.treefmt;
    # formats .hs files (fourmolu is also available)
    programs.ormolu.enable = true;
    # formats .nix files
    programs.nixpkgs-fmt.enable = true;
    # formats .cabal files
    programs.cabal-fmt.enable = false;
    # Suggests improvements for your code in .hs files
    programs.hlint.enable = false;
  };
}
```

### Add treefmt to your devShell

Finally, add the resulting treefmt wrapper (`build.wrapper`) to your devShell. We also add the individual formatters (`build.programs`) to the devShell, so that they can be used directly in text editors and IDEs.

```nix
{
  # Inside mkFlake's `perSystem`
  haskellProjects.default = {
    devShell.tools = _: {
      treefmt = config.treefmt.build.wrapper;
    } // config.treefmt.build.programs;
  };
}
```

### Flake check

The `treefmt-nix` flake module automatically adds a flake check that can be evaluated to make sure that the project is already autoformatted.

## Tips

### Exclude folders

If there are folders where you wouldn't want to run the formatter on, use the following:

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  settings.formatter.<formatter-name>.excludes = [ "./foo/*" ];
```

### Use a different package for formatter

The package shipped with the current [[nixpkgs]] might not be the desired one, follow the snippet below to override the package (assuming `nixpkgs-21_11` is present in your flake's inputs).

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  programs.ormolu.package = nixpkgs-21_11.haskellPackages.ormolu;
```
The same can be applied to other formatters.

### Pass additional parameters to your formatter

You might want to change a certain behaviour of your formatter by overriding by passing the input to the executable. The following example shows how to pass `ghc-opt` to ormolu:

```nix
  # Inside mkFlake's `perSystem.treefmt.config`
  settings.formatter.ormolu = {
    options = [
      "--ghc-opt"
      "-XTypeApplications"
    ];
  };
```

Ormolu requires this `ghc-opt` because unlike a lot of language extensions which are enabled by default, there are some which aren't. These can be found using `ormolu --manual-exts`.

## Example

- [Sample treefmt config for your haskell project](https://github.com/srid/haskell-template/blob/a8b6d1f547d761ba392a31e644494d0eeee49c2a/flake.nix#L38-L55)

## Upcoming

- `treefmt` will provide a pre-commit mode to disable commit if formatting checks fail. This is tracked here: https://github.com/numtide/treefmt/issues/78


===

<!-- Source: tutorial.md -->
<!-- URL: https://nixos.asia/en/tutorial -->
<!-- Title: Tutorials -->
<!-- Wikilinks: [[tutorial]] -->

---
order: -100
---

# Tutorials

>[!warning] WIP
> Our tutorials are being written.

> [!note] Structure of these tutorials
> Our tutorials are deliberately designed to give a quick overview of a topic, and then link to other resources for further reading. Think of them as providing a "guided tour" of the topic in question, as well as providing a learning progression.

- [[nix-tutorial]]#
- [[nixos-tutorial]]#
- [[hm-tutorial]]#
- [[dev]] tutorial series
  - [[nixify-haskell]]
  - [[haskell-rust-ffi]]
- [ ] CI/CD tutorial series



===

<!-- Source: vscode.md -->
<!-- URL: https://nixos.asia/en/vscode -->
<!-- Title: VSCode -->
<!-- Wikilinks: [[vscode]] -->

# VSCode

[Visual Studio Code](https://code.visualstudio.com/) is a popular open source code editor from Microsoft with extension support. 

{#nix}
## Using in [[nix|Nix]] based projects

If your project provides a [[flakes|flake.nix]] along with a #[[dev|development]] shell, it can be developed on VSCode using one of the two ways (prefer the 2nd way):

1. Open VSCode [from a terminal][vscode-term], inside of a [[shell|devshell]] (i.e., `nix develop -c code .`), **or**
2. Setup [[direnv|direnv]] and install the [direnv VSCode extension][direnv-ext].

>[!tip] The `.vscode` folder
> You can persist Nix related extensions & settings for VSCode in the project root's `.vscode` folder (see [example](https://github.com/srid/haskell-template/tree/master/.vscode)). This enables other people working on the project to inherit the same environment as you.

{#direnv}
### Working on `direnv`-activated projects

If you use [[direnv|direnv]], it is rather simple to get setup with VSCode:

Once you have cloned your project repo and have activated the direnv environment (using `direnv allow), you can open it in VSCode to develop it:

- Launch [VSCode](https://code.visualstudio.com/), and open the `git clone`’ed project directory [as single-folder workspace](https://code.visualstudio.com/docs/editor/workspaces#_singlefolder-workspaces)
    - NOTE: If you are on Windows, you must use the [Remote - WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) to open the folder in WSL.
- When prompted by VSCode, install the [workspace recommended](https://code.visualstudio.com/docs/editor/extension-marketplace#_workspace-recommended-extensions) extensions.
    - If it doesn’t prompt, press Cmd+Shift+X and search for `@recommended` to install them all manually.
- Ensure that the direnv extension is fully activated. You should expect to see this in the footer of VSCode: ![image](https://user-images.githubusercontent.com/3998/235459201-f0442741-294b-40bc-9c65-77500c9f4f1c.png)
- For Haskell projects: Once direnv is activated (and only then) open a Haskell file (`.hs`). You should expect haskell-language-server to startup, as seen in the footer: ![image](https://user-images.githubusercontent.com/3998/235459551-7c6c0c61-f4e8-41f3-87cf-6a834e2cdbc7.png)
    - Once this processing is complete, all IDE features should work.
    - The experience is similar for other languages; for Rust, it will be rust-analyzer.

 To give this a try, here are some sample repos:

 - Haskell: https://github.com/srid/haskell-template
 - Rust: https://github.com/srid/rust-nix-template


[vscode-term]: https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line
[direnv-ext]: https://marketplace.visualstudio.com/items?itemName=mkhl.direnv


===

<!-- Source: why-dev.md -->
<!-- URL: https://nixos.asia/en/why-dev -->
<!-- Title: Why Choose Nix for develoment? -->
<!-- Wikilinks: [[why-dev]] -->


# Why Choose Nix for develoment?

Why opt for [[nix]] when #[[dev|developping]] a software project instead of language-specific alternatives (such as Stack or GHCup for [[haskell]])?

- **Instantaneous Onboarding**: Typical project READMEs detail environment setup instructions that often fail to work uniformly across different developers' machines, taking hours or even days to configure. Nix offers an instant and reproducible setup, allowing any newcomer to get their development environment ready swiftly with one command.
- **Boosted Productivity**: Developers can dedicate more time to writing software, as Nix ensures a fully functional development environment through `nix develop`.
- **Multi-Platform Support**: The same configuration reliably works across [[macos]], Linux, and WSL.

>[!note] macOS support
> While [[macos]] doesn't enjoy first-class support in [[nixpkgs]] yet, [improvements are underway](https://github.com/NixOS/nixpkgs/issues/116341).



===

<!-- Source: writeShellApplication.md -->
<!-- URL: https://nixos.asia/en/writeShellApplication -->
<!-- Title: writeShellApplication -->
<!-- Wikilinks: [[writeShellApplication]] -->

# `writeShellApplication`

The recommended way to create [[drv]] using shell scripts.

https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellApplication

- The function generates a [[drv]] for a shell script specified as the value for `text` attribute. 
- `runtimeInputs`: packages to be made available to the shell application's PATH.
- Uses [shellcheck](https://github.com/koalaman/shellcheck) to statically analyze your bash script for issues.

## Examples

- [In hackage server](https://github.com/srid/haskell-flake/discussions/330)
