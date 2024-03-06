---
author: shivaraj
date: 2023-03-05
page:
  image: replacing-docker-compose/ny-services-flake.png
---

# Replacing docker-compose with Nix for development

Ever since I first started using [[nix|Nix]] for #[[dev|development]], I have enjoyed the [[why-dev|simplicity of setup]]: `nix develop`, make the code change and see it work. That's all well and good, but when your project keeps growing, you need to depend on external services like databases, message brokers, etc. And then, a quick search will tell you that [docker](https://www.docker.com/) is the way to go. You include it, [add one more step](https://github.com/nammayatri/nammayatri/tree/f056bb994fbf9adefa454319032ca35c34ea65bc/Backend#other-tools) in the setup guide, increasing the barrier to entry for new contributors. Not to mention, eating up all the system resources[^native-macos] on my not so powerful, company-provided MacBook.

This, along with the fact that we can provide one command to do more than just running external services (more about this at the end of the post), made us want to replace [docker-compose](https://docs.docker.com/compose/) with Nix in [Nammayatri](https://github.com/nammayatri/nammayatri) (Form now on, I'll use 'NY' as the reference for it).

> [!note] Nammayatri
> [NY](https://nammayatri.in) is an open-source auto rickshaw booking platform, based in India.

[^native-macos]: The high resource consumption is due to docker running the containers on a VM, there is an [initiative to run containers natively on macOS](https://github.com/macOScontainers/homebrew-formula), but it is still in alpha and [requires a lot of additional steps](https://github.com/macOScontainers/homebrew-formula?tab=readme-ov-file#installation) to setup. One such step is [disabling SIP](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection#3599244), which a lot of company monitored devices might not be allowed to do.

{#what-does-it-take}

## What does it take?

Turns out, there is not a lot of things that we need to do: we need to be able to run services natively, across platforms (so that my macOS doesn't drain its battery running a database), and integrate with the existing [flake.nix](https://github.com/nammayatri/nammayatri/blob/main/flake.nix) (to avoid an extra step in the setup guide).

If you've ever used [[nixos|NixOS]] before, you might be familiar with the way services are managed. Let's take a quick look at an example to understand if that will help us arrive at a solution for our problem.

{#nixos-services}

## NixOS services

Running services in NixOS is a breeze. For example, [running a PostgreSQL Database](https://nixos.wiki/wiki/PostgreSQL) is as simple as adding one line to your configuration:

```nix
{
  services.postgresql.enable = true;
}
```

This starts the database natively, with a global data directory, without the need for a container. That's great. What we need, however, is the same simplicity but with a project-specific data directory, applicable to macOS and other Linux distributions.

{#nixos-like-services}

## cross-platform nixos-like services

In the last section, we saw how easy it is to run services in NixOS. We are looking for something similar for our development environment that runs across platforms. Additionally, the solution should:

- Allow for running multiple instances of the same service (NY uses multiple instances of PostgreSQL and Redis).
- Ensure that services and their data are project-specific.

These were the exact problems #[[services-flake]] was designed to solve. Along with running services natively, it also [integrates with your project's `flake.nix`](https://community.flake.parts/services-flake/start).

{#services-flake}

## services-flake

How does [[services-flake]] solve them?

- It uses [[flake-parts]] for the [[modules|module system]] (that's the simplicity aspect), and [[process-compose-flake]] for managing services, along with providing a TUI app to monitor them.
- To address the need for running multiple instances, services-flake exports a [`multiService` library function](https://github.com/juspay/services-flake/blob/e0a1074f8adb68c06b847d34b260454a18c0697c/nix/lib.nix#L7-L33).
- By default, the data of each service is stored under `./data/<service-name>`, where `./` refers to the path where the process-compose app, exported by the project [[flakes|flake]] is run (usually in the project root).

{#let-s-get-started}

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

## Up next

Sharing [[services-flake]] modules deserves a separate post, so we will delve into this topic more in the next post.
