{
  pkgs,
  config,
}:
let
  user = config.devcontainer.settings.remoteUser;
  homeDir = if user == "root" then "/root" else "/home/${user}";
  projectPath = config.devenv.root;
  projectName = builtins.baseNameOf projectPath;
  scoped = name: "${projectName}-\${devcontainerId}-${name}";
in
{
  inherit scoped user homeDir;
}
