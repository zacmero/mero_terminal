-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

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
