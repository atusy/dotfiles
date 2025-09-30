{
  pkgs,
  pkgs-master ? null,
  ...
}:

let
  common = [
    pkgs.fenix.stable.completeToolchain
    pkgs.aha # Converet ANSI escape sequences to HTML
    pkgs.avahi
    pkgs.bash
    pkgs.bat
    pkgs.buf
    pkgs.bun
    pkgs.chezmoi
    pkgs.copilot-language-server
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
    pkgs.just
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
    pkgs.rustup
    pkgs.rsync
    pkgs.sheldon
    pkgs.sqlx-cli
    pkgs.terraform
    pkgs.tmux
    pkgs.trash-cli
    pkgs.uv
    pkgs.watch
    (
      # TODO(2025-08-05): use pkgs.wget2 when it become available in unstable branch
      # https://github.com/NixOS/nixpkgs/pull/429170
      if pkgs-master != null then pkgs-master.wget2 else pkgs.wget2
    )
    pkgs.zig
    pkgs.zoxide

    # language servers
    pkgs.gopls
    pkgs.lua-language-server
    pkgs.nixd
    pkgs.nodePackages_latest.bash-language-server
    pkgs.pyright
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
    pkgs.oxlint
    pkgs.prettierd
    pkgs.ruff
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.stylua
    pkgs.treefmt
  ];
in
{
  x86_64-linux = [
    pkgs.paru
    pkgs.bitwarden-cli # fails on aarch64-darwin
  ]
  ++ common;
  aarch64-darwin = [
  ]
  ++ common;
  fonts = [
    pkgs.ibm-plex
    pkgs.noto-fonts-color-emoji
    pkgs.udev-gothic
    pkgs.udev-gothic-nf
  ];
}
