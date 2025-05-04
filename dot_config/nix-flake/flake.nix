{
  description = "Home Manager configuration of atusy";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
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
          environment.systemPackages = (import ./pkgs.nix { inherit pkgs; }).system;
          fonts.packages = (import ./pkgs.nix { inherit pkgs; }).fonts;

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
      system = if darwinHost == "" then "x86_64-linux" else "aarch64-darwin";
    in
    if true then
      {
        homeConfigurations."atusy" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./home.nix
          ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      }
    else
      {
        darwinConfigurations.${darwinHost} = nix-darwin.lib.darwinSystem {
          modules = [ darwinConfiguration ];
        };
      };
}
