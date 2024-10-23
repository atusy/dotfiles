{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "atusy";
  home.homeDirectory = "/home/atusy";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.bat
    pkgs.chezmoi
    pkgs.delta
    pkgs.deno
    pkgs.direnv
    pkgs.eza
    pkgs.fd
    pkgs.fish
    pkgs.fzf
    pkgs.google-cloud-sdk
    pkgs.gh
    pkgs.ghq
    pkgs.git
    pkgs.gojq
    pkgs.jq
    pkgs.kind
    pkgs.kubectl
    pkgs.kubectx
    pkgs.mise
    pkgs.neovim # nightly
    pkgs.nodejs
    pkgs.pandoc
    pkgs.podman
    pkgs.podman-compose
    pkgs.poetry
    pkgs.python312
    pkgs.tmux
    pkgs.trash-cli
    pkgs.ripgrep
    pkgs.zoxide

    # R
    (
      pkgs.radianWrapper.override {
        packages = with pkgs.rPackages; [
          clock
          ragg
          blogdown
          devtools
          DBI
          dbplyr
          duckdb
          felp
          pak
          tidyverse
          renv
          shiny
          testit
          testthat
          languageserver
        ];
        wrapR = true;
      }
    )

    # Fonts
    pkgs.udev-gothic
    pkgs.udev-gothic-nf
    pkgs.noto-fonts-color-emoji
    pkgs.ibm-plex

    # Example overlays
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/atusy/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
