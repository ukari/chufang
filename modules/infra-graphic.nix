{
  pkgs,
  ...
}:
let
  localDir = "./.devcontainer/.local";
  xauthorityAuthPath = "${localDir}/.Xauthority";
in
{
  packages = with pkgs; [
    mangohud
    mesa
    mesa-demos
    vulkan-loader
    vulkan-tools
  ];

  env = {
    LIBGL_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
    LD_LIBRARY_PATH = "${pkgs.mesa}/lib:${pkgs.vulkan-loader}/lib";
  };

  tasks = {
    "infra:auth:xauthority" =
      let
        xauthorityAuthPathEnv = "\${XAUTHORITY}";
      in
      {
        exec = ''
          mkdir -p ${localDir}
          if [ -n "${xauthorityAuthPathEnv}" ] && [ -f "${xauthorityAuthPathEnv}" ]; then
            cat "${xauthorityAuthPathEnv}" > ${xauthorityAuthPath}
          fi
        '';
        status = ''
          diff -q ${xauthorityAuthPathEnv} ${xauthorityAuthPath}
        '';
        before = [ "devenv:enterShell" ];
      };
  };

  devcontainer.settings = {
    runArgs = [
      "--device=/dev/dri"
      "--ipc=host"
      "--group-add=keep-groups"
    ];

    mounts = [
      {
        source = "${xauthorityAuthPath}";
        target = "/tmp/.Xauthority";
        type = "bind";
        readonly = true;
      }
      {
        source = "/tmp/.X11-unix/";
        target = "/tmp/.X11-unix/";
        type = "bind";
        readonly = true;
      }
    ];

    containerEnv = {
      DISPLAY = "\${localEnv:DISPLAY}";
      XAUTHORITY = "/tmp/.Xauthority";
    };
  };
}
