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

    gleam-nix.url = "github:vic/gleam-nix";
    gleam-nix.inputs.gleam.url = "github:gleam-lang/gleam/v1.13.0-rc1";
    gleam-nix.inputs.nixpkgs.follows = "nixpkgs";
    gleam-nix.inputs.rust-manifest.url = "file+https://static.rust-lang.org/dist/channel-rust-1.88.0.toml";
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
    in
    {
      packages = forAllSystems (pkgs: {
        fish = pkgs.fish.overrideAttrs (
          finalAttrs: previousAttrs: {
            src = inputs.fish;
            version = pkgs.lib.pipe "${inputs.fish}/Cargo.toml" [
              builtins.readFile
              (builtins.match ''.+"fish".version = "([^"]+)".*'')
              (ver: builtins.elemAt ver 0)
            ];
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

        gleam = inputs.gleam-nix.packages.${pkgs.system}.default;
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
