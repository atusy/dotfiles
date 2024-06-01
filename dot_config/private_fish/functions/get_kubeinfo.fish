set -g __kube_config
set -g __kube_ctx
set -g __kube_ns
set -g __kube_ts 0

function __update_kubeinfo
  # normalize KUBECONFIG
  if set -qx KUBECONFIG; and string match -q -r '^~/' "$KUBECONFIG"
    eval "set -gx KUBECONFIG $KUBECONFIG"
  end

  # update if KUBECONFIG path has changed
  set -l __kube_config_default ~/.kube/config
  if set -qx KUBECONFIG; and test -n "$KUBECONFIG"
    if not test "$__kube_config" = "$KUBECONFIG"
      set __kube_config "$KUBECONFIG"
      set __kube_ts 0
      set __kube_ctx
      set __kube_ns
    end
  else if not test "$__kube_config" = "$__kube_config_default"
    set __kube_config "$__kube_config_default"
    set __kube_ts 0
    set __kube_ctx
    set __kube_ns
  end

  # abort if KUBECONFIG is not found
  if not test -f $__kube_config
    return 1
  end

  # update if KUBECONFIG content has updated
  set -l ts ( stat -c "%Y" "$__kube_config" )
  if test "$ts" -eq "$__kube_ts"
    return 0
  end
  set __kube_ts $ts

  # get ctx
  set __kube_ctx (kubectl config current-context 2>/dev/null)
  if test -z "$__kube_ctx"
    return 1
  end

  # get ns
  set __kube_ns (kubectl config view -o "jsonpath={.contexts[?(@.name==\"$__kube_ctx\")].context.namespace}")
  test -z $__kube_ns; and set __kube_ns 'N/A'
end

function get_kubeinfo --description "Get current kubernetes context and namespace with kubectl"
  __update_kubeinfo # use cache for performance
  echo $__kube_ctx $__kube_ns
end
