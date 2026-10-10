-- Headless Lazy commands can exit zero despite failed plugin tasks.
-- Convert missing checkouts/task errors into an actionable installer exit status.
local ok, config = pcall(require, "lazy.core.config")
if not ok then
  io.stderr:write("LazyVim installation check: lazy.nvim is unavailable\n")
  vim.cmd("cquit 1")
  return
end
local failed = false
for name, plugin in pairs(config.plugins) do
  if vim.fn.isdirectory(plugin.dir) ~= 1 then
    io.stderr:write("Missing plugin directory: " .. name .. "\n")
    failed = true
  end
  for _, task in ipairs(plugin._.tasks or {}) do
    if task:has_errors() then
      io.stderr:write("Plugin task failed: " .. name .. " / " .. task.name .. "\n")
      failed = true
    end
  end
end
if failed then vim.cmd("cquit 1") end
