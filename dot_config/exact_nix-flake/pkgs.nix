{ pkgs, ... }:

let
  common = [
    pkgs.aha # Converet ANSI escape sequences to HTML
    pkgs.avahi
    pkgs.bash
    pkgs.bat
    pkgs.bitwarden-cli
    pkgs.chezmoi
    pkgs.delta
    pkgs.deno
    pkgs.direnv
    pkgs.duf
    pkgs.eza
    pkgs.fd
    pkgs.ffmpeg
    pkgs.fish
    pkgs.fzf
    pkgs.gdu
    pkgs.gh
    pkgs.ghq
    pkgs.git
    pkgs.go
    pkgs.go-task
    pkgs.gojq
    pkgs.google-cloud-sdk
    pkgs.htop
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
    pkgs.nixd
    pkgs.nodePackages_latest.bash-language-server
    pkgs.nodePackages_latest.vscode-json-languageserver
    pkgs.pyright
    pkgs.rust-analyzer
    pkgs.terraform-ls
    pkgs.typescript-language-server
    pkgs.yaml-language-server
    pkgs.vtsls

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
