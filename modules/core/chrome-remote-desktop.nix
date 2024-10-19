{ lib, config, pkgs,nixpkgs, ... }:

let
  chrome-remote-desktop = pkgs.callPackage ../../pkgs/chrome-remote-desktop/chrome-remote-desktop.nix {}; 
in
{
  
  environment = {
      etc = {
        "chromium/native-messaging-hosts/com.google.chrome.remote_assistance.json".source = "${chrome-remote-desktop}/etc/opt/chrome/native-messaging-hosts/com.google.chrome.remote_assistance.json";
        "chromium/native-messaging-hosts/com.google.chrome.remote_desktop.json".source = "${chrome-remote-desktop}/etc/opt/chrome/native-messaging-hosts/com.google.chrome.remote_desktop.json";
      };
      systemPackages = [ 
        chrome-remote-desktop 
        pkgs.xorg.xinit 
        pkgs.xorg.xhost
      ];
    };

    security = {
      wrappers.crd-user-session = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${chrome-remote-desktop}/opt/google/chrome-remote-desktop/user-session";
      };

      pam.services.chrome-remote-desktop.text = ''
        auth        required    pam_unix.so
        account     required    pam_unix.so
        password    required    pam_unix.so
        session     required    pam_unix.so
      '';
    };

    users.groups.chrome-remote-desktop = { };

    systemd.services."chrome-remote-desktop@change-username" = {
      enable = false;
      description = "Chrome Remote Desktop instance for %I";
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "change-username";
        Environment = "XDG_SESSION_CLASS=user XDG_SESSION_TYPE=x11";
        PAMName = "chrome-remote-desktop";
        TTYPath = "/dev/chrome-remote-desktop";
        ExecStart = "${chrome-remote-desktop}/bin/chrome-remote-desktop --start --new-session";
        ExecReload = "${chrome-remote-desktop}/bin/chrome-remote-desktop --reload";
        ExecStop = "${chrome-remote-desktop}/bin/chrome-remote-desktop --stop";
        StandardOutput = "journal";
        StandardError = "inherit";
        Restart = "always";
        RestartForceExitStatus = [ 41 ];
      };

      wantedBy = [ "multi-user.target" ];
    };

}