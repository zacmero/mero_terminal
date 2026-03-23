return {
  -- 1. Keep Dracula installed so it's available in your list
  {
    "dracula/vim",
    lazy = false,
    priority = 1000,
    -- We removed the "config" part that forced it to load every time
  },

  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, _colors)
        hl.NeoTreeGitUntracked = { fg = "#44FFB1" }
        hl.NeoTreeGitAdded = { fg = "#44FFB1" }
      end,
    },
  },

  -- 2. Tell LazyVim which theme to actually use as the default on startup
  -- Change "tokyonight" to "dracula" here whenever you want to switch back
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight", 
    },
  },
}
