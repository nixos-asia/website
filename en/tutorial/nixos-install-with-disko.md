# Install NixOS and partition the disk with `disko`

This tutorial adds another layer of reproducibility to the [[nixos-install]] by writing your partitioning scheme for #[[nixos]] in #[[nix]].

>[!note] Flake configuration
> We will use #[[flakes]] by default.

{#iso}
## Install NixOS

>[!note] Minimal ISO image
> This tutorial doesn't use a graphical installer. Instead, it uses the minimal ISO image. This is primarily because we don't want the installer to partion the disk for us. We will use [disko](https://github.com/nix-community/disko) to do that.

- Download the latest NixOS ISO from [here](https://nixos.org/download#download-nixos). Choose the "Minimal ISO image" for your architecture.
- Create a bootable USB flash drive ([instructions here](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)) and boot the computer from it.

NixOS will boot into the USB in CLI mode. 

:::{.center}
![[nixos-installer-cli.jpeg]]
:::

{#partition}
## Partition the disk

The [disko quickstart guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md) does an excellent job of explaining it. We will follow the same steps and include screenshots wherever necessary. Additionally, in the last step we will use flakes to manage the configuration.

### Choosing the disk configuration

Disko provides a few examples to choose [from](https://github.com/nix-community/disko/tree/master/example). We will use the [hybrid](https://github.com/nix-community/disko/blob/master/example/hybrid.nix) example as it will work for both BIOS and UEFI systems.

Copy the disk configuration on to the USB flash drive.

```bash
curl https://raw.githubusercontent.com/nix-community/disko/master/example/hybrid.nix -o /tmp/disko-config.nix
```

### Modify the disk configuration

We need to find the device name of the disk we want to install NixOS on. We can use `lsblk` to find it.


:::{.center}
![[nixos-lsblk.jpeg]]
:::

In this case, the device name is `vda`. We will use this to modify `disko-config.nix` we downloaded earlier.

:::{.center}
![[nixos-disko-config.jpeg]]
:::

### Run the partitioning script

>[!note]
> The disk will be partitioned and mounted at `/mnt`.

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko-config.nix
```

:::{.center}
![[nixos-disko-post-partition.jpeg]]
:::

{#configuration}
## The NixOS configuration

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```

The [fileSystems](https://search.nixos.org/options?channel=23.11&show=fileSystems&from=0&size=50&sort=relevance&type=packages&query=fileSystems) configuration will be added by `disko`'s [nixosModule](https://nixos.wiki/wiki/NixOS_modules) hence we use `--no-filesystems` to avoid generating it. `--root` is to specify the mountpoint to generate `configuration.nix` and `hardware-configuration.nix` in. Here, it will be `/mnt/etc/nixos`.

### Flakify the NixOS configuration

This step remains the same as the [Install NixOS with Flake configuration on Git](https://nixos.asia/en/tutorial/nixos-install#flakeify) tutorial.

### Add the `disko` nixosModule

Add the `disko` flake input:

```nix
# In `flake.nix`
{
  inputs = {
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```
>[!info]
> `disko.inputs.nixpkgs.follows = "nixpkgs";` is to ensure that `disko` uses the same version of `nixpkgs` as specified in the current flake. This avoids having two different sources of `nixpkgs` and saves space.

Add the `disko` nixosModule:

```nix
{
  # In `outputs` of `flake.nix`
  nixosConfigurations.nixos = {
    # ...
    modules = [
      ./configuration.nix
      disko.nixosModules.disko
    ];
  };
}
```
:::{.center}
![[nixos-flake-with-disko.jpeg]]
:::

Add the disk configuration and use GRUB:

```nix
{
  # In `configuration.nix`
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

Verify `fileSystems` set by `disko` in `nix repl`:
:::{.center}
![[nixos-disko-filesystems.jpeg]]
:::


{#install}
## Install NixOS

```bash
sudo nixos-install --root /mnt --flake '.#nixos'
```

{#extras}
## Extra configuration (Good to have)

- [Move configuration to home dir](https://nixos.asia/en/tutorial/nixos-install#homedir)
- [Store the configuration on Git](https://nixos.asia/en/tutorial/nixos-install#git)
- [Enable flakes](https://nixos.asia/en/tutorial/nixos-install#enable-flakes)

## Recap

You now have a reproducible disk partitioning scheme. This does come with a cost of few extra manual steps but you can automate them with a script. Which is what we will do in the next tutorial.

## Up next

We will use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) to automate the steps above and eliminate the need for a USB flash drive (assuming you have a working Linux system or are booted into a rescue image).

#











