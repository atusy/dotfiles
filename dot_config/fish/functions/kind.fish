function kind
  if not set -qx KUBE_CONFIG; or test -z "$KUBE_CONFIG"
    set -gx KUBE_CONFIG "$HOME/.kube/kind.yml"
  end
  command kind $argv
end
