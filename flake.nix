{
  description = "FrostPhoenix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, self, ... } @ inputs: 
  let
    username = "change-username";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
  in
  {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/desktop
          { home-manager.backupFileExtension = "backup"; }
        ];
        specialArgs = { host = "desktop"; inherit self inputs username; };
      };

      # Uncomment these sections if you have configurations for laptop and VM
      # laptop = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   modules = [ ./hosts/laptop ];
      #   specialArgs = { host = "laptop"; inherit self inputs username; };
      # };
      # vm = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   modules = [ ./hosts/vm ];
      #   specialArgs = { host = "vm"; inherit self inputs username; };
      # };
    };
  };
}
