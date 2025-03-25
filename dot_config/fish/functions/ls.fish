set -l cmd eza
if type -q $cmd
    function ls --inherit-variable cmd
        command $cmd $argv
    end
end
