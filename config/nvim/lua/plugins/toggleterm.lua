return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "horizontal",
      size = 12,
      close_on_exit = true,
      shell = vim.o.shell,
    },
    config = function(_, opts)
      local function set_terminal_highlights()
        vim.cmd([[
          highlight ToggleTerm guibg=NONE ctermbg=NONE
          highlight ToggleTermBorder guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE
        ]])
      end

      require("toggleterm").setup(opts)
      set_terminal_highlights()

      local function set_terminal_keymaps()
        local keymap_opts = { buffer = 0 }

        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], keymap_opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], keymap_opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], keymap_opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], keymap_opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], keymap_opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], keymap_opts)
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], keymap_opts)
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = set_terminal_keymaps,
      })

      vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm direction=horizontal<cr>", {
        noremap = true,
        silent = true,
        desc = "Toggle terminal",
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = set_terminal_highlights,
      })
    end,
  },
}
