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
      style = "night",
      -- 1. Change the background color variable
      on_colors = function(colors)
        colors.bg = "#222436"
        colors.bg_sidebar = "#22243a"
        colors.bg_float = "#20283a"
      end,
      on_highlights = function(hl, _colors)
        hl.NeoTreeGitUntracked = { fg = "#44ff8f" }
        hl.NeoTreeGitAdded = { fg = "#44ff8f" }
        hl.GitSignsAddNr = { fg = "#44ff8f" }
        hl.GitSignsAddLn = { fg = "#44ff8f" }
        hl.GitSignsAddPreview = { fg = "#44ff8f" }
        hl.GitSignsStagedAddNr = { fg = "#44ff8f" }
        hl.GitSignsStagedAddLn = { fg = "#44ff8f" }

        -- Bright clear blue for modifications (code changes)
        hl.GitSignsChange = { fg = "#58d6ff" }
        hl.GitSignsChangeNr = { fg = "#58d6ff", bold = true }
        hl.GitSignsChangeLn = { fg = "#58d6ff" }
        hl.GitSignsChangedelete = { fg = "#58d6ff" }
        hl.GitSignsChangedeleteNr = { fg = "#58d6ff", bold = true }
        hl.GitSignsChangedeleteLn = { fg = "#58d6ff" }
        hl.GitSignsStagedChange = { fg = "#58d6ff" }
        hl.GitSignsStagedChangeNr = { fg = "#58d6ff", bold = true }
        hl.GitSignsStagedChangeLn = { fg = "#58d6ff" }
        hl.GitSignsStagedChangedelete = { fg = "#58d6ff" }
        hl.GitSignsStagedChangedeleteNr = { fg = "#58d6ff", bold = true }
        hl.GitSignsStagedChangedeleteLn = { fg = "#58d6ff" }
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
