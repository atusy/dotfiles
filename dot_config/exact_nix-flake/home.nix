{ config, pkgs, pkgs-master, ... }:

{
  home.username = "atusy";
  home.homeDirectory = "/home/atusy";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  nixpkgs.config.allowUnfree = true;

  home.packages = (import ./pkgs.nix { inherit pkgs; inherit pkgs-master; }).x86_64-linux;

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true; # let home-manager manages itself
}
