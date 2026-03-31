if not status is-interactive
    return
end

if not type -q fzf
    return
end

set -l fzf_color '--color=fg:-1,fg+:#d0d0d0,bg:-1,bg+:#262626,hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00,prompt:#00d7ff,spinner:#af5fff,pointer:#af5fff,header:#87afaf,border:#262626,label:#aeaeae,query:#d9d9d9'
set -l fzf_layout '--border=rounded --prompt="> " --marker="*" --pointer=">" --separator="-" --scrollbar="|" --info=right --height=100% --preview-window=right:50%:border-rounded'
set -gx FZF_DEFAULT_OPTS "$fzf_color $fzf_layout --ansi --bind 'ctrl-h:change-preview-window(hidden|)' --preview '$FZF_PREVIEW_SCRIPT {}'"

if type -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --hidden --follow --exclude .git --exclude node_modules --exclude venv --exclude .venv'
else
    set -gx FZF_DEFAULT_COMMAND 'find . -path "*/.git" -prune -o -path "*/node_modules" -prune -o -print'
end
