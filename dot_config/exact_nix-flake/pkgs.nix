{ pkgs, ... }:

let
  common = [
    pkgs.aha # Converet ANSI escape sequences to HTML
    pkgs.avahi
    pkgs.bash
    pkgs.bat
    pkgs.bun
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
    # pkgs.gcc # use one in system to avoid not found error from ld
    pkgs.gdu
    pkgs.gh
    pkgs.ghq
    pkgs.git
    pkgs.glab
    pkgs.go
    pkgs.go-task
    pkgs.gojq
    pkgs.google-cloud-sdk
    pkgs.htop
    pkgs.jq
    pkgs.kind
    pkgs.kubectl
    pkgs.kubectx
    pkgs.lnav
    pkgs.mise
    pkgs.mypy
    pkgs.neovim # nightly
    pkgs.neovim-remote
    pkgs.nodejs
    pkgs.ollama
    pkgs.pandoc
    pkgs.pnpm
    pkgs.podman
    pkgs.podman-compose
    pkgs.procs
    pkgs.python312
    pkgs.ripgrep
    pkgs.rsync
    pkgs.sheldon
    pkgs.terraform
    pkgs.tmux
    pkgs.trash-cli
    pkgs.uv
    pkgs.watch
    pkgs.wget2
    pkgs.zoxide

    # language servers
    pkgs.gopls
    pkgs.lua-language-server
    pkgs.nixd
    pkgs.nodePackages_latest.bash-language-server
    pkgs.pyright
    pkgs.rust-analyzer
    pkgs.terraform-ls
    pkgs.typescript-language-server
    pkgs.yaml-language-server
    pkgs.vscode-langservers-extracted # JSON, HTML, CSS, ESLint
    pkgs.vtsls

    # formatters/linters
    pkgs.actionlint
    pkgs.biome
    pkgs.checkmate
    pkgs.gotools
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
    pkgs.bitwarden-cli # fails on aarch64-darwin
  ] ++ common;
  aarch64-darwin = [
  ] ++ common;
  fonts = [
    pkgs.ibm-plex
    pkgs.noto-fonts-color-emoji
    pkgs.udev-gothic
    pkgs.udev-gothic-nf
  ];
}
