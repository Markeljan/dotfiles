function mkcd
    if test (count $argv) -eq 0
        printf 'mkcd: missing directory\n' >&2
        return 1
    end

    mkdir -p -- "$argv[1]"; and cd -- "$argv[1]"
end
