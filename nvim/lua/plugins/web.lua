return {
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("colorizer").setup({
        filetypes = {
          "*",
          css = { rgb_fn = true, hsl_fn = true },
          html = { names = true },
          javascript = { names = true },
          javascriptreact = { names = true },
          scss = { names = true },
          typescript = { names = true },
          typescriptreact = { names = true },
          vue = { names = true },
          svelte = { names = true },
          astro = { names = true },
        },
        user_default_options = {
          tailwind = true,
          mode = "background",
          always_update = true,
          names = false,
        },
      })
    end,
  },
  {
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick", "CccHighlighterToggle", "CccConvert" },
    keys = {
      { "<leader>cp", "<cmd>CccPick<cr>", desc = "Pick Color" },
      { "<leader>ch", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle Color Highlighting" },
      { "<leader>cC", "<cmd>CccConvert<cr>", desc = "Convert Color" },
    },
    opts = {
      highlighter = {
        auto_enable = true,
        lsp = true,
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html",
      "javascriptreact",
      "typescriptreact",
      "svelte",
      "vue",
      "astro",
      "xml",
    },
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {},
        emmet_language_server = {},
        html = {},
        tailwindcss = {},
        tsserver = {},
      },
    },
  },
}
