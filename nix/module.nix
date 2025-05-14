inputs: {config, lib, pkgs, ...}: let
        cfg = config.programs.ski;
        inherit (lib) mkOption mkEnableOption mkIf mkDefault types;
        inherit (pkgs.stdenv.hostPlatform) system;
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
            description = "The ski package to use.";
          };
        };
        config = mkIf cfg.enable {
          home.packages = [cfg.package];
          # programs.ski.package = mkDefault inputs.self.packages.${system}.ski;

          home.file.".ssh/config.toml" = mkIf (cfg.settings != {}) {
            source = tomlFormat.generate "ski-config" cfg.settings;
          };
        };
      } inputs
