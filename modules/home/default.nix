{inputs, username, host, ...}: {
  imports = [
    ./audiorelay.nix
    ./bat.nix                         # audio visualizer
    ./fastfetch.nix                   # alternate neofetch
    ./git.nix                         # version control
    ./gtk.nix                         # gtk theme
    ./p10k/p10k.nix
    ./packages.nix                    # other packages
    ./starship.nix                    # shell prompt
    ./zsh                             # shell
    # ./scripts/scripts.nix
    ./jetbrains-toolbox.nix
  ];
}
