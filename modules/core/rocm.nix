

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rocmPackages.rpp
    rocmPackages.clr
    rocmPackages.rccl
    rocmPackages.half
    rocmPackages.hipcc
    rocmPackages.rocm-smi
    gperftools
  ];
}