set -g ___fish_prompt_prefix

function preprompt
  set ___fish_prompt_prefix $argv ""
end

function __preprompt --on-event fish_prompt
  commandline --replace "$___fish_prompt_prefix"
end
