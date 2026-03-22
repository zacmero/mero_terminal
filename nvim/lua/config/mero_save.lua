local M = {}

local uv = vim.uv or vim.loop

local function buf_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  return vim.fs.normalize(name)
end

local function cwd()
  if uv and uv.cwd then
    return vim.fs.normalize(uv.cwd())
  end
  return vim.fs.normalize(vim.fn.getcwd())
end

local function default_filename()
  return os.date("note-%Y%m%d-%H%M%S.txt")
end

local function file_exists(path)
  local stat = uv and uv.fs_stat(path)
  return stat ~= nil, stat
end

local function save_to_path(path)
  if not path or path == "" then
    return
  end

  local expanded = vim.fs.normalize(vim.fn.expand(path))
  local parent = vim.fs.dirname(expanded)
  if parent and parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end

  vim.cmd(("confirm saveas %s"):format(vim.fn.fnameescape(expanded)))
end

local function prompt_for_target(default_path)
  vim.ui.input({
    prompt = "Save As > ",
    default = default_path,
    completion = "file",
  }, function(value)
    if not value or value == "" then
      return
    end
    save_to_path(value)
  end)
end

local function suggested_path(selected)
  local current = buf_path()
  local fallback = current or (cwd() .. "/" .. default_filename())
  if not selected or selected == "" then
    return fallback
  end

  local ok, stat = file_exists(selected)
  if ok and stat and stat.type == "directory" then
    local filename = current and vim.fs.basename(current) or default_filename()
    return (selected:gsub("/+$", "")) .. "/" .. filename
  end

  return vim.fs.normalize(selected)
end

function M.save()
  if buf_path() == nil then
    return M.save_as()
  end
  vim.cmd("silent write")
end

function M.save_as()
  local current = buf_path()
  local start_dir = current and vim.fs.dirname(current) or cwd()
  local snacks = rawget(_G, "Snacks")

  if snacks and snacks.picker and snacks.picker.files then
    snacks.picker.files({
      title = "Save As: pick a file or directory",
      dirs = { start_dir },
      hidden = true,
      ignored = true,
      follow = true,
      confirm = function(picker, item)
        picker:close()
        local target = item and item.file or nil
        vim.schedule(function()
          prompt_for_target(suggested_path(target))
        end)
      end,
    })
    return
  end

  prompt_for_target(suggested_path(nil))
end

return M
