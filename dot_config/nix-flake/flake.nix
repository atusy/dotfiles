{
  description = "Home Manager configuration of atusy";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
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
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-master,
      home-manager,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-master = nixpkgs-master.legacyPackages.${system};
      overlays = [
        inputs.neovim-nightly-overlay.overlays.default
        inputs.fenix.overlays.default
        inputs.brew-nix.overlays.default
      ];
      darwinConfiguration =
        { pkgs, ... }:
        let
          pkgs2 = import ./pkgs.nix {
            inherit pkgs;
            pkgs-master = pkgs-master;
          };
        in
        {
          environment.systemPackages = pkgs2.aarch64-darwin;
          fonts.packages = pkgs2.fonts;
          homebrew = {
            # https://github.com/nix-darwin/nix-darwin/blob/master/modules/homebrew.nix
            enable = true;
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
            brews = pkgs2.aarch64-darwin-brews;
            casks = pkgs2.aarch64-darwin-casks;
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          system.primaryUser = darwinUser;

          system.defaults.dock = {
            autohide = true;
            autohide-delay = 0.0;
            autohide-time-modifier = 0.5;
          };

          system.defaults.finder = {
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            FXEnableExtensionChangeWarning = false;
            QuitMenuItem = true;
            ShowExternalHardDrivesOnDesktop = true;
            _FXSortFoldersFirst = true;
          };

          system.defaults.trackpad = {
            Clicking = true; # Enable tap to click
            TrackpadRightClick = true; # Enable two-finger tap for right click
          };

          system.defaults.NSGlobalDomain = {
            "com.apple.mouse.tapBehavior" = 1; # Enable tap to click for external trackpads
            "com.apple.swipescrolldirection" = false; # Natural scrolling: false = traditional scroll (reverse for mouse)
          };

          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.overlays = overlays;
          nixpkgs.config.allowUnfree = true;
        };
      darwinHost = builtins.getEnv "DARWIN_HOST";
      darwinUser = builtins.getEnv "DARWIN_USER";
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

          extraSpecialArgs = {
            pkgs-master = pkgs-master;
          };
        };
      }
    else
      {
        darwinConfigurations.${darwinHost} = nix-darwin.lib.darwinSystem {
          modules = [ darwinConfiguration ];
        };
      };
}
