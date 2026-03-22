-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local mero_save = require("config.mero_save")

local function after_normalizing_mode(callback)
  return function()
    local mode = vim.api.nvim_get_mode().mode

    if mode:sub(1, 1) == "i" or mode:sub(1, 1) == "R" then
      vim.cmd.stopinsert()
      vim.schedule(callback)
      return
    end

    if mode == "v" or mode == "V" or mode == "\22" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
      vim.schedule(callback)
      return
    end

    callback()
  end
end

local save = after_normalizing_mode(mero_save.save)
local save_as = after_normalizing_mode(mero_save.save_as)
local ctrl_shift_s = vim.api.nvim_replace_termcodes("<Esc>[9002u", true, false, true)

vim.keymap.set({ "n", "i", "x" }, "<C-s>", save, { desc = "Save File" })
vim.keymap.set({ "n", "i", "x" }, "<C-S-s>", save_as, { desc = "Save File As" })
vim.keymap.set({ "n", "i", "x" }, ctrl_shift_s, save_as, { desc = "Save File As" })

vim.keymap.set("n", "<leader>ii", function()
  require("neo-tree.command").execute({
    action = "show",
    source = "filesystem",
    position = "left",
    dir = vim.uv.cwd(),
    reveal = true,
  })
end, { desc = "Mero IDE (cwd)" })
