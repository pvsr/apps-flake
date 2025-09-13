{
  description = "Various dev tools I often want to install from source";

  inputs = {
    fish.url = "github:fish-shell/fish-shell";
    fish.flake = false;
    jj.url = "github:jj-vcs/jj/v0.33.0";
    jj.inputs.nixpkgs.follows = "nixpkgs";
    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
    helix.inputs.rust-overlay.follows = "jj/rust-overlay";

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
        concatStringsSep
        replaceStrings
        ;
      metaPackages = [
        "all"
        "dev"
        "default"
      ];
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = forAllSystems (system: {
        fish = nixpkgs.legacyPackages.${system}.fish.overrideAttrs (
          finalAttrs: previousAttrs: {
            src = inputs.fish;
            version = inputs.fish.shortRev;
            cargoDeps = nixpkgs.legacyPackages.${system}.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) src patches;
              hash = "sha256-zXaLTROJ90+Gv8M9B9zIcu9MJdtZskgvMSsms+NNAOc=";
            };
            postPatch = concatStringsSep "\n" [
              "rm tests/checks/version.fish"
              (replaceStrings [ "src/tests/highlight.rs" ] [ "src/highlight/tests.rs" ] previousAttrs.postPatch)
            ];
          }
        );

        jj = inputs.jj.packages.${system}.default;
        helix = inputs.helix.packages.${system}.default;

        gleam = inputs.gleam-nix.packages.${system}.default;
        janet = nixpkgs.legacyPackages.${system}.janet.overrideAttrs {
          src = inputs.janet;
          version = inputs.janet.shortRev;
        };

        dev = nixpkgs.legacyPackages.${system}.buildEnv {
          name = "pvsr/dev-tools";
          paths = with inputs.self.packages.${system}; [
            fish
            jj
            helix
          ];
        };
        all = nixpkgs.legacyPackages.${system}.buildEnv {
          name = "pvsr/src-apps";
          paths = attrValues (removeAttrs inputs.self.packages.${system} metaPackages);
        };
        default = inputs.self.packages.${system}.all;
      });
    };
}
