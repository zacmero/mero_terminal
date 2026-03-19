local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = { os.getenv("SHELL") or "/bin/bash", "-l" }

config.font = wezterm.font_with_fallback({
  "CaskaydiaCove Nerd Font Mono",
  "Noto Color Emoji",
})
config.font_size = 19.0
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
config.window_background_opacity = 0.90
config.adjust_window_size_when_changing_font_size = false

config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_max_width = 32

config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.keys = {
  {
    key = "/",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "?",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "-",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "_",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
}

config.colors = {
  foreground = "#CBE0F0",
  background = "#0f1317",
  cursor_bg = "#d747ff",
  cursor_fg = "#011423",
cursor_border = "#9a5aaa",
  selection_fg = "#CBE0F0",
  selection_bg = "#033259",
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
