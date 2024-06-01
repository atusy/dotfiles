function get_kubeinfo2 --description "Get current kubernetes context and namespace with gojq (much faster than get_kubeinfo which uses kubectl)"
  set -l kubeconfig ~/.kube/config
  set -qx "$KUBECONFIG"; and test -n "$KUBECONFIG"; and set kubeconfig "$KUBECONFIG"
  if not test -f $kubeconfig
    return
  end
  set -l ctx ( cat $kubeconfig | gojq -r --yaml-input '.["current-context"] // ""' )
  if test -z $ctx
    return
  end
  set -l ns ( cat $kubeconfig | gojq -r --yaml-input ".contexts[] | select(.name == \"$ctx\") | .context.namespace // \"\"" )
  echo $ctx $ns
end
