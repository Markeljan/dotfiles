local group = vim.api.nvim_create_augroup("dotfiles_nvim", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function(args)
    if #vim.api.nvim_list_uis() == 0 then
      return
    end

    local is_directory = args.file ~= "" and vim.fn.isdirectory(args.file) == 1

    if is_directory then
      vim.cmd.cd(args.file)
      vim.cmd.enew()
    end

    vim.cmd("Neotree show left")
    vim.cmd("wincmd p")

    if vim.bo.buftype == "" and vim.bo.modifiable then
      vim.schedule(function()
        vim.cmd("startinsert")
      end)
    end
  end,
})
