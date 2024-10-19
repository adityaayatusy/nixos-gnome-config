{ ... }: 
{
  services = {
    gvfs.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
    thermald.enable = true;

    flatpak.enable = true;
    blueman.enable = true;
  };
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
}
