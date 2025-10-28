{
  description = "Various dev tools I often want to install from source";

  inputs = {
    fish.url = "github:fish-shell/fish-shell/4.1.2";
    fish.flake = false;
    jj.url = "github:jj-vcs/jj/v0.34.0";
    jj.inputs.nixpkgs.follows = "nixpkgs";
    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
    helix.inputs.rust-overlay.follows = "jj/rust-overlay";

    ghostty.url = "github:ghostty-org/ghostty/v1.2.0";
    ghostty.inputs.nixpkgs.follows = "nixpkgs";
    ghostty.inputs.zon2nix.inputs.nixpkgs.follows = "nixpkgs";

    gleam.url = "github:gleam-lang/gleam/v1.13.0";
    gleam.flake = false;
    janet.url = "github:janet-lang/janet/v1.39.1";
    janet.flake = false;
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      forAllSystems =
        mkOutputs:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: mkOutputs nixpkgs.legacyPackages.${system}
        );
      getCargoVersion =
        path:
        nixpkgs.lib.pipe path [
          builtins.readFile
          (builtins.match ''.+''\nversion = "([^"]+)".*'')
          (ver: builtins.elemAt ver 0)
        ];
    in
    {
      packages = forAllSystems (pkgs: {
        fish = pkgs.fish.overrideAttrs (
          finalAttrs: previousAttrs: {
            src = inputs.fish;
            version = getCargoVersion "${inputs.fish}/Cargo.toml";
            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) src patches;
              hash = "sha256-7mYWCHH6DBWTIJV8GPRjjf6QulwlYjwv0slablDvBF8=";
            };
            postPatch =
              builtins.replaceStrings [ "src/tests/highlight.rs" ] [ "src/highlight/tests.rs" ]
                previousAttrs.postPatch;
          }
        );

        jj = inputs.jj.packages.${pkgs.system}.default;
        helix = inputs.helix.packages.${pkgs.system}.default;
        ghostty = inputs.ghostty.packages.${pkgs.system}.default;

        gleam = pkgs.gleam.overrideAttrs rec {
          src = inputs.gleam;
          version = getCargoVersion "${inputs.gleam}/gleam-bin/Cargo.toml";
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-TzHjXW9sSbOJv7PrUaQzZ0jOPocVci1DjcmLzv7aaBY=";
          };
        };
        janet = pkgs.janet.overrideAttrs {
          src = inputs.janet;
          version = inputs.janet.shortRev;
        };

        default = pkgs.buildEnv {
          name = "pvsr-src-apps";
          paths = with inputs.self.packages.${pkgs.system}; [
            jj
            helix
            ghostty
            gleam
            janet
          ];
        };
      });
    };
}
