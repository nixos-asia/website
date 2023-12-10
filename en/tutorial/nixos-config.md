
# Install NixOS and keep configuration on Git

This short tutorial will walk you through the steps necessary to install #[[nixos]], convert your configuration to be a [[flakes|flake]] and then store it on Git.

## Install NixOS

Download the latest NixOS ISO from [here](https://nixos.org/download#download-nixos). Choose the GNOME image for the appropriate CPU architecture. Create a bootable USB flash drive ([instructions here](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)) and boot the computer from it.

NixOS will boot into a graphical environment with the installer already running. 

:::{.center}
![[nixos-installer.png]]
:::

Once NixOS install is complete, reboot into your new system. You will be greeted with a login screen. Login as the user you created with the password you set during installation. Then open the "Console" application from the "Activities" menu.

## Your first `configuration.nix` change


Your systems configuration includes everything from partition layout to kernel version to packages to services. It is defined in `/etc/nixos/configuration.nix`. 

>[!info] What is `hardware-configuration.nix`?
> Hardware specific configuration (eg: disk partitions to mount) are defined in `/etc/nixos/hardware-configuration.nix` which is `import`ed, as a [[modules|module]], by `configuration.nix`.

All system changes require a change to this `configuration.nix`. In order to "install" or "uninstall" a package, for instance, we would edit this `configuration.nix`. Let's do this now to install the [neovim](https://neovim.io/) text editor:

```sh
sudo nano /etc/nixos/configuration.nix
```

>[!tip] Nix language
> These `*.nix` files are written in the [[nix]] language.

- Add `neovim` under `environment.systemPackages`
- Bonus: uncomment `services.openssh.enable = true;` (this will enable the SSH server)

Press <kbd>Ctrl+X</kbd> to exit nano.

Once `configuration.nix` is changed, you must activate that new configuration:

```sh
sudo nixos-rebuild switch
```

This will take a few minutes to complete. Once it is done, you should expect to see something like this:

:::{.center}
![[nixos-rebuild-switch.png]]
:::

>[!tip] Remote access
> Now that you have OpenSSH enabled, you may do the rest of the steps from another machine by ssh'ing to this machine.

## Flakeify

Our `configuration.nix` is not "pure", because it still uses mutable Nix channel. For this reason (among others), we will immediately switch to using [[flakes]] for our NixOS configuration. Doing this is pretty simple. Just add a `flake.nix` file in `/etc/nixos`:

```sh
sudo nvim /etc/nixos/flake.nix
```

Add the following:

```nix
# /etc/nixos/flake.nix
{
  inputs = {
    # NOTE: This version should match the system.stateVersion in your configuration.nix
    # You can also use `nixos-unstable` to use bleeding edge.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };
  outputs = { self, nixpkgs }: {
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
> - `nixos-23.11` should match the `system.stateVersion` in your `configuration.nix`
> - `x86_64-linux` should be `aarch64-linux` if you are on ARM

Now, `/etc/nixos` is technically a [[flakes|flake]]. We can "inspect" this flake using the `nix flake show` command:

```sh
$ nix flake show /etc/nixos
error: experimental Nix feature 'nix-command' is disabled; use '--extra-experimental-features nix-command' to override
```

Oops, what happened here? Because flakes is a so-called "experimental" feature you must manually enable it. We'll _temporarily_ enable it for now, and then latter enable it _permanently_. The `--extra-experimental-features` flag can be used to enable experimental features. Let's try again:

```sh
$ nix --extra-experimental-features 'nix-command flakes' flake show /etc/nixos
warning: creating lock file '/etc/nixos/flake.lock'
error:
       … while updating the lock file of flake 'path:/etc/nixos?lastModified=1702156351&narHash=sha256-km4AQoP/ha066o7tALAzk4tV0HEE%2BNyd9SD%2BkxcoJDY%3D'

       error: opening file '/etc/nixos/flake.lock': Permission denied
```

Alright, now Nix understably cannot to write to root-owned directory. At this point, we are better off moving the whole configuration to our home directory, which would also prepare the ground for storing it on Git.

## Move configuration to user directory

Move the entire `/etc/nixos` directory to your home directory:

```sh
$ sudo mv /etc/nixos ~/nixos-config && sudo chown -R $USER ~/nixos-config
```

It should now look like this:

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

This flake has a single output, `nixosConfigurations.nixos`, which is the NixOS configuration. 

>[!info] More on Flakes
> See [[nix-rapid]] for more information on flakes.

Once flake-ified, in order to activate the new configuration we must pass the `--flake` flag, viz.:

```sh
$ sudo nixos-rebuild switch --flake .
```

If everything went well, you should see something like this:

:::{.center}
![[nixos-rebuild-switch-flake.png]]
:::

Excellent, now we have a flake-ified NixOS configuration that is pure and reproducible! Let's store it on Git.

## Store the configuration on Git

First we need to install Git: add `git` to `environment.systemPackages`, and activate your new configuration using `sudo nixos-rebuild switch --flake .`. Then, create a Git repository for your configuration:


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

## Conclusion

Congratulations, you now have a flake-ified NixOS configuration that is stored in a Git repo. You can make changes to your configuration, commit them to Git, and push it to GitHub. Additionally we enabled [[flakes]] permanently, which means you can now use all the modern `nix` commands, such as running a package directly from [[nixpkgs]] (same version pinned in `flake.lock` file):

:::{.center}
![[nixos-pony.png]]
:::


## Next Steps

- Check out [nixos-flake](https://community.flake.parts/nixos-flake) for more convenience, and especially if you wish to use [[home-manager]] (to manage home configuration) and/or also have a [[macos|Mac]].