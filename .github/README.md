# nixos.asia website

This website is built using [Emanote](https://emanote.srid.ca/).

To run the English site locally with live preview,

```sh
nix run .#en  # Or just: nix run
```

## Goals

On nixos.asia website, we will host our Nix weblog as well as wiki'esque content. Everyone is welcome to contribute content!

## How to edit

Contents are stored in Markdown and can be edited using your favourite [text editor](https://emanote.srid.ca/start/resources/editors) (this repo comes with VSCode settings and extensions). Anyone with a GitHub account can edit this website by clicking the edit icon at the bottom of any page and thereby creating a pull request.

### Guidelines

- When linking to a concept, see if there is an existing page for it. For eg., if you are linking to "nix flakes", use the wikilink `[[flakes]]` since the website already has a page, `flakes.md` for it. If there isn't one, you usually want to create such an [atomic](https://neuron.zettel.page/atomic) note for it.
- Create parent-child ([folgezettel](https://neuron.zettel.page/folgezettel)) relationships as appropriate by using `#[[..]]` style of wikilinks such as to shape the [uplink tree](https://emanote.srid.ca/guide/html-template/uptree) of any page.

### PR guidelines

To assist the reviewer, use `nix run github:nixos-asia/website/branch#preview` in the PR description to provide a handy command for previewing the changes in the PR. See example: https://github.com/nixos-asia/website/pull/12


### Content organization

This site is made of multiple Emanote layers:

- `./global`: Static files and HTML temlpates (common to all languages)
    - If a note uses images, you should put them here.
- Language-specific content:
    - `./en`: English content
    - `./fr`: French content[^fr]

[^fr]: This is just a placeholder. See https://github.com/nixos-asia/website/issues/18


## Discussion

We hang out in [Zulip](https://nixos.zulipchat.com/) ― come say hi.
