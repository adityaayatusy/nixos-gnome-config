{ pkgs, ... }: 
{
  home.packages = (with pkgs; [ 
      jetbrains-toolbox

      #(pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.goland ["github-copilot"])44
  ]);

    
}