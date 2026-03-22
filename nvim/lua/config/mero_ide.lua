local M = {}

local preferred_patterns = {
  "README.md",
  "README.txt",
  "README",
  "readme.md",
  "**/README.md",
  "**/README.txt",
  "**/readme.md",
  "main.*",
  "index.*",
  "app.*",
  "init.*",
  "**/main.*",
  "**/index.*",
  "**/app.*",
  "**/init.*",
}

local function first_existing(matches)
  for _, match in ipairs(matches) do
    if vim.fn.filereadable(match) == 1 then
      return vim.fn.fnamemodify(match, ":p")
    end
  end
end

local function pick_recent_file(dir)
  local prefix = vim.fn.fnamemodify(dir, ":p")
  for _, file in ipairs(vim.v.oldfiles or {}) do
    local full = vim.fn.fnamemodify(file, ":p")
    if vim.startswith(full, prefix) and vim.fn.filereadable(full) == 1 then
      return full
    end
  end
end

local function pick_preferred_file(dir)
  for _, pattern in ipairs(preferred_patterns) do
    local matches = vim.fn.globpath(dir, pattern, false, true)
    local found = first_existing(matches)
    if found then
      return found
    end
  end
end

local function pick_git_file(dir)
  local files = vim.fn.systemlist({ "git", "-C", dir, "ls-files" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  for _, rel in ipairs(files) do
    local full = vim.fn.fnamemodify(dir .. "/" .. rel, ":p")
    if vim.fn.filereadable(full) == 1 then
      return full
    end
  end
end

local function pick_start_file(dir)
  return pick_recent_file(dir) or pick_preferred_file(dir) or pick_git_file(dir)
end

function M.open(target)
  local dir = target
  if dir == nil or dir == "" then
    dir = vim.env.MERO_IDE_TARGET or vim.uv.cwd()
  end
  dir = vim.fn.fnamemodify(dir, ":p")

  vim.cmd.cd(vim.fn.fnameescape(dir))

  local start_file = pick_start_file(dir)
  if start_file then
    vim.cmd.edit(vim.fn.fnameescape(start_file))
  else
    vim.cmd.enew()
  end

  vim.schedule(function()
    require("neo-tree.command").execute({
      action = "show",
      source = "filesystem",
      position = "left",
      dir = dir,
      reveal = true,
    })
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("MeroIde", function(opts)
    M.open(opts.args)
  end, { nargs = "?", desc = "Open Mero IDE layout" })
end

return M
