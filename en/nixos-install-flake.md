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

As a final step, let's permanently enable [[flakes]] on our system, which is particular useful if you do a lot of [[dev|software development]]. This time, instead of editing `configuration.nix` again, let's do it in a separate [[modules|module]] (for no particular reasons other than pedagogic purposes). Remember the `modules` argument to `nixosSystem` function in our `flake.nix`? It is a list of modules, so we can add a second module there:

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

