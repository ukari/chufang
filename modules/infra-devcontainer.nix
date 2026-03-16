{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  defaultUser = "vscode";

  ctx = pkgs.callPackage ../lib/mk-context.nix { inherit config; };

  infra = pkgs.callPackage ../lib/mk-devcontainer.nix {
    inherit inputs;
    user = ctx.user;
    scoped = ctx.scoped;
    hostNixMnt = "/mnt/host-nix";
  };
in
{
  options = {
    devcontainer.settings = lib.mkOption {
      type = lib.types.submodule {
        options.postCreateCommand = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };
      };
    };
  };
  config = {

    packages = [ ] ++ infra.packages;

    tasks = {
      "infra:json:devcontainer" =
        let
          devcontainerJson = builtins.toJSON config.devcontainer.settings;
          devcontainerJsonFile = pkgs.writeText "devcontainer.json" devcontainerJson;
          targetPath = ".devcontainer/devcontainer.json";
        in
        {
          exec = ''
            mkdir -p .devcontainer
            [ -f ${targetPath} ] && [ -w ${targetPath} ] && { echo "${targetPath} is user-writable (manual changes detected)"; exit 1; }
            cp -fL ${devcontainerJsonFile} ${targetPath} && chmod 444 ${targetPath}
          '';
          status = ''
            [ -f ${targetPath} ] || exit 1
            [ -w ${targetPath} ] && exit 1
            diff -q ${devcontainerJsonFile} ${targetPath}
          '';
          before = [ "devenv:enterShell" ];
        };
    }
    // infra.tasks;

    devcontainer.enable = true;

    devcontainer.settings = with pkgs.lib; {
      name = mkDefault "\${localWorkspaceFolder}";
      remoteUser = mkDefault defaultUser;
      workspaceFolder = mkDefault "/workspaces/\${localWorkspaceFolderBasename}";
      #workspaceMount = mkDefault "source=\${localWorkspaceFolder},target=${config.devenv.root},type=bind,consistency=cached";
      updateRemoteUserUID = mkDefault false;

      runArgs = [
        "--init"
        "--tmpfs=/tmp:exec,mode=1777"
      ]
      ++ infra.runArgs;

      mounts = [
        {
          source = ctx.scoped "secretspec-config";
          target = "${ctx.homeDir}/.config/secretspec";
          type = "volume";
        }
      ]
      ++ infra.mounts;

      features = {
        "ghcr.io/devcontainers-extra/features/bash-command:1" = {
          "command" = ''
            set -e
            ${infra.initNixConf}
          '';
        };
      }
      // infra.features;

      containerEnv = {
      }
      // infra.containerEnv;

      onCreateCommand = ''
        set -e
        ${infra.setupMnt}
        ${infra.setupNixAccessTokenConf}
        ${infra.setupOverlay}
        ${infra.setupRegistry}
        direnv allow .
      '';

      updateContentCommand = ''
        direnv exec . devenv test
      '';

      postStartCommand = ''
        set -e
        ${infra.setupNixAccessTokenConf}
        ${infra.setupOverlay}
      '';

      customizations = {
        vscode = {
          extensions = [
            "saoudrizwan.claude-dev"
            "mkhl.direnv"
          ];

          settings = {
            "files.exclude" = {
              "**/.devenv" = true;
              "**/.devenv.*" = true;
            };
            "search.exclude" = {
              "**/.devenv" = true;
              "**/.devenv.*" = true;
            };

            "terminal.integrated.inheritEnv" = true;
            "direnv.restart.automatic" = false;
            "window.title" =
              "\${localWorkspaceFolderBasename} 🛡️ \${activeEditorShort}\${separator}\${rootName}";
            "workbench.colorCustomizations" = {
              "titleBar.activeBackground" = "#2E8B57";
              "titleBar.activeForeground" = "#FFFFFF";
              "titleBar.inactiveBackground" = "#2E8B5799";

              "statusBar.background" = "#6A0DAD";
              "statusBar.foreground" = "#FFFFFF";

              "activityBar.background" = "#1e1e1e";
              "activityBar.foreground" = "#a29f9f";
              "activityBar.activeBorder" = "#2E8B57";
              "editorGroup.border" = "#2E8B5744";
            };
          };
        };
      };
    };
  };

}
