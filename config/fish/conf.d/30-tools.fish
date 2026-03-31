if status is-interactive
    if type -q zoxide
        zoxide init fish | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q direnv
        direnv hook fish | source
    end

    if type -q fnm
        fnm env --use-on-cd | source
    end
end

if test -f $HOME/.config/fish/local.fish
    source $HOME/.config/fish/local.fish
end
