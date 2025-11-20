---
author: srid
date: 2025-11-20
page:
  image: blog/git-submodule-input/submodule-banner.png
---

# Git Submodules as Nix Flake Inputs

Nix flakes support `self.submodules = true`, allowing git submodules to be referenced as flake inputs via `path:` URLs. This approach offers distinct advantages over GitHub-based inputs when co-developing dependencies alongside your main configuration.

![[submodule-banner.png]]

## The Pattern {#pat}

Standard GitHub-based flake input:

```nix
inputs = {
  AI.url = "github:srid/AI";
  AI.flake = false;
}
```

Submodule-based alternative:

```nix
inputs = {
  self.submodules = true;
  
  AI.url = "path:vendor/AI";
  AI.flake = false;
}
```

Add the submodule:

> [!NOTE]
> Path-based flake inputs don't store version information in `flake.lock`. The entry only contains `"type": "path"` and the local path—no commit hash, no `lastModified` timestamp. Version tracking is delegated to git's submodule system, where the commit SHA is stored in your repository's tree. This means `nix flake lock --update-input AI` has no effect; you update by running `git submodule update --remote vendor/AI` instead.

```bash
git submodule add https://github.com/srid/AI.git vendor/AI
```

> [!NOTE]
> Use HTTPS URLs rather than SSH to support anonymous cloning in CI environments without key management.

## Advantages

### Zero-Latency Development Loop {#latency}

With GitHub-based inputs, testing dependency changes requires:
1. Committing changes in the dependency repository
2. Pushing to GitHub
3. Running `nix flake lock --update-input <name>` in the parent repository
4. Rebuilding to test

With submodules, you edit `vendor/AI/` directly and rebuild. The dependency is already local. No push required, no lock file update needed.

> [!WARNING]
> **Workaround Required**: Due to [Nix issue \#13324](https://github.com/NixOS/nix/issues/13324), path-based inputs only track local changes when the **parent repository has uncommitted changes**. If your parent repo is clean, Nix ignores submodule working tree modifications and attempts to fetch from the remote instead. [Keep a trivial uncommitted change](https://github.com/NixOS/nix/issues/13324#issuecomment-2159058506) (e.g., whitespace in a comment) in the parent repo to force Nix to use local working trees. This is an acknowledged limitation in Nix's current design.

### Git-Native Version Tracking {#git}

Path-based flake inputs bypass `flake.lock` versioning entirely. The lock file entry contains only `"type": "path"` and the local path—no `narHash`, no `lastModified`, no `rev`. Version pinning is delegated to git's submodule system, where the commit SHA is stored as a tree object in your repository.

> [!TIP]
> **Understanding git tree objects:** Submodules are tracked as [gitlink entries](https://git-scm.com/docs/gitsubmodules) in the parent repository's [tree objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects#_tree_objects). When you commit a submodule update, git stores the specific commit SHA as a tree entry—not as file content. This means `git log`, `git diff`, `git blame`, `git bisect`, and `git revert` operate on submodule commits directly. Dependency version history is first-class git data, not opaque lock file JSON.

`nix flake lock --update-input AI` is a no-op for path-based inputs. Updates are purely git operations via `git submodule update --remote vendor/AI`.

## Example

The [`srid/nixos-config` repository](https://github.com/srid/nixos-config) uses this pattern for **`vendor/AI`** (Claude Code configuration):

```nix
inputs = {
  AI.url = "path:vendor/AI";
  AI.flake = false;
}
```

The [`srid/AI` repo](https://github.com/srid/AI) is then consumed as `${AI}/nix/home-manager-module.nix` in home-manager modules. Changes to prompts, commands, or MCP configurations can be tested immediately by editing files in `vendor/AI/`, rebuilding the home-manager configuration, and verifying behavior—all without leaving the local repository.

## Trade-offs {#tradeoffs}

Git submodules have well-documented UX issues:

- Requires explicit `git submodule update --init --recursive` on initial clone
- Detached HEAD state in submodule directories by default
- Non-obvious update semantics (`git pull` in parent doesn't update submodules automatically)
- Clone operations need `--recurse-submodules` flag or manual initialization

These are standard git submodule concerns, not specific to Nix flakes. If you're already using submodules elsewhere, the mental model is familiar. If not, the learning curve exists regardless of this use case.

**Nix-Specific Limitation**: See the [WARNING callout above](git-submodule-input.md#latency) regarding the dirty working tree requirement for local development.

## Usage

Use this when actively co-developing a Nix configuration and its dependencies (home-manager modules, package sets, dotfiles). Submodules eliminate the push-lock-rebuild cycle.

If you rarely modify dependencies and don't need to test local changes before pushing, stick with GitHub-based inputs and `nix flake lock --update-input`. Submodules add clone complexity in exchange for faster iteration.

## References

- [Nix Manual - Self-attributes](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake#self-attributes) - Official documentation on `self.submodules` and related attributes
- [Nix Manual - Path-like syntax](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake#path-like-syntax) - Documentation on `path:` URL schema for flake inputs
- [Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) - Git documentation on submodule mechanics
- [srid/nixos-config](https://github.com/srid/nixos-config) - Real-world example using this pattern
