set -l cmd bat
if type -q $cmd
    function cat --inherit-variable cmd
        command $cmd $argv
    end
end
