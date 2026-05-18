local M = {}

local patterns = {
  "*.docx",
  "*.DOCX",
  "*.doc",
  "*.DOC",
}

local function preview_lines(path)
  local helper = vim.fn.exepath("merodoc-preview")
  if helper == "" then
    return nil, "merodoc-preview helper is not installed"
  end

  local output = vim.fn.systemlist({ helper, path })
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(output, "\n")
  end

  if #output == 0 then
    return { "" }, nil
  end

  return output, nil
end

local function populate_buffer(bufnr, path)
  local lines, err = preview_lines(path)
  if not lines then
    return false, err
  end

  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].filetype = "markdown"
  vim.api.nvim_buf_set_name(bufnr, vim.fn.fnamemodify(path, ":p"))
  return true
end

function M.setup()
  local group = vim.api.nvim_create_augroup("MeroDocPreview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = patterns,
    callback = function(args)
      local ok, err = populate_buffer(args.buf, args.file)
      if not ok then
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, { err or "DOC preview failed." })
        vim.bo[args.buf].modifiable = false
        vim.bo[args.buf].readonly = true
        vim.bo[args.buf].buftype = "nofile"
        vim.bo[args.buf].bufhidden = "wipe"
        vim.bo[args.buf].swapfile = false
        vim.bo[args.buf].filetype = "text"
        vim.api.nvim_err_writeln(("MeroDoc: %s"):format(err or "DOC preview failed"))
      end
    end,
  })

  vim.api.nvim_create_user_command("MeroDoc", function(opts)
    local target = vim.trim(opts.args or "")
    if target == "" then
      target = vim.api.nvim_buf_get_name(0)
    else
      target = vim.fn.expand(target)
    end

    if target == "" then
      vim.notify("Usage: :MeroDoc {file.docx|file.doc}", vim.log.levels.INFO)
      return
    end

    vim.cmd.edit(vim.fn.fnameescape(target))
  end, {
    nargs = "?",
    complete = "file",
    desc = "Open a Word document preview",
  })
end

return M
