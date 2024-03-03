# Replacing docker-compose with Nix for development

Ever since I first started using [[nix]], I have enjoyed the [[why-dev|simplicity of setup]]: `nix develop`, make the code change and see it work. That's all well and good, but when your project keeps growing, you need to depend on external services like databases, message brokers, etc. And then a quick search will tell you that [docker](https://www.docker.com/) is the way to go. You include it, [add one more step](https://github.com/nammayatri/nammayatri/tree/f056bb994fbf9adefa454319032ca35c34ea65bc/Backend#other-tools) in the setup guide, increasing the barrier to entry for new contributors. Not to forget, eating up all my system resources on my not so powerful, company provided, macOS[^native-macos].

This, along with the fact that we can provide one command to do a lot of **cool things** (which you will see, as you continue to read), made us want to replace [docker-compose](https://docs.docker.com/compose/) with Nix in [Nammayatri](https://github.com/nammayatri/nammayatri) (to keep it simple, I will refer to it as NY from now on).

[^native-macos]: There is an [initiative to run containers natively on macOS](https://github.com/macOScontainers/homebrew-formula), but it is still in alpha and [requires a lot of additional steps](https://github.com/macOScontainers/homebrew-formula?tab=readme-ov-file#installation) to setup. One such step is [disabling SIP](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection#3599244), which a lot of company monitored devices might not be allowed to do. 😕

{#what-does-it-take}

## What does it take?

Turns out, there is not a lot of things that we need to do: we need to be able to run services natively, across platforms (so that my macOS doesn't drain its battery running a database), and integrate with the existing [flake.nix](https://github.com/nammayatri/nammayatri/blob/main/flake.nix) (to avoid an extra step in the setup guide).

Lucky for us, NixOS already has a clean way to run services natively. We can use that as inspiration and build on top it.

{#nixos-services}

## NixOS services

Running services in NixOS is a breeze. For example, [running a PostgreSQL Database](https://nixos.wiki/wiki/PostgreSQL) is as simple as adding one line to your configuration:

```nix
{
  services.postgresql.enable = true;
}
```

This starts the database natively, without the need for a container. This is great, only if we could extend this to run on macOS and other Linux distributions. Also, the configuration above is system-wide, and we are looking for a way to run services on a per-project basis.

{#nixos-like-services}

## NixOS-like services

That's a relief, we are now closer to our goal. We now know what we want, and there are a few more things that needs to be added to the list:

- Allow for running multiple instances of the same service (NY uses multiple instances of PostgreSQL and Redis).
- Along with services being project specific, their data should also be project specific.

These were the exact problems [services-flake](https://community.flake.parts/services-flake) was designed to solve. Along with running services natively, it also [integrates with your project's `flake.nix`](https://community.flake.parts/services-flake/start).

>[!info] How are processes managed in services-flake?
> In NixOS they are managed by [systemd](https://en.wikipedia.org/wiki/Systemd). In services-flake, we use [process-compose](https://github.com/F1bonacc1/process-compose) whose configuration is managed by [process-compose-flake](https://community.flake.parts/process-compose-flake).

{#let-s-get-started}

## Let's get started

Now that we have all the answers. It's time to replace [docker-compose in NY](https://github.com/nammayatri/nammayatri/blob/f056bb994fbf9adefa454319032ca35c34ea65bc/Backend/nix/arion-configuration.nix) with services-flake. We will only look at a few services to keep it simple, for more details, see [PR](https://github.com/nammayatri/nammayatri/pull/3718).

:::{.center}
![[ny-services-flake.png]]
:::

{#postgresql}

### PostgreSQL

NY uses about 3 instances of postgresql databases.

One of them is [exported by passetto](https://github.com/nammayatri/passetto/blob/nixify/process-compose.nix) (passetto is a haskell application that encrypts data before storing in postgres), and using it looks like:

```nix
{
  services.passetto.enable = true;
}
```

By using [[modules|module system]], we can hide the implementation details and only expose the `passetto` service to the user, and use it as above.

The other two instances are used by the [postgres-with-replica module](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/nix/services/postgres-with-replica.nix). This module starts two services (`primary` and `replica` database) and a [pg-basebackup](https://www.postgresql.org/docs/current/app-pgbasebackup.html) process (to sync `replica` with `primary` during init). For the user it is:

```nix
{
  services.postgres-with-replica.enable = true;
}
```

{#redis}

### Redis

Redis and its clustered version are pretty straightforward:

```nix
{
  services.redis.enable = true;
  services.redis-cluster.enable = true;
}
```

{#cool-things}

## Cool things

By not depending on docker anymore, we can now run the entire NY backend with one command and its all defined in a [single place](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/nix/services/nammayatri.nix). 

That is not all, we can also reuse this to do much more, like defining [loadtest](https://github.com/nammayatri/nammayatri/blob/ccab8da607cfd8d4e9f7d28b55b83e22eec1af9b/Backend/load-test/default.nix) config and run it in CI/local, again, with one command.

Here's the screen grab of the devShell and the commands to run loadtest and the entire backend:
:::{.center}
![[ny-devshell.png]]
:::
