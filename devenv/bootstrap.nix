{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  #chufangFlakeDirFilePath = ".devcontainer/chufang-flake-dir";

  absDevenvRoot = builtins.readFile inputs.devenv-root.outPath;

  absChufangFlakeDir = builtins.readFile inputs.chufang-flake-dir.outPath;
  relativeChufangFlakeDir = util.relativeFromTo absDevenvRoot absChufangFlakeDir;
  chufangFlakeDir = relativeChufangFlakeDir;

  isLocalChufang = inputs ? chufang-local-dir && inputs.chufang-local-dir != null;
  absChufangLocalDir =
    if isLocalChufang then builtins.readFile inputs.chufang-local-dir.outPath else null;
  util = pkgs.callPackage ./util.nix {
    inherit lib config;
  };
  relativeChufangLocalDir =
    if isLocalChufang then util.relativeFromTo absDevenvRoot absChufangLocalDir else null;

  containerAbsChufangLocalDir =
    if isLocalChufang then "\${containerWorkspaceFolder}/" + relativeChufangLocalDir else null;

  scoped = util.scoped;

  absStaticDir = "${absChufangFlakeDir}/.static";
  absStaticBinDir = "${absStaticDir}/bin";
  absStaticBinSh = "${absStaticBinDir}/sh";

  #   absChufangSecretsTmp = builtins.readFile inputs.chufang-secrets-tmp.outPath;
  #   absChufangSecretsLink = builtins.readFile inputs.chufang-secrets-link.outPath;
  relativeChufangSecretsDir = "${chufangFlakeDir}/.secrets";
  absChufangSecretsDir = "${absChufangFlakeDir}/.secrets";
  nixosMntConstants = import ../nixos/mnt-constants.nix;
  nixAccessTokensSecretsDir = nixosMntConstants.nixAccessTokensSecretsDir;
  relativeChufangSecretsNixAccessTokensDir = "${relativeChufangSecretsDir}/nix-access-tokens";
  absChufangSecretsNixAccessTokensDir = "${absChufangSecretsDir}/nix-access-tokens";

  #   absChufangSecretsTmpNixAccessTokensSecretsDir = "${absChufangSecretsTmp}/nix-access-tokens";
  #   relativeChufangSecretsLink = util.relativeFromTo absDevenvRoot absChufangSecretsLink;
  #   relativeChufangSecretsNixAccessTokensDir = "${relativeChufangSecretsLink}/nix-access-tokens";

  hostNixMnt = nixosMntConstants.hostNixMnt;
  persistNixMnt = nixosMntConstants.persistNixMnt;
  hostNixRegistryMnt = nixosMntConstants.hostNixRegistryMnt;
in
{
  tasks = {
    "infra:json:devcontainer" =
      let
        devcontainerJson = builtins.toJSON config.devcontainer.settings;
        devcontainerJsonFile = pkgs.writeText "devcontainer.json" devcontainerJson;
        targetPath = ".devcontainer/devcontainer.json";
      in
      {
        exec = ''
          mkdir -p ${chufangFlakeDir}
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
    # "infra:env:CHUFANG_FLAKE_DIR" = {
    #   exec = ''
    #     if SECRET=$(echo $CHUFANG_FLAKE_DIR 2>/dev/null); then
    #       echo $SECRET > ${chufangFlakeDirFilePath}
    #     fi
    #   '';
    #   status = ''
    #     CUR_DIR=$(echo $CHUFANG_FLAKE_DIR)
    #     if [ -f ${chufangFlakeDirFilePath} ]; then
    #       OLD_DIR=$(cat ${chufangFlakeDirFilePath})
    #       if [ "$CUR_DIR" = "$OLD_DIR" ]; then
    #         exit 0
    #       else
    #         exit 1
    #       fi
    #     else
    #       exit 1
    #     fi
    #   '';
    #   before = [ "devenv:enterShell" ];
    # };
    "infra:static:sh" =
      let
        pkgsSh = "${pkgs.pkgsStatic.bash}/bin/bash";
      in

      {
        exec = ''
          mkdir -p ${absStaticBinDir}
          install -D -m 755 ${pkgsSh} ${absStaticBinDir}/sh
        '';
        status = ''
          mkdir -p ${absStaticBinDir}
          CUR_SH="${pkgsSh}"
          OLD_SH="${absStaticBinDir}/sh"
          if [ -f "$OLD_SH" ] && cmp -s "$OLD_SH" "$CUR_SH"; then
            exit 0
          else
            exit 1
          fi
        '';
        before = [ "devenv:enterShell" ];
      };
    "infra:secrets:GITHUB_TOKEN" = {
      exec = ''
        mkdir -p ${relativeChufangSecretsNixAccessTokensDir}
        if SECRET=$(secretspec get GITHUB_TOKEN 2>/dev/null); then
          echo -n "$SECRET" > "${relativeChufangSecretsNixAccessTokensDir}/GITHUB_TOKEN.secret"
          chmod 600 "${relativeChufangSecretsNixAccessTokensDir}/GITHUB_TOKEN.secret"
        fi
      '';
      status = ''
        mkdir -p ${relativeChufangSecretsNixAccessTokensDir}
        OLD_SECRET=$(cat ${relativeChufangSecretsNixAccessTokensDir}/GITHUB_TOKEN.secret 2>/dev/null)
        CUR_SECRET=$(secretspec get GITHUB_TOKEN 2>/dev/null)
        if [ "$OLD_SECRET" = "$CUR_SECRET" ]; then
          exit 0
        else
          exit 1
        fi
      '';
      before = [ "devenv:enterShell" ];
    };
  };

  packages = with pkgs; [
    bashInteractive
    secretspec
  ];

  devcontainer.settings = with pkgs.lib; {

    #containerUser = "root";

    remoteUser = "vscode";

    image = "localhost/nixos-rebuild-base:latest";

    overrideCommand = false;

    updateRemoteUserUID = false;

    runArgs = [
      "--device=/dev/fuse"
      "--systemd=always"
      "--security-opt=seccomp=unconfined"
      /*
        https://github.com/NixOS/nix/blob/0e27c6740ed2dbf8bd1ec9e9faa80ed7ef39960b/src/libutil/linux/linux-namespaces.cc#L53
        Test whether we can remount /proc. The kernel disallows
                       this if /proc is not fully visible,
        bool mountAndPidNamespacesSupported()
          if (mount("none", "/proc", "proc", 0, 0) == -1)
      */
      "--security-opt=unmask=/proc/*"
      "--device=/dev/net/tun"
      "--userns=keep-id"
      # "--group-add=keep-groups"
    ];

    capAdd = [
      "SYS_ADMIN"
      "NET_ADMIN"
      "SETUID"
      "SETGID"
    ];

    mounts = [
      #   {
      #     source = absChufangSecretsTmp;
      #     target = "\${containerWorkspaceFolder}/" + relativeChufangSecretsLink;
      #     type = "bind";
      #   }
      {
        source = absStaticBinSh;
        target = "/bin/sh";
        type = "bind";
      }
      {
        source = absChufangSecretsNixAccessTokensDir;
        target = nixAccessTokensSecretsDir;
        type = "bind,readonly";
      }
      {
        source = "/nix";
        target = hostNixMnt;
        type = "bind,readonly";
      }
      {
        source = scoped "nix-persist";
        target = persistNixMnt;
        type = "volume";
      }
      {
        source = "/etc/nix/registry.json";
        target = hostNixRegistryMnt;
        type = "bind,readonly";
      }
    ]
    ++ (
      if isLocalChufang then
        [
          {
            source = "\${localWorkspaceFolder}/" + relativeChufangLocalDir;
            target = "\${containerWorkspaceFolder}/" + relativeChufangLocalDir;
            type = "bind";
          }
        ]
      else
        [ ]
    );

    #entrypoint = [ "/init" ];

    waitFor = "postStartCommand";

    customizations = {
      vscode = {
        extensions = [
          "mkhl.direnv"
        ];
        settings = {
          #   "terminal.integrated.defaultProfile.linux" = "bash";
          #   "terminal.integrated.profiles.linux" = {
          #     "bash" = {
          #       # "path" = "/run/wrappers/bin/sudo";
          #       # "args" = [
          #       #   "/run/current-system/sw/bin/login"
          #       #   "-p"
          #       #   "-f"
          #       #   "vscode"
          #       # ];
          #       "path" = "/bin/bash";
          #       "args" = [
          #         "-c"
          #         "exec -a bash sudo -E /run/current-system/sw/bin/systemd-run --pty --quiet --property=User=vscode --property=PAMName=login --property=Delegate=yes --property=WorkingDirectory=/workspaces/typewriter/ /run/current-system/sw/bin/bash -l"
          #       ];

          #       # "args" = [
          #       #   "-E"
          #       #   "/run/current-system/sw/bin/systemd-run"
          #       #   "--pty"
          #       #   "--quiet"
          #       #   "--property=User=vscode"
          #       #   "--property=PAMName=login"
          #       #   "--property=Delegate=yes"
          #       #   "--property=WorkingDirectory=\${containerWorkspaceFolder}/"
          #       #   "/run/current-system/sw/bin/bash"
          #       #   "-l"
          #       # ];
          #       "overrideName" = true;
          #     };
          #   };
          "files.exclude" = {
            "**/.git" = true;
            "**/.direnv" = true;
            "**/.devenv" = true;
            "**/.devenv.*" = true;
          };
          "files.watcherExclude" = {
            "**/.git" = true;
            "**/.direnv" = true;
            "**/.devenv" = true;
            "**/.devenv.*" = true;
          };
          "search.exclude" = {
            "**/.git" = true;
            "**/.direnv" = true;
            "**/.devenv" = true;
            "**/.devenv.*" = true;
          };

          "terminal.integrated.inheritEnv" = true;
          "direnv.restart.automatic" = false;
          "window.title" =
            "\${localWorkspaceFolderBasename} 🫕 \${activeEditorShort}\${separator}\${rootName}";
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

    onCreateCommand = ''
      set -e
      id
      cat /etc/group
      cat /etc/passwd
      systemctl is-system-running --wait
      id
      cat /etc/group
      cat /etc/passwd
      nix registry list
      CMD="sudo nixos-rebuild switch --flake path:${chufangFlakeDir}#devos --override-input nixpkgs nixpkgs"
      ${lib.optionalString isLocalChufang ''CMD="$CMD --override-input chufang git+file://${containerAbsChufangLocalDir}"''}
      echo $CMD
      $CMD
    '';

    postStartCommand = ''
      set -e
      systemctl is-system-running --wait || true
      direnv allow .
      direnv exec . devenv test
    '';

    updateContentCommand = ''
      
    '';
  };
}
