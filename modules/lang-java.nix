{
  pkgs,
  config,
  lib,
  ...
}:
let
  ctx = pkgs.callPackage ../lib/mk-context.nix { inherit config; };
  persistM2Root = "${ctx.homeDir}/.m2";
  persistM2RepositoryRoot = "${persistM2Root}/repository";
  persistM2Settings = "${persistM2Root}/settings.xml";
  persistM2SettingsSecurity = "${persistM2Root}/settings-security.xml";
in
{
  options = {
    chufang.lang.java.m2SettingsPath = lib.mkOption {
      type = lib.types.str;
      default = "\${localEnv:HOME}/.m2/settings.xml";
      description = "Path to maven settings.xml";
    };
    chufang.lang.java.m2SettingsSecurityPath = lib.mkOption {
      type = lib.types.str;
      default = "\${localEnv:HOME}/.m2/settings-security.xml";
      description = "Path to maven settings-security.xml";
    };
  };

  config = {
    languages.java = with pkgs; {
      enable = true;
      jdk.package = lib.mkDefault jdk17;
      maven.enable = lib.mkDefault true;
    };

    packages = with pkgs; [
    ];

    devcontainer.settings = with pkgs; {
      mounts = [
        {
          source = "\${localEnv:HOME}/.m2/repository";
          target = persistM2RepositoryRoot;
          type = "bind";
        }
        {
          source = config.chufang.lang.java.m2SettingsPath;
          target = persistM2Settings;
          type = "bind";
          readonly = true;
        }
        {
          source = config.chufang.lang.java.m2SettingsSecurityPath;
          target = persistM2SettingsSecurity;
          type = "bind";
          readonly = true;
        }
      ];

      customizations = {
        vscode = {
          extensions = [
            "vscjava.vscode-java-pack"
            "vscjava.vscode-lombok"
            "redhat.java"
          ];
          settings = {
            "java.compile.nullAnalysis.mode" = "automatic";
          };
        };
      };
    };
  };
}
