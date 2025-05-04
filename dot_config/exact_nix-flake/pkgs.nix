{ pkgs, ... }:

let
  common = [
    pkgs.aha # Converet ANSI escape sequences to HTML
    pkgs.avahi
    pkgs.bash
    pkgs.bat
    pkgs.chezmoi
    pkgs.delta
    pkgs.deno
    pkgs.direnv
    pkgs.duf
    pkgs.gdu
    pkgs.htop
    pkgs.eza
    pkgs.go
    pkgs.go-task
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
    pkgs.mypy
    pkgs.neovim # nightly
    pkgs.nodejs
    pkgs.pandoc
    pkgs.pnpm
    pkgs.podman
    pkgs.podman-compose
    pkgs.procs
    pkgs.python312
    pkgs.ripgrep
    pkgs.rsync
    pkgs.terraform
    pkgs.tmux
    pkgs.trash-cli
    pkgs.uv
    pkgs.wget2
    pkgs.zoxide

    # language servers
    pkgs.gopls
    pkgs.lua-language-server
    pkgs.nil
    pkgs.nixd
    pkgs.nodePackages_latest.bash-language-server
    pkgs.nodePackages_latest.vscode-json-languageserver
    pkgs.pyright
    pkgs.typescript-language-server
    pkgs.terraform-ls
    pkgs.yaml-language-server

    # formatters/linters
    pkgs.actionlint
    pkgs.biome
    pkgs.checkmate
    pkgs.nixfmt-rfc-style
    pkgs.ruff
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.stylua
  ];
in
{
  x86_64-linux = [
    pkgs.paru
  ] ++ common;
  aarch64-darwin = [
  ] ++ common;
  fonts = [
    pkgs.udev-gothic
    pkgs.udev-gothic-nf
    pkgs.noto-fonts-color-emoji
    pkgs.ibm-plex
  ];
}
