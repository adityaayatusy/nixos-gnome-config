{ stdenvNoCC
, lib
, autoPatchelfHook
, dpkg
, fetchurl
, glib
, gtk3
, libdrm
, libutempter
, mesa
, nss
, pam
, python3
, shadow
, xorg
, makeWrapper
, libvmaf
, glibc
}:

let
  replacePrefix = "/opt/google/chrome-remote-desktop";
  
in
stdenvNoCC.mkDerivation rec {
  pname = "chrome-remote-desktop";
  # Get sri:
  # nix-prefetch-url https://dl.google.com/linux/chrome-remote-desktop/deb/pool/main/c/chrome-remote-desktop/chrome-remote-desktop_130.0.6723.14_amd64.deb | xargs nix-hash --to-sri --type sha256

  # Get the latest version from:
  # https://dl.google.com/linux/chrome-remote-desktop/deb/dists/stable/main/binary-amd64/Packages
  version = "130.0.6723.14";
  src = fetchurl {
    url = "https://dl.google.com/linux/chrome-remote-desktop/deb/pool/main/c/chrome-remote-desktop/chrome-remote-desktop_${version}_amd64.deb";
    hash = "sha256-IKcLV8Vu78v3kb2qvaUQ/t2AHJ5QmFpe7KrgAXMP2tc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    glib
    gtk3
    libdrm
    libutempter
    mesa
    nss
    pam
    xorg.libX11
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXtst
    xorg.libXScrnSaver
    xorg.xf86videodummy
    xorg.xf86videoamdgpu
    xorg.xvfb
    xorg.setxkbmap
    xorg.xauth
    xorg.xhost
    xorg.xdpyinfo
    makeWrapper
    libvmaf
  ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    runHook preUnpack

    ${dpkg}/bin/dpkg -x $src $out

    runHook postUnpack
  '';

  patchPhase = ''
    runHook prePatch

    sed \
      -e '/^.*sudo_command =/ s/"gksudo .*"/"pkexec"/' \
      -e '/^.*command =/ s/s -- sh -c/s sh -c/' \
      -i $out/opt/google/chrome-remote-desktop/chrome-remote-desktop

    substituteInPlace $out/lib/systemd/system/chrome-remote-desktop@.service \
      --replace /opt/google/chrome-remote-desktop/chrome-remote-desktop '${placeholder "out"}/bin/chrome-remote-desktop'

    substituteInPlace $out/etc/opt/chrome/native-messaging-hosts/com.google.chrome.remote_desktop.json \
      --replace ${replacePrefix}/native-messaging-host $out/${replacePrefix}/native-messaging-host \
      --replace ${replacePrefix}/remote-assistance-host $out/${replacePrefix}/remote-assistance-host

    for file in $out/opt/google/chrome-remote-desktop/*; do
      if [ -f "$file" ]; then
        fileType=$(file "$file")
        if [[ "$fileType" == *"text"* ]]; then
          substituteInPlace "$file" \
            --replace "/opt/google/chrome-remote-desktop" "$out/opt/google/chrome-remote-desktop" \
            --replace "/usr/bin/python3" "${python3.withPackages (ps: with ps; [ psutil pyxdg packaging ])}/bin/python3" \
            --replace '"Xvfb"' '"${xorg.xorgserver}/bin/Xvfb"' \
            --replace 'dpkg-query' '${dpkg}/bin/dpkg-query' \
            --replace '"Xorg"' '"${xorg.xorgserver}/bin/Xorg"' \
            --replace '"xrandr"' '"${xorg.xrandr}/bin/xrandr"' \
            --replace "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
            --replace "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
            --replace "/usr/bin/gpasswd" "${shadow}/bin/gpasswd" \
            --replace "/usr/bin/groupadd" "${shadow}/bin/groupadd" \
            --replace "xdpyinfo" "${xorg.xdpyinfo}/bin/xdpyinfo" \
            --replace "/usr/lib/xorg/modules" "${xorg.xorgserver}/lib/xorg/modules" \
            --replace "while os.path.exists(X_LOCK_FILE_TEMPLATE % display):" "# while os.path.exists(X_LOCK_FILE_TEMPLATE % display):" \
            --replace "display += 1" "# display += 1" \
            --replace "FIRST_X_DISPLAY_NUMBER = 20" "FIRST_X_DISPLAY_NUMBER = 0"
        fi
      fi
    done

    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    for i in "$out/opt/google/chrome-remote-desktop/"*; do
      if [[ ! -x "$i" ]]; then
        continue
      fi
      ln -s "$i" "$out/bin/"
    done

    cp ${./crd} $out/bin/crd
    substituteInPlace $out/bin/crd \
      --replace /opt/google/chrome-remote-desktop/chrome-remote-desktop $out/opt/google/chrome-remote-desktop/chrome-remote-desktop

    runHook postInstall
  '';

  meta = {
    description = "Access your computer or share your screen with others using your phone, tablet, or another device";
    homepage = "https://remotedesktop.google.com/";
    platforms = [ "x86_64-linux" ];
    license = with lib.licenses; [ unfree ];
    mainProgram = "chrome-remote-desktop";
    maintainers = with lib.maintainers; [ change-username ];
  };
}