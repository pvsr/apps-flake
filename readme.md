This is a nix flake wrapping programs that I often want to build from source, for easy use with `nix profile install`.
I used to include some of these directly in my [system flake](https://github.com/pvsr/nixfiles),
but rebuilding a ton of rust code every time I upgraded nixpkgs got old.

### Dev tools
 - [Fish shell](https://fishshell.com/)
 - [Jujutsu VCS](https://jj-vcs.github.io/jj/latest/)
 - [Helix editor](https://helix-editor.com/)
 - [Ghostty terminal](https://ghostty.org/)

### Programming languages
 - [Gleam](https://gleam.run/)
 - [Janet](https://janet-lang.org/)

## Usage

```
# install all
nix profile install github:pvsr/apps-flake

# install all, building with the system nixpkgs
nix profile install --override-input nixpkgs nixpkgs github:pvsr/apps-flake

# ad-hoc upgrade
nix profile upgrade --override-input github:helix-editor/helix/some-branch apps-flake

# run a specific version of an app
nix run --override-input github:janet-lang/janet/v1.39.1 github:pvsr/apps-flake#janet
```
