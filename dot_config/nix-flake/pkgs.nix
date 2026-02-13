{
  pkgs,
  pkgs-master ? null,
  ...
}:

let
  common = [
    pkgs.aha # Converet ANSI escape sequences to HTML
    pkgs.avahi
    pkgs.bash
    pkgs.bat
    pkgs.bitwarden-cli
    pkgs.buf
    pkgs.bun
    pkgs.chezmoi
    pkgs.copilot-language-server
    pkgs.coreutils-full
    pkgs.delta
    pkgs.deno
    pkgs.direnv
    pkgs.duf
    pkgs.eza
    pkgs.fd
    pkgs.ffmpeg
    pkgs.fish
    pkgs.fzf
    pkgs.gawk
    # pkgs.gcc # use one in system to avoid not found error from ld
    pkgs.gdu
    pkgs.gh
    pkgs.ghq
    pkgs.git
    pkgs.glab
    pkgs.gnugrep
    pkgs.gnumake
    pkgs.gnused
    pkgs.go
    pkgs.go-task
    pkgs.gojq
    pkgs.google-cloud-sdk
    pkgs.grpcurl
    pkgs.htop
    pkgs.hyperfine
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
    pkgs.ninja
    pkgs.nodejs
    # pkgs.ollama
    pkgs.pandoc
    pkgs.pnpm
    pkgs.podman
    pkgs.podman-compose
    pkgs.procs
    pkgs.python312
    pkgs.quarto
    pkgs.ripgrep
    pkgs.rsync
    pkgs.sheldon
    pkgs.silicon
    pkgs.sqlx-cli
    pkgs.terraform
    pkgs.tmux
    pkgs.trash-cli
    pkgs.typst
    pkgs.uv
    pkgs.watch
    pkgs.wget2
    pkgs.zig
    pkgs.zoxide

    # language servers
    pkgs.gopls
    pkgs.lua-language-server
    pkgs.emmylua-ls
    pkgs.nixd
    pkgs.nodePackages_latest.bash-language-server
    pkgs.basedpyright
    pkgs.terraform-ls
    pkgs.typescript-language-server
    pkgs.yaml-language-server
    pkgs.vscode-langservers-extracted # JSON, HTML, CSS, ESLint
    pkgs.vtsls

    # formatters/linters
    # pkgs.actionlint
    pkgs.air-formatter
    pkgs.biome
    pkgs.checkmate
    pkgs.gotools
    pkgs.nixfmt
    pkgs.oxlint
    pkgs.prettierd
    pkgs.ruff
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.stylua
    pkgs.treefmt

    # rust
    pkgs.cargo
    pkgs.clippy
    pkgs.crate2nix
    pkgs.rust-analyzer
    pkgs.rust.packages.stable.rustc-unwrapped
    pkgs.rustfmt
  ];
in
{
  x86_64-linux = common ++ [
    pkgs.paru
  ];
  aarch64-darwin = common ++ [
    pkgs.docker-compose
    pkgs.mas
    pkgs.terminal-notifier

    # https://github.com/BatteredBunny/brew-nix
    pkgs.brewCasks.chatgpt
    pkgs.brewCasks.keycastr
    pkgs.brewCasks.libreoffice
    pkgs.brewCasks.slack
    pkgs.brewCasks.raycast
    pkgs.brewCasks.vlc
  ];
  aarch64-darwin-brews = [
    "dnsmasq" # remains here to solve *.localhost by https://zenn.dev/lambdalisue/scraps/db98eb60fa9d21
  ];
  aarch64-darwin-casks = [
    "docker-desktop"
    "firefox" # pkgs or brewCasks works, but without firefox as terminal command
    "google-chrome"
    "macskk" # pkgs.macskk fails to setup input source
    "meetingbar" # pkgs.brewCasks.meetingbar fails to start
    "r-app" # pkgs.brewCasks.r does not exist and pkgs.brewCasks.r-app fails to start
    "karabiner-elements" # pkgs fails to setup privilege and pkgs.brewCasks wont't even install
    "spotify" # pkgs.brewCasks.spotify fails to start
    "wezterm@nightly"
  ];
  fonts = [
    pkgs.ibm-plex
    pkgs.noto-fonts-color-emoji
    pkgs.udev-gothic
    pkgs.udev-gothic-nf
  ];
}
