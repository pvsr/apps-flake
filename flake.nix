{
  description = "Various dev tools I often want to install from source";

  inputs = {
    jj.url = "github:jj-vcs/jj/v0.33.0";
    jj.inputs.nixpkgs.follows = "nixpkgs";
    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
    helix.inputs.rust-overlay.follows = "jj/rust-overlay";

    gleam-nix.url = "github:vic/gleam-nix";
    gleam-nix.inputs.nixpkgs.follows = "nixpkgs";
    gleam-nix.inputs.gleam.url = "github:gleam-lang/gleam/v1.12.0";
    janet.url = "github:janet-lang/janet/v1.39.1";
    janet.flake = false;
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (builtins) attrValues removeAttrs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = forAllSystems (system: {
        jj = inputs.jj.packages.${system}.default;
        helix = inputs.helix.packages.${system}.default;

        gleam = inputs.gleam-nix.packages.${system}.default;
        janet = nixpkgs.legacyPackages.${system}.janet.overrideAttrs {
          src = inputs.janet;
          version = inputs.janet.shortRev;
        };

        default = nixpkgs.legacyPackages.${system}.buildEnv {
          name = "src-apps";
          paths = attrValues (removeAttrs inputs.self.packages.${system} [ "default" ]);
        };
      });
    };
}
