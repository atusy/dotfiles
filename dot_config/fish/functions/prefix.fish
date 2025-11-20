set -g ___fish_commandline_prefix

function prefix
  set ___fish_commandline_prefix $argv ""
end

function ___apply_prefix --on-event fish_prompt
  commandline --replace "$___fish_commandline_prefix"
end
