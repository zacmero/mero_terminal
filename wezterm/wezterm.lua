local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = { os.getenv("SHELL") or "/bin/bash", "-l" }

config.font = wezterm.font_with_fallback({
  "CaskaydiaCove Nerd Font Mono",
  "Noto Color Emoji",
})
config.font_size = 17.0
config.line_height = 1.0
config.cell_width = 1.0
config.initial_cols = 140
config.initial_rows = 40

config.window_decorations = "RESIZE"
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.96
config.adjust_window_size_when_changing_font_size = false

config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_max_width = 32

config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "NONE",
    action = act.ScrollByLine(-2),
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "NONE",
    action = act.ScrollByLine(2),
  },
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "CTRL",
    action = act.ScrollByLine(-10),
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "CTRL",
    action = act.ScrollByLine(10),
  },
}

local function foreground_is_nvim(pane)
  local process = pane:get_foreground_process_name() or ""
  process = process:gsub("\\", "/")
  return process:match("(^|/)n?vim$") ~= nil
end

local function send_if_nvim(sequence, fallback)
  return wezterm.action_callback(function(window, pane)
    if foreground_is_nvim(pane) then
      window:perform_action(act.SendString(sequence), pane)
    elseif fallback then
      window:perform_action(fallback, pane)
    end
  end)
end

config.keys = {
  {
    key = "/",
    mods = "CTRL|SHIFT",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "?",
    mods = "CTRL|SHIFT",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "-",
    mods = "CTRL|SHIFT",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "_",
    mods = "CTRL|SHIFT",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "s",
    mods = "CTRL|SHIFT",
    action = send_if_nvim("\x1b[9002u", act.SendKey({ key = "s", mods = "CTRL|SHIFT" })),
  },
}

config.colors = {
  foreground = "#e8e8e8",
  background = "#161a1f",
  cursor_bg = "#7cb8ff",
  cursor_fg = "#0f1317",
cursor_border = "#7cb8ff",
  selection_fg = "#0f1317",
  selection_bg = "#4a86d9",
ansi = {
    "#214969",
    "#E52E2E",
    "#44FFB1",
    "#FFE073",
    "#0fb7dd",
    "#a277ff",
    "#b824f7",
    "#d21fdf",
  },
  brights = {
    "#214969",
    "#E52E2E",
    "#44FFB1",
    "#FFE073",
    "#A277FF",
    "#a277ff",
    "#24EAF7",
    "#24EAF7",
  },
}

return config
