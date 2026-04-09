return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,
    popup_border_style = "rounded",
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
      window = {
        mappings = {
          ["<cr>"] = "open",
          ["l"] = "open",
          ["o"] = "open",
          ["P"] = { "toggle_preview", config = { use_float = false } },
        },
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    vim.cmd([[
      highlight NeoTreeNormal guibg=NONE ctermbg=NONE
      highlight NeoTreeNormalNC guibg=NONE ctermbg=NONE
      highlight NeoTreeEndOfBuffer guibg=NONE ctermbg=NONE
    ]])

    vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle left<cr>", {
      silent = true,
      desc = "Toggle file tree",
    })
  end,
}
