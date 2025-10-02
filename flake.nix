{
  description = "Various dev tools I often want to install from source";

  inputs = {
    fish.url = "github:fish-shell/fish-shell/4.1.1";
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
    gleam-nix.inputs.gleam.url = "github:gleam-lang/gleam/v1.12.0";
    gleam-nix.inputs.nixpkgs.follows = "nixpkgs";
    janet.url = "github:janet-lang/janet/v1.39.1";
    janet.flake = false;
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (builtins)
        attrValues
        removeAttrs
        replaceStrings
        ;
      metaPackages = [
        "all"
        "dev"
        "default"
      ];
      forAllSystems =
        mkOutputs:
        nixpkgs.lib.genAttrs [
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
          "x86_64-linux"
        ] (system: mkOutputs nixpkgs.legacyPackages.${system});
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
              hash = "sha256-WZdfon6mnM+5caWW6yInQx5B1GjCxQ0XLbJlbvHa3Zc=";
            };
            postPatch =
              replaceStrings [ "src/tests/highlight.rs" ] [ "src/highlight/tests.rs" ]
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

        dev = pkgs.buildEnv {
          name = "pvsr/dev-tools";
          paths = with inputs.self.packages.${pkgs.system}; [
            fish
            jj
            helix
          ];
        };
        all = pkgs.buildEnv {
          name = "pvsr/src-apps";
          paths = attrValues (removeAttrs inputs.self.packages.${pkgs.system} metaPackages);
        };
        default = inputs.self.packages.${pkgs.system}.all;
      });
    };
}
