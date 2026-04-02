set -g fish_greeting

set -l onepassword_agent "$HOME/.1password/agent.sock"

if test -S "$onepassword_agent"
    set -gx SSH_AUTH_SOCK "$onepassword_agent"
end
