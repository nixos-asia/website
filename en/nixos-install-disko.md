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
