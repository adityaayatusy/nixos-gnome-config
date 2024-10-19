{ pkgs, ... }:
{  
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        amdvlk
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };

    };
  };
  hardware.enableRedistributableFirmware = true;
}
