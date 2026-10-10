return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Lite installations control parser setup explicitly; skip bulk update builds.
    build = (function() if vim.env.MERO_LITE == "1" or vim.env.MERO_INSTALLING == "1" then return false end end)(),
    opts = function(_, opts)
      local ok, ts = pcall(require, "nvim-treesitter")
      if (vim.env.MERO_LITE == "1" or vim.env.MERO_INSTALLING == "1") and ok and ts.get_installed then
        -- Tree-sitter's own job pool is independent of Lazy/build concurrency.
        if not ts._mero_serial then
          for _, name in ipairs({ "install", "update" }) do
            local original = ts[name]
            ts[name] = function(languages, options)
              options = vim.tbl_extend("force", options or {}, { max_jobs = 1 })
              return original(languages, options)
            end
          end
          ts._mero_serial = true
        end
        -- Use bundled parsers in lite mode; extra parsers are an explicit user action.
        opts.ensure_installed = {}
        return
      end
      -- These legacy compiler settings only apply to the older Tree-sitter API.
      if not (ok and ts.get_installed) then
        local install_ok, install = pcall(require, "nvim-treesitter.install")
        if install_ok then
          install.prefer_git = true
          install.compilers = { "gcc", "clang", "cc" }
        end
      end
      opts.ensure_installed = opts.ensure_installed or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "go", "gomod", "gosum", "gowork", "latex", "vim", "vimdoc",
        })
      end
    end,
  },
}
