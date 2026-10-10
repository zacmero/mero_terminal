-- Validate Neovim's bundled parsers without downloading or compiling anything.
for _, language in ipairs({ "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc" }) do
  local ok, result = pcall(vim.treesitter.language.add, language)
  if not ok or not result then
    io.stderr:write("Unavailable bundled parser: " .. language .. "\n")
    vim.cmd("cquit 1")
    return
  end
end
