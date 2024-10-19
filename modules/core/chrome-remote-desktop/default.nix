{ config, pkgs, ... }:

{ 
   imports =
     [
       ./service-crd.nix
     ];

   environment.systemPackages = with pkgs; [
     chromium
   ];
   
   services = {
     chrome-remote-desktop = {
       enable = true;
       user = "change-username";
     };
   };
   
   nixpkgs.overlays = [
     (self: super: {
       chrome-remote-desktop = super.callPackage ./crd.nix {};
     })
   ];
}