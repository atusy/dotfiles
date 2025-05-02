# Apply with:
# DARWIN_HOST=$(hostname -s) darwin-rebuild switch --flake ~/.config/nix-darwin --impure
{
  description = "personal darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          environment.systemPackages = (import ./system-packages.nix { inherit pkgs; }).system;
          fonts.packages = (import ./system-packages.nix { inherit pkgs; }).fonts;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          nixpkgs.config.allowUnfree = true;
        };
      darwinHost = builtins.getEnv "DARWIN_HOST";
    in
    {
      darwinConfigurations.${darwinHost} = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
