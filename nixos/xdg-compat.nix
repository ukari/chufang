{
  config,
  lib,
  ...
}:
{
  environment.extraInit = ''
    if [ -z "$XDG_RUNTIME_DIR" ] && command -v loginctl >/dev/null 2>&1; then
      export XDG_RUNTIME_DIR=/run/user/$(id -u)
      
      if [ -n "$XDG_RUNTIME_DIR" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      fi
    fi
  '';
}
