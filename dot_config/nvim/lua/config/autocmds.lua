local group = vim.api.nvim_create_augroup("dotfiles_nvim", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function(args)
    if #vim.api.nvim_list_uis() == 0 then
      return
    end

    vim.cmd([[silent! aunmenu PopUp.How-to\ disable\ mouse]])
    vim.cmd([[silent! aunmenu PopUp.-2-]])

    local is_directory = args.file ~= "" and vim.fn.isdirectory(args.file) == 1

    if is_directory then
      vim.cmd.cd(args.file)
      vim.cmd.enew()
    end

    vim.cmd("Neotree show left")

    if #vim.api.nvim_list_wins() > 1 then
      vim.cmd("wincmd p")
    end
  end,
})
