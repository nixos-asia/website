# Git

Git is the most commonly used version control system for #[[dev|software development]].

## Declarative configuration

Git can be declaratively configured in [[nix]] via [[home-manager]]. [Here is](https://github.com/srid/nixos-config/blob/master/home/git.nix) an example:

```nix
{
  programs.git = {
    enable = true;
    userName = "john";
    userEmail = "john@doe.com";
    ignores = [ "*~" "*.swp" ];
    extraConfig = {
      init.defaultBranch = "master";
    };
  };
}
```

## Git related pages

```query
children:.
```
