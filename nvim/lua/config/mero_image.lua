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

local video_patterns = {
  "*.mp4",
  "*.mkv",
  "*.mov",
  "*.webm",
  "*.avi",
  "*.m4v",
  "*.mpg",
  "*.mpeg",
  "*.ogv",
  "*.ts",
  "*.m2ts",
  "*.3gp",
  "*.flv",
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

local function prepare_preview_buffer(bufnr, display_path)
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "text"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })

  if display_path and display_path ~= "" then
    vim.api.nvim_buf_set_name(bufnr, vim.fn.fnamemodify(display_path, ":p"))
  end
end

local function cleanup_temp_file(path)
  if path and path ~= "" then
    pcall(vim.fn.delete, path)
  end
end

local function attach_cleanup(bufnr, temp_path, image_handle)
  local group = vim.api.nvim_create_augroup(("MeroMediaPreviewCleanup:%d"):format(bufnr), { clear = true })
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload", "WinClosed" }, {
    group = group,
    buffer = bufnr,
    once = true,
    callback = function()
      if image_handle and type(image_handle.clear) == "function" then
        pcall(function()
          image_handle:clear()
        end)
      end
      cleanup_temp_file(temp_path)
    end,
  })
end

local function render_with_chafa(bufnr, path, display_path)
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

  prepare_preview_buffer(bufnr, display_path or path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true

  return true
end

local function render_with_image_backend(bufnr, path, display_path)
  local backend = resolve_backend()
  local ok, image = pcall(require, "image")
  if not ok or not backend then
    return false, "image.nvim backend is unavailable"
  end

  prepare_preview_buffer(bufnr, display_path or path)
  local win = vim.api.nvim_get_current_win()
  local image_handle = image.from_file(path, {
    window = win,
    buffer = bufnr,
    with_virtual_padding = false,
  })

  if not image_handle then
    return false, "image.nvim could not create a preview handle"
  end

  attach_cleanup(bufnr, path ~= display_path and path or nil, image_handle)
  local rendered, render_err = pcall(function()
    image_handle:render()
  end)
  if not rendered then
    cleanup_temp_file(path ~= display_path and path or nil)
    return false, tostring(render_err)
  end

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true

  return true
end

local function probe_video_duration(path)
  if vim.fn.executable("ffprobe") ~= 1 then
    return nil, "ffprobe is not installed"
  end

  local output = vim.fn.systemlist({
    "ffprobe",
    "-v",
    "error",
    "-select_streams",
    "v:0",
    "-show_entries",
    "format=duration",
    "-of",
    "default=nk=1:nw=1",
    path,
  })

  if vim.v.shell_error ~= 0 then
    return nil, table.concat(output, "\n")
  end

  return tonumber(output[1] or "")
end

local function extract_video_frame(path)
  if vim.fn.executable("ffmpeg") ~= 1 then
    return nil, "ffmpeg is not installed"
  end

  local duration, err = probe_video_duration(path)
  if err then
    return nil, err
  end

  local temp_png = vim.fn.tempname() .. ".png"
  local offset = 0
  if duration and duration > 0 then
    offset = math.max(0, math.floor(math.min(duration * 0.1, math.max(duration - 0.5, 0))))
  end

  local args = {
    "ffmpeg",
    "-v",
    "error",
    "-y",
  }

  if offset > 0 then
    vim.list_extend(args, { "-ss", tostring(offset) })
  end

  vim.list_extend(args, {
    "-i",
    path,
    "-frames:v",
    "1",
    "-vf",
    "scale='min(1600,iw)':-2:force_original_aspect_ratio=decrease",
    temp_png,
  })

  local output = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    local message = table.concat(output, "\n")
    cleanup_temp_file(temp_png)
    return nil, message
  end

  return temp_png
end

local function render_video_preview(bufnr, path)
  local frame, err = extract_video_frame(path)
  if not frame then
    return false, err
  end

  local ok, image_err = render_with_image_backend(bufnr, frame, path)
  if ok then
    return true
  end

  local rendered, chafa_err = render_with_chafa(bufnr, frame, path)
  cleanup_temp_file(frame)
  if rendered then
    return true
  end

  return false, image_err or chafa_err or "Video preview failed"
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

local function setup_video_preview()
  local group = vim.api.nvim_create_augroup("MeroVideoPreview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = video_patterns,
    callback = function(args)
      local ok, err = render_video_preview(args.buf, args.file)
      if not ok then
        prepare_preview_buffer(args.buf, args.file)
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, { err or "Video preview failed." })
        vim.bo[args.buf].modifiable = false
        vim.bo[args.buf].readonly = true
        vim.api.nvim_err_writeln(("MeroMedia: %s"):format(err or "Video preview failed"))
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
  else
    setup_chafa_fallback()
  end

  setup_video_preview()
end

return M
