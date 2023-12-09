---
date: 2023-11-16
author: shivaraj-bh
---

# NixOS Remote Development

In this series of blog posts, we'll explore how to set up a remote [[dev|development environment]] using #[[nixos|NixOS]]. The goal of this post is to:
- Create a minimal [[nixos]] configuration.
- Deploy the configuration to a remote machine over SSH
  - Without a bootable USB, we will partition the disk and install the OS on the remote machine

**Table of Contents:**

- [Why?](#why)
- [The `flake.nix` file](#the-flakenix-file)
  - [`nixosConfigurations` attribute](#nixosconfigurations-attribute)
  - [`nixpkgs.lib.nixosSystem` function](#nixpkgslibnixossystem-function)
  - [Disko module](#disko-module)
  - [`configuration.nix` as a module](#configurationnix-as-a-module)
- [Installing NixOS](#installing-nixos)
- [What's next?](#whats-next)
- [Credits](#credits)


## Why?

Why develop remotely on a NixOS machine? There are two reasons:

- You can use a powerful remote machine for development, while carrying around a lightweight laptop.
- You remote machine's configuration is defined in [[nix]] expressions. The entire state of the machine (including users and services) can be reproduced from these expressions. This includes initial install and subsequent updates.

## The `flake.nix` file

>[!info] tl;dr
> If you just want to perform the installation, you may skip this section and jump to [installation](#installing-nixos).

>[!note]
>It is assumed that the user has a basic understanding of Nix (the language), if not, you can check out [[nix-rapid]] and #[[flakes|Flakes]].

Here's a [[flakes|flake]] with a single output of type NixOS configuration, named "office":

```nix title="flake.nix"
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, disko, ... }:
    {
      nixosConfigurations.office = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ({ ... }: {
            imports = [
              ./disk-config.nix
            ];
            services.openssh.enable = true;
            users.users = {
              root = {
                # Post-installation, the IP might change if MAC is not the
                # only identifier used by DHCP server to lease an IP, by setting a
                # password you can find the changed IP.
                initialHashedPassword = "";
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFN5Ov2zDIG59/DaYKjT0sMWIY15er1DZCT9SIak07vK"
                ];
              };
            };
            boot.loader.grub = {
              # adding devices is managed by disko
              # devices = [ ];
              efiSupport = true;
              efiInstallAsRemovable = true;
            };
            system.stateVersion = "23.11";
          }
          )
        ];
      };
    };
}
```

### `nixosConfigurations` attribute

Flakes can output a special attribute called `nixosConfigurations` which can contain multiple NixOS configurations. It is a set of attributes, where each attribute is a NixOS configuration. This is how it looks like with two configurations:
```nix
# Inside `outputs`
{
    nixosConfigurations = {
        office = { ... };
        home = { ... };
    };
}
```

>[!note] Why `nixosConfigurations`?
>It is not mandatory to put your configuration under `nixosConfigurations` attribute, but by doing so you can run `nixos-rebuild switch --flake .#office` instead of specifying the entire path to the attribute.

### `nixpkgs.lib.nixosSystem` function

`nixosConfigurations.*` must be a NixOS configuration, which is created using the `nixosSystem` function from [[nixpkgs]]. This function takes an attrset with several keys, of which two are mandatory: `system` and [[modules|`modules`]]. The functions returns an attrset with several attributes, of which we are interested in `config.system.build.toplevel` as this represents the [[drv]] for our entire NixOS system.

### Disko module

We do not have to manually partition our disk. To declaraticely define our partition layout in our configuration, we use [Disko](https://github.com/nix-community/disko):

```nix title="disk-config.nix"
# disk-config.nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

The two important attributes here are:
- `disko.devices.disk.<device-name>.device`: The device name of the disk to partition.
<!-- Is the boot partition necessary? -->
- `disko.devices.disk.<device-name>.content.partitions`:
    - [`boot`](https://en.wikipedia.org/wiki/BIOS_boot_partition)
    - [`ESP`](https://en.wikipedia.org/wiki/EFI_system_partition)
    - [`root`](https://en.wikipedia.org/wiki/Root_directory)

### `configuration.nix` as a module

In pre-[[flakes]] world, `configuration.nix` has been the top-level [[modules|module]] specifying entire NixOS configuration. When using [`flake.nix`](#the-flakenix-file), however, we can add the configuration to the `modules` attribute of `nixosSystem` function.

```nix
# Inside `outputs`
{
  nixosConfigurations.office = lib.nixosSystem {
    # ...
    modules = [
      # ...
      ({ ... }: {
        # Your `configuration.nix` goes here
      })
    ];
  }
}
```

In this module we do the following things:
- Enable SSH access to the machine.
- Set a password for the `root` user.
- Add an SSH key to the `root` user's `authorized_keys` file.
- Enable GRUB with EFI support.
<!-- Verify the point below -->
- Set the `system.stateVersion` to `23.11` to avoid rebuilding the system on every `nixos-rebuild switch`.
- Import the `disk-config.nix` file that we created [earlier](#disko-module).

## Installing NixOS

Once our configuration is ready, we can deploy it to a remote machine over SSH. This machine must already be running a linux based OS. If it doesn't, boot it using a [live/rescue image](https://en.wikipedia.org/wiki/Live_USB).

>[!info] kexec
> If a machine has no OS installed on it yet, how do we install an OS without a bootable USB? The answer is, we use the RAM as a bootable disk. We achieve this with [`kexec`](https://en.wikipedia.org/wiki/Kexec) to load the nixos image into RAM. Once loaded, the control is switched from your current OS to the image running on the RAM, this image then partitions the disk and installs the system on your hard drive.

[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) is a tool that automates this process for us. To follow along:
```sh
git clone https://github.com/juspay/remote-development.git
cd remote-development
git checkout a23acb9cb0a51e048096b3e4c8130b979ca0c2fa
```

The [README](https://github.com/juspay/remote-development/blob/a23acb9cb0a51e048096b3e4c8130b979ca0c2fa/README.md) should help you get started with the installation. Once you are done, you should be able to SSH into the machine.

## What's next?

In the next blog post, we'll explore how to make incremental changes to the configuration and deploy them to the machine.

You can track the progress [here](https://github.com/juspay/remote-development/issues/2).

## Credits

Thanks to [srid](https://x.com/sridca) for all the help and feedback.