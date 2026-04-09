local function tree_and_editor_only()
  local tree_windows = 0
  local editor_windows = 0

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      tree_windows = tree_windows + 1
    else
      editor_windows = editor_windows + 1
    end
  end

  return tree_windows > 0 and editor_windows <= 1
end

local function smart_quit(write)
  if tree_and_editor_only() then
    vim.cmd(write and "wqall" or "qall")
    return
  end

  vim.cmd(write and "wq" or "q")
end

vim.api.nvim_create_user_command("SmartQuit", function()
  smart_quit(false)
end, {})

vim.api.nvim_create_user_command("SmartWriteQuit", function()
  smart_quit(true)
end, {})

vim.cmd([[cnoreabbrev <expr> q getcmdtype() ==# ':' && getcmdline() ==# 'q' ? 'SmartQuit' : 'q']])
vim.cmd([[cnoreabbrev <expr> wq getcmdtype() ==# ':' && getcmdline() ==# 'wq' ? 'SmartWriteQuit' : 'wq']])
