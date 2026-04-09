if status is-interactive
    function __dotfiles_abbr --argument name expansion
        abbr --erase $name >/dev/null 2>/dev/null
        abbr --add --global $name -- $expansion
    end

    __dotfiles_abbr pi "pnpm install"
    __dotfiles_abbr px "pnpx"
    __dotfiles_abbr prd "pnpm run dev"
    __dotfiles_abbr prb "pnpm run build"
    __dotfiles_abbr prs "pnpm run start"
    __dotfiles_abbr prt "pnpm run test"
    __dotfiles_abbr prl "pnpm run lint"
    __dotfiles_abbr prf "pnpm run format"

    __dotfiles_abbr bi "bun install"
    __dotfiles_abbr bx "bunx"
    __dotfiles_abbr brd "bun run dev"
    __dotfiles_abbr brb "bun run build"
    __dotfiles_abbr brs "bun run start"
    __dotfiles_abbr brt "bun run test"
    __dotfiles_abbr brl "bun run lint"
    __dotfiles_abbr brf "bun run format"

    __dotfiles_abbr gfl "git fetch && git pull"
    __dotfiles_abbr dclaude "claude --dangerously-skip-permissions"
    __dotfiles_abbr dcodex "codex --dangerously-bypass-approvals-and-sandbox"

    if type -q python3
        alias py="python3"
        alias python="python3"
    end

    functions --erase __dotfiles_abbr
end
