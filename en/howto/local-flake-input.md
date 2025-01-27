
# Use a local directory as flake input

A [[flake-url]] can not only be [[git]] repositories. They can also refer to local paths. If you have two projects `~/code/foo` and `~/code/bar`, and `bar` depends on `foo`, you can use the following `flake.nix` in `bar` to have it refer to the local `foo` project:

```nix
{
  inputs = {
    foo.url = "path:/Users/me/code/foo";
  };
  outputs = inputs: { ... };
}
```

>[!warning] `flake.lock`
> Whenever you modify files under `~/code/foo`, you must run update the `flake.lock` hash in `~/code/bar` by running:
>
> ```sh
> nix flake update foo
> ```
>
> The alternative is to pass `--override-input foo ~/code/foo` to `nix build` or `nix develop` commands; this will override the hash for "foo" in the `flake.lock` file.
