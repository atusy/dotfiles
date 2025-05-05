{
  description = "Home Manager configuration of atusy";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      home-manager,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
      darwinConfiguration =
        { pkgs, ... }:
        {
          environment.systemPackages = (import ./pkgs.nix { inherit pkgs; }).aarch64-darwin;
          fonts.packages = (import ./pkgs.nix { inherit pkgs; }).fonts;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          nixpkgs.config.allowUnfree = true;
        };
      darwinHost = builtins.getEnv "DARWIN_HOST";
      system = if darwinHost == "" then "x86_64-linux" else "aarch64-darwin";
    in
    if darwinHost == "" then
      {
        homeConfigurations."atusy" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./home.nix
          ];
        };
      }
    else
      {
        darwinConfigurations.${darwinHost} = nix-darwin.lib.darwinSystem {
          modules = [ darwinConfiguration ];
        };
      };
}
