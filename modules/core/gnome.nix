{ pkgs, lib, config, ... }:
{
  services = {
    gnome.gnome-keyring.enable = true;
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.debug = true;
      desktopManager.gnome.enable = true;
      desktopManager.gnome.debug = true;
      exportConfiguration = true;
    };
  };

  environment = {
    variables = config.environment.sessionVariables; 
    systemPackages = with pkgs; [
      gnome-tweaks
      gnome-extension-manager
      gnome-session

      #extension
      gnomeExtensions.dash-to-panel
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.removable-drive-menu
      gnomeExtensions.tiling-assistant
    ];
  };


  programs.dconf.profiles = {
    user.databases = [{
      settings = with lib.gvariant; {
        "org/gnome/shell/extensions/dash-to-panel" = {
          hide-overview-on-startup = true;
        };
      };
    }];
  };
}