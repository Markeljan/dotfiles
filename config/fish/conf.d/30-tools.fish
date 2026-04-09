if status is-interactive
    if type -q zoxide
        zoxide init fish | source
    end

    if type -q starship
        starship init fish | source
    end
end

if test -f $HOME/.config/fish/local.fish
    source $HOME/.config/fish/local.fish
end
