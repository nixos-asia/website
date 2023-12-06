# nixos.asia website

This website is built using [Emanote](https://emanote.srid.ca/).

To run it locally with live preview,

```sh
nix run
```

## Goals

On nixos.asia website, we will host our Nix weblog as well as wiki'esque content. Everyone is welcome to contribute content!

## How to edit

Contents are stored in Markdown and can be edited using your favourite [text editor](https://emanote.srid.ca/start/resources/editors) (this repo comes with VSCode settings and extensions). Anyone with a GitHub account can edit this website by clicking the edit icon at the bottom of any page and thereby creating a pull request.

### Guidelines

- When linking to a concept, see if there is an existing page for it. For eg., if you are linking to "nix flakes", use the wikilink `[[flakes]]` since the website already has a page, `flakes.md` for it.
- Create parent (folgezettel) relationships are appropriate by using `#[[..]]` stylf of wikilinks such as to shape the [uplink tree](https://emanote.srid.ca/guide/html-template/uptree) of any page.

## Discussion

We hang out in [Zulip](https://nixos.zulipchat.com/) ― come say hi.
