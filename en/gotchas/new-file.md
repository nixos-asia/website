
# Nix does not recognize a new file I added

Often you'll see an error like this,

```text
error: getting status of '/nix/store/vlks3d7fr5ywc923pvqacx2bkzm1782j-source/foo': No such file or directory
```

This usually means you have not staged this new file/ directory to the Git
index. When using #[[flakes]], Nix will not see [untracked] files/ directories by default. To resolve this, just `git add -N` the untracked file/ directory.

>[!info] For further information
> https://github.com/NixOS/nix/issues/8389

[untracked]: https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
