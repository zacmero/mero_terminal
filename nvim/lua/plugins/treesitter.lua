return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = {
        "go",
        "gomod",
        "gosum",
        "gowork",
        "latex",
        "vim",
        "vimdoc",
      },
    },
  },
}
