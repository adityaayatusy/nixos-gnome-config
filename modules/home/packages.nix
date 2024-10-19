{ inputs, pkgs, ... }: 
{
  home.packages = (with pkgs; [
    ## CLI utility
    ffmpeg
    openssl
    unzip
    wget
    yt-dlp
    dpkg

    ## GUI Apps
    libreoffice
    obs-studio
    pavucontrol                       # pulseaudio volume controle (GUI)  
    vlc

    # C / C++
    gcc
    gdb
    gnumake

    # Python
    python3
    python312Packages.ipython

    go
    bun
    jdk22
    nodejs_20
    pnpm
    docker
    docker-compose
    php

    brave

    vscode

    signal-desktop
    vesktop
    whatsapp-for-linux
    postman
    google-chrome

  ]);
}
