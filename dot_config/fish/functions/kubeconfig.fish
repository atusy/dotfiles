function kubeconfig
  set -l RES ( find "$HOME/.kube" -mindepth 1 -maxdepth 1 -type f | grep -v '/kubectx$' | fzf --preview 'cat {}' )
  test -f "$RES" && export KUBECONFIG="$RES"
end

