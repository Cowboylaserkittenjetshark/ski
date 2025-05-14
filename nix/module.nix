self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ski;
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  inherit (pkgs.stdenv.hostPlatform) system;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.ski = {
    enable = mkEnableOption "ski";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
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
      default = self.packages.${system}.default;
      description = "The ski package to use.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".ssh/ski.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ski-config" cfg.settings;
    };
  };
}
