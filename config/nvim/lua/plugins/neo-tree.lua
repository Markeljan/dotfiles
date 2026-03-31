return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = false,
      enable_git_status = true,
      enable_diagnostics = true,
      window = {
        position = "left",
        width = 36,
      },
      filesystem = {
        hijack_netrw_behavior = "open_default",
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            vim.schedule(function()
              if vim.bo.buftype == "" and vim.bo.modifiable then
                vim.cmd("startinsert")
              end
            end)
          end,
        },
      },
    })

    vim.cmd([[
      highlight NeoTreeNormal guibg=NONE ctermbg=NONE
      highlight NeoTreeNormalNC guibg=NONE ctermbg=NONE
      highlight NeoTreeEndOfBuffer guibg=NONE ctermbg=NONE
    ]])

    vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle left<cr>", { silent = true, desc = "Toggle file tree" })
  end,
}

