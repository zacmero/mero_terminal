-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Let Neovim own mouse input again so normal mode actions and right-click
-- behavior remain consistent. Hold Shift in the terminal when you want raw
-- terminal selection/paste behavior instead of editor mouse handling.
opt.mouse = "a"
vim.o.mousemodel = "extend"
