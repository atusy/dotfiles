# variables for async behavior
set -l sid (status -f | shasum | string match -r "^[\S]+")
set -l varname_prefix "___"$sid"_"$fish_pid"_"
set -l varname_prompt_extra $varname_prefix"prompt_extra"
set -U $varname_prompt_extra
set -l varname_prompt_request $varname_prefix"prompt_request"
set -U $varname_prompt_request false

# clean universal variables related to this script
function __clean_$sid --on-event fish_exit --inherit-variable varname_prefix --inherit-variable sid
  # erase universal variable created on this process
  set -e -U (set -n -U | string match -r "^"$varname_prefix)

  # erase orphant universal variable
  set -l pids
  set -n -U | string match --regex --groups-only "^___"$sid"_([0-9]+)_" | sort -u | while read -l pid
    set -l comm (ps -p $pid -o comm=)
    if test "_$comm" != "_fish"
      set --append pids $pid
    end
  end
  if test -z "$pids"
    return
  end
  set -l pat "^___"$sid"_("(string join "|" $pids)")_.*"
  set -e -U (set -n -U | string match -r $pat)
end

function __repaint_prompt --on-variable $varname_prompt_extra
  set -U --no-event $varname_prompt_request false
  commandline -f repaint
end

function fish_prompt_info_extra_async --inherit-variable varname_prompt_extra --inherit-variable varname_prompt_request
  fish -c "
    set -U $varname_prompt_extra (fish_prompt_info_extra)
    set -U $varname_prompt_request true
  " &
  echo -n $varname_prompt_extra
end
