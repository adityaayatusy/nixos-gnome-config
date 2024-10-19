{ pkgs, lib, inputs, ... }: with lib; 
let

  extra-path = with pkgs; [
    temurin-bin-17
    zip
  ];

  extra-lib = with pkgs; [
    libglvnd
    alsa-lib
    libpulseaudio
  ];

  manifest = ''
    Manifest-Version: 1.0
    Main-Class: com.azefsw.audioconnect.desktop.app.MainKt
    Specification-Title: Java Platform API Specification
    Specification-Version: 17
    Specification-Vendor: Oracle Corporation
    Implementation-Title: Java Runtime Environment
    Implementation-Version: 17.0.6
    Implementation-Vendor: Eclipse Adoptium
    Created-By: 17.0.5 (Eclipse Adoptium)
  '';

  _audiorelay = pkgs.stdenv.mkDerivation {
    pname = "audiorelay";
    version = "0.27.5";

    src = pkgs.fetchzip {
      url = "https://dl.audiorelay.net/setups/linux/audiorelay-0.27.5.tar.gz";
      hash = "sha256-KfhAimDIkwYYUbEcgrhvN5DGHg8DpAHfGkibN1Ny4II=";
      stripRoot = false;
    };

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.zip ];

    patchPhase = ''
      mkdir -p META-INF

      echo '${manifest}' > META-INF/MANIFEST.MF
      zip -r lib/app/audiorelay.jar META-INF/MANIFEST.MF
    '';

    installPhase = ''
      runHook preInstall

      install -Dm644 lib/AudioRelay.png $out/share/pixmaps/audiorelay.png
      install -Dm644 lib/app/audiorelay.jar $out/share/audiorelay/audiorelay.jar
      install -Dm644 lib/runtime/lib/libnative-rtaudio.so $out/lib/libnative-rtaudio.so
      install -Dm644 lib/runtime/lib/libnative-opus.so $out/lib/libnative-opus.so

      makeWrapper ${pkgs.temurin-bin-17}/bin/java $out/bin/audiorelay \
        --add-flags "-jar $out/share/audiorelay/audiorelay.jar" \
        --prefix LD_LIBRARY_PATH : $out/lib/ \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"

      runHook postInstall
    '';

    meta = {
      description = "Application to stream every sound from your PC to one or multiple Android devices";
      homepage = "https://audiorelay.net";
      license = pkgs.lib.licenses.unfree;
    };
  };

in 
{
  home.packages = with pkgs; [
    _audiorelay
  ];

  home.file = { ".local/share/applications/audiorelay.desktop".source =
    let desktopFile = pkgs.makeDesktopItem {
      name = "audiorelay";
      desktopName = "AudioRelay";
      exec = "\"${_audiorelay}/bin/audiorelay\"";
      icon = "audiorelay";
      type = "Application";
      startupNotify = true;
      categories = [ "AudioVideo" "Audio" "Network" ];
    }; 
    in "${desktopFile}/share/applications/audiorelay.desktop";
  };
}
