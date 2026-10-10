-- Honor the installed mode even when launched outside an interactive Bash shell.
if vim.env.MERO_LITE == nil then
  local mode = vim.fn.resolve(vim.fn.expand("~/.config/mero-terminal/session.sh"))
  if mode:match("/lite%-session%.sh$") then vim.env.MERO_LITE = "1" end
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

require("config.mero_ide").setup()
require("config.mero_doc").setup()
require("config.mero_image").setup()

vim.opt.number = true
vim.opt.relativenumber = true

-- Show absolute number in Insert Mode, relative in Normal Mode
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  pattern = "*",
  command = "set norelativenumber",
})
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  pattern = "*",
  command = "set relativenumber",
})
