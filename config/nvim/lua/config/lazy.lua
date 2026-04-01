local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"

  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  checker = {
    -- Avoid startup update notifications; update plugins manually with :Lazy update.
    enabled = false,
  },
  change_detection = {
    notify = false,
  },
})

local bun_node_host = vim.fn.expand("~/.bun/bin/neovim-node-host")

if vim.fn.executable(bun_node_host) == 1 then
  vim.g.node_host_prog = bun_node_host
end

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
