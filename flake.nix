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

      homeModules.default = inputs: {config, lib, pkgs, ...}: let
        cfg = config.programs.ski;
        inherit (lib) mkOption mkEnableOption mkIf types;
        tomlFormat = pkgs.formats.toml {};
      in {
        options.programs.ski = {
          enable = mkEnableOption "ski";

          settings = mkOption {
            type = tomlFormat.type;
            default = {};
            example = {
              pairs = {
                k1.name = "k1_1234_ed25519";
                k2 = {
                  public = "/a/path/outside/of/.ssh/k2_4321.pub";
                  private = "/a/path/outside/of/.ssh/k2_4321";
                };
              };
              roles = {
                auth.target = "id_ed25519_sk";
                sign.target = "signing-key";
              };
            };
            description = "Options to add to the {file}`ski.toml` file";
          };
          
          package = mkOption {
            type = types.package;
            default = ski;
            description = "The ski package to use.";
          };
        };
        config = mkIf cfg.enable {
          home.packages = [cfg.package];

          home.file.".ssh/config.toml" = mkIf (cfg.settings != {}) {
            source = tomlFormat.generate "ski-config" cfg.settings;
          };
        };
      } inputs;
    });
}
