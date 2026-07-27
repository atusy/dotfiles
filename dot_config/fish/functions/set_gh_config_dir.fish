function set_gh_config_dir --on-variable PWD
  if set -l ghq_root (ghq root)
    set -l pattern ^(string escape --style regex "$ghq_root"/github.com/)"([^/]+)"
    if set -l candidate "$HOME/.config/gh_"(string match --groups-only --regex "$pattern" "$PWD"); and test -d "$candidate"
      set -gx GH_CONFIG_DIR "$candidate"
      return
    end
  end
  if test -d "$PWD/.config/gh_default"
    set -gx GH_CONFIG_DIR "$HOME/.config/gh_default"
    return
  end
  set -e GH_CONFIG_DIR
end
