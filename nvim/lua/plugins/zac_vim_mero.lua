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
    version = "*", -- Use the latest stable release
    lazy = true,
    ft = "markdown", -- Only load when you open a markdown file
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      local workspaces = {}

      local configured_vault = vim.env.OBSIDIAN_VAULT_DIR
      if configured_vault and configured_vault ~= "" then
        table.insert(workspaces, {
          name = "vault",
          path = configured_vault,
        })
      end

      table.insert(workspaces, {
        name = "current-markdown-dir",
        path = function()
          return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
        end,
        overrides = {
          notes_subdir = vim.NIL,
          new_notes_location = "current_dir",
          templates = {
            folder = vim.NIL,
          },
          disable_frontmatter = true,
        },
      })

      return {
        workspaces = workspaces,
      }
    end,
  },
}
