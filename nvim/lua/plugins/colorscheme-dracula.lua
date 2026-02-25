return {
  -- 1. Keep Dracula installed so it's available in your list
  {
    "dracula/vim",
    lazy = false,
    priority = 1000,
    -- We removed the "config" part that forced it to load every time
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
