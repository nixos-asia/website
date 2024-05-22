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

[vscode-term]: https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line
[direnv-ext]: https://marketplace.visualstudio.com/items?itemName=mkhl.direnv