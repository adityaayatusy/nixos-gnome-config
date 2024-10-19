{ inputs, nixpkgs, self, username, host, ...}:
{
  imports = [
    ./bootloader.nix
    ./hardware.nix
    ./gnome.nix
    ./xserver.nix
    ./network.nix
    ./nh.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./steam.nix
    ./system.nix
    ./user.nix
    ./virtualization.nix
    ./wayland.nix
    ./rocm.nix
    ./chrome-remote-desktop.nix
  ];
}