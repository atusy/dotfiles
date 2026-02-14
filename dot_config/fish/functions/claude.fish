set -l AGENTIC_SCRUM_REPOSITORY "github.com/atusy/agentic-scrum"
set -l AGENTIC_SCRUM_ROOT "$HOME/ghq/$AGENTIC_SCRUM_REPOSITORY"
set -l AGENTIC_SCRUM_PLUGIN "$AGENTIC_SCRUM_ROOT/claude-plugins/agentic-scrum"

if not type -q claude
  curl -fsSL https://claude.ai/install.sh | bash
end

if not test -d "$AGENTIC_SCRUM_ROOT"
  if type -q ghq
    ghq get "$AGENTIC_SCRUM_REPOSITORY"
  else
    git clone "https://$AGENTIC_SCRUM_REPOSITORY" -- "$AGENTIC_SCRUM_ROOT"
  end
else
  git -C "$AGENTIC_SCRUM_ROOT" pull --ff-only origin HEAD
end

function claude
  command claude \
    --dangerously-skip-permissions \
    --plugin-dir "$AGENTIC_SCRUM_PLUGIN" \
    $argv
end
