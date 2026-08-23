-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Let Neovim own mouse input again so normal mode actions and right-click
-- behavior remain consistent. Hold Shift in the terminal when you want raw
-- terminal selection/paste behavior instead of editor mouse handling.
opt.mouse = "a"
vim.o.mousemodel = "extend"
opt.clipboard = "unnamedplus"

-- Force OSC 52 clipboard provider in SSH, Herdr, containers, or headless environments
-- so yanking escapes directly through the terminal to the client's system clipboard.
local is_remote = vim.env.SSH_TTY ~= nil
  or vim.env.SSH_CLIENT ~= nil
  or vim.env.SSH_CONNECTION ~= nil
  or vim.env.HERDR_SESSION ~= nil
  or vim.env.REMOTE_CONTAINERS ~= nil
  or vim.env.MERO_FORCE_OSC52 == "1"
  or (vim.env.WAYLAND_DISPLAY == nil and vim.env.DISPLAY == nil)

if is_remote then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
