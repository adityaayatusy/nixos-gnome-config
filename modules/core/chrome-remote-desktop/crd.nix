{ pkgs, lib, ... }:
with lib;
let
  environment.systemPackages = with pkgs; [
    xorg.xdpyinfo
    xorg.xf86videodummy
    xorg.xorgserver
    pipewire
    wireplumber
  ];

  libPath = lib.makeLibraryPath [
      pkgs.gtk3
      pkgs.libutempter
      pkgs.xorg.libX11
      pkgs.xorg.libXScrnSaver
      pkgs.xorg.libXext
      pkgs.nss
      pkgs.python312Packages.packaging
      pkgs.python312Packages.psutil
      pkgs.python312Packages.pyxdg
      pkgs.xorg.xf86videodummy
      pkgs.xorg.xvfb
      pkgs.xorg.setxkbmap
      pkgs.xorg.xauth
      pkgs.xorg.xdpyinfo
      pkgs.xorg.xrandr
      pkgs.glib
      pkgs.xdg-utils
    ];

  chromeRemoteDesktop = pkgs.stdenv.mkDerivation rec {
    name = "chrome-remote-desktop";

    src = pkgs.fetchurl {
      url = "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb";
      sha256 = "1mys1xrh3q5axig5m62hkqf81pgy22jvvamxj7vwpvvfqmbhp9r0";  # Ensure this is correct
    };

    buildInputs = [ pkgs.makeWrapper pkgs.libvmaf ];

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      ${pkgs.dpkg}/bin/dpkg -x $src $out
    '';

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper $out/opt/google/chrome-remote-desktop/chrome-remote-desktop $out/bin/chrome-remote-desktop
    '';

    patchPhase = ''
      sed -i \
      -e '/^.*sudo_command =/ s/"gksudo .*"/"pkexec"/' \
      -e '/^.*command =/ s/s -- sh -c/s sh -c/' \
      $out/opt/google/chrome-remote-desktop/chrome-remote-desktop
      
      for file in $out/opt/google/chrome-remote-desktop/*; do
        if [ -f "$file" ]; then
          echo "Processing $file with size $(stat -c%s "$file") bytes"
          fileType=$(file "$file")
          echo "File type: $fileType"
          if [[ "$fileType" == *"text"* ]]; then
            substituteInPlace "$file" \
              --replace "/opt/google/chrome-remote-desktop" "/run/current-system/sw/bin/" \
              --replace "/usr/bin/python3" "${pkgs.python3.withPackages (ps: with ps; [ psutil pyxdg packaging ])}/bin/python3" \
              --replace "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
              --replace "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
              --replace "/usr/bin/gpasswd" "${pkgs.shadow}/bin/gpasswd" \
              --replace "/usr/bin/groupadd" "${pkgs.shadow}/bin/groupadd" \
              --replace "xdpyinfo" "${pkgs.xorg.xdpyinfo}/bin/xdpyinfo" \
              --replace "FIRST_X_DISPLAY_NUMBER = 20" "FIRST_X_DISPLAY_NUMBER = 0" \
              --replace "while os.path.exists(X_LOCK_FILE_TEMPLATE % display):" "# while os.path.exists(X_LOCK_FILE_TEMPLATE % display):" \
              --replace "display += 1" "# display += 1" \
              --replace "self.launch_x_session()" "# self.launch_x_session()"
          else
            echo "File $file is a binary file, skipping."
          fi
        else
          echo "File $file not found!"
        fi
      done
    '';

    preFixup = ''
      for i in $out/opt/google/chrome-remote-desktop/{chrome-remote-desktop-host,start-host,native-messaging-host,remote-assistance-host,user-session}; do
        patchelf --set-rpath "${libPath}" $i
        patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $i
      done
    '';

    meta = {
      description = "Chrome Remote Desktop for remote access to your computer.";
      homepage = "https://remotedesktop.google.com/";
      license = pkgs.lib.licenses.unfree;
    };
  };

  cfg = {
    user = "change-username";
    group = "users";
  };

in {
  #programs.zsh.initExtra = '''';

  environment = {
    etc = {
      "chromium/native-messaging-hosts/com.google.chrome.remote_assistance.json".source = "${chromeRemoteDesktop}/etc/opt/chrome/native-messaging-hosts/com.google.chrome.remote_assistance.json";
      "chromium/native-messaging-hosts/com.google.chrome_remote_desktop.json".source = "${chromeRemoteDesktop}/etc/opt/chrome/native-messaging-hosts/com.google.chrome_remote_desktop.json";
    };
    systemPackages = with pkgs; [
      chromeRemoteDesktop
      chromium
    ];
  };

  security = {
    wrappers.crd-user-session = {
      source = "${chromeRemoteDesktop}/opt/google/chrome-remote-desktop/user-session";
      owner = "${cfg.user}";
      group = "${cfg.group}";
    };

    pam.services.chrome-remote-desktop.text = ''
      auth        required    pam_unix.so
      account     required    pam_unix.so
      password    required    pam_unix.so
      session     required    pam_unix.so
    '';
  };

  users.groups.chrome-remote-desktop = {};

  users.users."${cfg.user}".extraGroups = [ "chrome-remote-desktop" ];

  systemd.packages = [
    chromeRemoteDesktop
  ];

  systemd.tmpfiles.rules = [
    "d /opt/google 0755 change-username users"
  ];
  #env LD_LIBRARY_PATH=/run/current-system/sw/lib:$LD_LIBRARY_PATH
  systemd.services."pre-chrome-remote-desktop@root" = {
    description = "pre setup chrome remote desktop";
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "/run/current-system/sw/bin/rm -rf /opt/google/chrome-remote-desktop";
      ExecStart = "/run/current-system/sw/bin/ln -s ${chromeRemoteDesktop}/opt/google/chrome-remote-desktop /opt/google/chrome-remote-desktop";
      ExecStartPost = "/run/current-system/sw/bin/zsh -c \"export LD_LIBRARY_PATH=/run/current-system/sw/lib:${libPath}:$LD_LIBRARY_PATH\"";
      RemainAfterExit = false;
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."chrome-remote-desktop@${cfg.user}" = {
    enable = true;
    description = "Chrome Remote Desktop instance for ${cfg.user}";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "${cfg.user}";
      Environment = "XDG_SESSION_CLASS=user XDG_SESSION_TYPE=x11";
      PAMName = "chrome-remote-desktop";
      TTYPath = "/dev/chrome-remote-desktop";
      ExecStart = "${chromeRemoteDesktop}/opt/google/chrome-remote-desktop/chrome-remote-desktop --start --new-session";
      ExecReload = "${chromeRemoteDesktop}/opt/google/chrome-remote-desktop/chrome-remote-desktop --reload";
      ExecStop = "${chromeRemoteDesktop}/opt/google/chrome-remote-desktop/chrome-remote-desktop --stop";
      StandardOutput = "journal";
      StandardError = "inherit";
      RestartForceExitStatus = "41";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
