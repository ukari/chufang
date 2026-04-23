{
  pkgs,
  config,
  lib,
  ...
}:
{
  languages.python = with pkgs; {
    enable = true;
    version = "3.11";
    uv = {
      enable = true;
    };
  };

  packages = with pkgs; [
  ];

  devcontainer.settings = with pkgs; {
    mounts = [
      
    ];

    customizations = {
      vscode = {
        extensions = [
          "ms-python.python"
          "charliermarsh.ruff"
          "ms-python.debugpy"
          "kevinrose.vsc-python-indent"
        ];
        settings = {
          "python.defaultInterpreterPath" = "\${workspaceFolder}/.devenv/state/venv/bin/python";
          "[python]" = {
            "editor.defaultFormatter" = "charliermarsh.ruff";
            "editor.formatOnSave"= true;
            "editor.codeActionsOnSave"= {
              "source.fixAll.ruff" = "explicit";
               "source.organizeImports.ruff" = "explicit";
            };
          };
        };
      };
    };
  };
}
