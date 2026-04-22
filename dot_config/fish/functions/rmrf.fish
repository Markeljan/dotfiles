function rmrf --description "fast remove (rename + async delete with guardrails)"
    if test (count $argv) -eq 0
        printf 'rmrf: missing path\n' >&2
        return 1
    end

    for raw in $argv
        if test -z "$raw"
            printf 'rmrf: refusing empty path\n' >&2
            continue
        end

        switch "$raw"
            case '/' '.' '..' '~' '~/'
                printf 'rmrf: refusing dangerous path: %s\n' "$raw" >&2
                continue
        end

        set -l expanded "$raw"
        switch "$expanded"
            case '~'
                set expanded "$HOME"
            case '~/*'
                set expanded "$HOME/"(string sub -s 3 -- "$expanded")
        end

        if not test -e "$expanded"
            printf 'rmrf: not found: %s\n' "$raw" >&2
            continue
        end

        set -l trimmed "$expanded"
        if test "$trimmed" != "/"
            set trimmed (string replace -r '/+$' '' -- "$trimmed")
            if test -z "$trimmed"
                set trimmed "/"
            end
        end

        set -l target
        if test "$trimmed" = "/"
            set target "/"
        else
            set -l parent (path dirname -- "$trimmed")
            set -l base (path basename -- "$trimmed")
            set -l parent_abs (path resolve -- "$parent" 2>/dev/null)

            if test $status -ne 0 -o -z "$parent_abs" -o -z "$base"
                printf 'rmrf: could not resolve path: %s\n' "$raw" >&2
                continue
            end

            if test "$parent_abs" = "/"
                set target "/$base"
            else
                set target "$parent_abs/$base"
            end
        end

        if test "$target" = "/" -o "$target" = "$HOME"
            printf 'rmrf: refusing protected path: %s\n' "$target" >&2
            continue
        end

        set -l timestamp (date +%s 2>/dev/null)
        if test -z "$timestamp"
            set timestamp 0
        end

        set -l attempt 0
        set -l trash
        while true
            set attempt (math "$attempt + 1")
            set trash "$target.__trash__.$timestamp.$fish_pid.$attempt"
            if not test -e "$trash"
                break
            end
        end

        set -l mv_output (command mv -- "$target" "$trash" 2>&1)
        set -l mv_status $status
        if test $mv_status -ne 0
            if test -d "$target"; and not test -L "$target"
                set -l content_attempt 0
                set -l content_trash
                while true
                    set content_attempt (math "$content_attempt + 1")
                    set content_trash "$target/.rmrf-contents.__trash__.$timestamp.$fish_pid.$content_attempt"
                    if not test -e "$content_trash"
                        break
                    end
                end

                if command mkdir -- "$content_trash"
                    set -l content_trash_base (path basename -- "$content_trash")
                    if command find "$target" -mindepth 1 -maxdepth 1 ! -name "$content_trash_base" -exec mv -- '{}' "$content_trash"/ \;
                        command rm -rf -- "$content_trash" >/dev/null 2>&1 &
                        printf 'rmrf: cleared contents of %s (async); kept directory after rename failed\n' "$target"
                        continue
                    end
                    command rmdir -- "$content_trash" >/dev/null 2>&1
                end
            end

            if test (count $mv_output) -gt 0
                printf '%s\n' $mv_output >&2
            end
            printf 'rmrf: failed to stage path for deletion: %s\n' "$target" >&2
            continue
        end

        command rm -rf -- "$trash" >/dev/null 2>&1 &
        printf 'rmrf: removed %s (async)\n' "$target"
    end
end
