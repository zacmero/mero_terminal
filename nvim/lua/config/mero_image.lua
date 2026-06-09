local M = {}

local image_patterns = {
  "*.png",
  "*.jpg",
  "*.jpeg",
  "*.gif",
  "*.webp",
  "*.avif",
  "*.bmp",
  "*.ico",
  "*.tif",
  "*.tiff",
}

local function resolve_backend()
  local forced = vim.env.MERO_IMAGE_BACKEND
  if forced and forced ~= "" then
    forced = forced:lower()
    if forced == "chafa" then
      return nil
    end
    return forced
  end

  if vim.env.KITTY_WINDOW_ID and vim.env.KITTY_WINDOW_ID ~= "" then
    return "kitty"
  end

  if vim.env.TERM_PROGRAM == "WezTerm" or vim.env.TERM == "wezterm" or vim.env.WEZTERM_EXECUTABLE then
    return "sixel"
  end

  if vim.fn.executable("ueberzugpp") == 1 and (vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY) then
    return "ueberzug"
  end

  return nil
end

local function render_with_chafa(bufnr, path)
  if vim.fn.executable("chafa") ~= 1 then
    return false, "chafa is not installed"
  end

  local width = math.max(vim.api.nvim_win_get_width(0) - 2, 40)
  local height = math.max(vim.api.nvim_win_get_height(0) - 4, 12)
  local output = vim.fn.systemlist({
    "chafa",
    "--format=symbols",
    "--stretch",
    ("--size=%dx%d"):format(width, height),
    path,
  })

  if vim.v.shell_error ~= 0 then
    return false, table.concat(output, "\n")
  end

  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].filetype = "text"
  vim.api.nvim_buf_set_name(bufnr, vim.fn.fnamemodify(path, ":p"))

  return true
end

local function setup_chafa_fallback()
  local group = vim.api.nvim_create_augroup("MeroImagePreview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = image_patterns,
    callback = function(args)
      local ok, err = render_with_chafa(args.buf, args.file)
      if not ok then
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, { err or "Image preview failed." })
        vim.bo[args.buf].modifiable = false
        vim.bo[args.buf].readonly = true
        vim.bo[args.buf].buftype = "nofile"
        vim.bo[args.buf].bufhidden = "wipe"
        vim.bo[args.buf].swapfile = false
        vim.bo[args.buf].filetype = "text"
        vim.api.nvim_err_writeln(("MeroImage: %s"):format(err or "Image preview failed"))
      end
    end,
  })
end

function M.setup()
  local backend = resolve_backend()
  local ok, image = pcall(require, "image")

  if ok and backend then
    image.setup({
      backend = backend,
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          only_render_image_at_cursor_mode = "popup",
          floating_windows = false,
          filetypes = { "markdown", "markdown_inline" },
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      scale_factor = 1.0,
      kitty_direct_chunk_size = 4096,
      window_overlap_clear_enabled = false,
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = false,
      hijack_file_patterns = image_patterns,
    })
    return
  end

  setup_chafa_fallback()
end

return M
