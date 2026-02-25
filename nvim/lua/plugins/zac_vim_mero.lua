-- This is your new file: ~/.config/nvim/lua/plugins/custom.lua
return {

  -- 1. Override the width of neo-tree (your first question)
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        width = 25, -- Set the width you want
      },
    },
  },

  -- 2. Add the Todo Tree plugin
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {}, -- You can add configuration here later
  },

  -- 3. Add the Neogit (GitLens) plugin
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },

  -- 4. Add the Dendron/Obsidian plugin
  {
    "epwalsh/obsidian.nvim",
    -- This is an example of a more complex setup
    version = "*", -- Use the latest stable release
    lazy = true,
    ft = "markdown", -- Only load when you open a markdown file
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      -- This is where you would tell it where your notes are
      workspaces = {
        {
          name = "my-notes",
          path = "~/Documents/MyNotes", -- Change this to your notes folder
        },
      },
    },
  },
}
