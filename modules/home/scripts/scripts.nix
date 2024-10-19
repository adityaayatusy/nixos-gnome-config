{ pkgs, ... }:

let
  # navigation-btn-layout = pkgs.writeScriptBin "navigation-btn-layout" (builtins.readFile ./scripts/nav-right.sh);
in {
  home.activation = {
    set-button-layout = ''
      exec ~/nixos-config/scripts/nav-right.sh
    '';
  };
}