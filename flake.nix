{
  description = "A simple tool to switch active ssh key pairs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    crane,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      craneLib = crane.mkLib pkgs;

      commonArgs = {
        src = craneLib.cleanCargoSource ./.;
        strictDeps = true;

        buildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin [
          pkgs.libiconv
        ];
        nativeBuildInputs = [pkgs.installShellFiles];
      };

      ski = craneLib.buildPackage (commonArgs
        // {
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          postInstall = ''
            installShellCompletion \
              --bash target/ski.bash \
              --fish target/ski.fish \
              --zsh target/_ski
          '';
        });
    in {
      checks = {
        inherit ski;
      };

      packages.default = ski;

      apps.default = flake-utils.lib.mkApp {
        drv = ski;
      };

      devShells.default = craneLib.devShell {
        checks = self.checks.${system};
        packages = with pkgs; [
          nil
          statix
          deadnix
          rust-analyzer
          cargo-generate
        ];
      };

    }) // {
      homeModules.default = import ./nix/module.nix self;
  };
}
