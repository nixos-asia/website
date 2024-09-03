# VSCode

[Visual Studio Code](https://code.visualstudio.com/) is a popular open source code editor from Microsoft with extension support. 

>[!warning] WIP
> This page has not been completed.

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
