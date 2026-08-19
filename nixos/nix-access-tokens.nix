{
  config,
  lib,
  pkgs,
  ...
}:
let
  isTemplateUnitMode = config.chufang.nix.isTemplateUnitMode;

  runtimeDirName = "chufang/nix-access-tokens";
  runtimeDir = "/run/${runtimeDirName}";

  mntConstants = import ./mnt-constants.nix;
  nixAccessTokensSecretsDir = mntConstants.nixAccessTokensSecretsDir;

  nixAccessTokensConfPath = "${runtimeDir}/nix-access-tokens.conf";
in
{
  imports = [
    ./core-options.nix
  ];

  config = lib.mkMerge [
    ({
      systemd.services.nix-access-tokens = {
        wantedBy = [ ];
        before = [ ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = runtimeDirName;
        };

        script = ''
          tokens=()
          if [ -d "${nixAccessTokensSecretsDir}" ]; then
            shopt -s nullglob
            for file in "${nixAccessTokensSecretsDir}"/*; do
              if [ -f "$file" ]; then
                content=$(< "$file")
                content=$(echo "$content" | xargs)
                if [ -n "$content" ]; then
                  tokens+=("$content")
                fi
              fi
            done
          fi

          access_tokens="''${tokens[*]}"
          cat << EOF > ${nixAccessTokensConfPath}
          access-tokens = $access_tokens
          EOF
        '';
      };

      nix.extraOptions = ''
        !include ${nixAccessTokensConfPath}
      '';
    })

    (
      let
        nixAccessTokensService = "nix-access-tokens.service";
        wants = [ nixAccessTokensService ];
        after = [ nixAccessTokensService ];
      in
      {
        systemd.services.nix-daemon = lib.mkIf (!isTemplateUnitMode) {
          inherit wants after;
        };

        systemd.services."nix-daemon@" = lib.mkIf isTemplateUnitMode {
          inherit wants after;
        };
      }
    )
  ];
}
