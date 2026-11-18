function __ghq_root
    if not set -q __ghq_cached_root[1]
        set -l root (ghq root)
        or return 1
        test -n "$root"
        or return 1
        set -g __ghq_cached_root "$root"
    end
    printf '%s\n' "$__ghq_cached_root"
end
