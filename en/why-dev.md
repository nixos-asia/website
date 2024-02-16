
# Why Choose Nix for develoment?

Why opt for [[nix]] when #[[dev|developping]] a software project instead of language-specific alternatives (such as Stack or GHCup for [[haskell]])?

- **Instantaneous Onboarding**: Typical project READMEs detail environment setup instructions that often fail to work uniformly across different developers' machines, taking hours or even days to configure. Nix offers an instant and reproducible setup, allowing any newcomer to get their development environment ready swiftly with one command.
- **Boosted Productivity**: Developers can dedicate more time to writing software, as Nix ensures a fully functional development environment through `nix develop`.
- **Multi-Platform Support**: The same configuration reliably works across [[macos]], Linux, and WSL.

>[!note] macOS support
> While [[macos]] doesn't enjoy first-class support in [[nixpkgs]] yet, [improvements are underway](https://github.com/NixOS/nixpkgs/issues/116341).

