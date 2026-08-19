{ config, lib, ... }: let 
  isSystemdTrue = val:
    builtins.elem (toString val) [ "1" "yes" "true" "on" ];
in {

  options.chufang.nix = {
    isLix = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      readOnly = true;
      description = "Whether the current Nix package is the Lix fork.";
    };

    isTemplateUnitMode = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      readOnly = true;
      description = "Whether the nix-daemon.socket is using per-connection socket activation (Accept=true).";
    };
  };

  config =
    let
      isLix = (config.nix.package.pname == "lix");
      isTemplateUnitMode =
        let
          socketConfig = config.systemd.sockets.nix-daemon.socketConfig;
        in
        (if socketConfig ? Accept then isSystemdTrue socketConfig.Accept else isLix);
    in
    {
      chufang.nix.isLix = isLix;
      chufang.nix.isTemplateUnitMode = isTemplateUnitMode;
    };
}
