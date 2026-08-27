return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Force git cloning and standard C compiler to avoid tree-sitter CLI parser header panic
      local install_ok, install = pcall(require, "nvim-treesitter.install")
      if install_ok then
        install.prefer_git = true
        install.compilers = { "gcc", "clang", "cc" }
      end

      opts.ensure_installed = opts.ensure_installed or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "go",
          "gomod",
          "gosum",
          "gowork",
          "latex",
          "vim",
          "vimdoc",
        })
      end
    end,
  },
}

