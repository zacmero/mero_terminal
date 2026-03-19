local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = { os.getenv("SHELL") or "/bin/bash", "-l" }

config.font = wezterm.font_with_fallback({
  "CaskaydiaCove Nerd Font Mono",
  "CaskaydiaCove Nerd Font",
  "JetBrainsMono Nerd Font",
  "Noto Color Emoji",
})
config.font_size = 12.5
config.line_height = 1.05

config.window_decorations = "RESIZE"
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.96
config.adjust_window_size_when_changing_font_size = false

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32

config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.keys = {
  {
    key = "/",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "?",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "-",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "_",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
}

config.colors = {
  foreground = "#f8f8f2",
  background = "#10131a",
  cursor_bg = "#8be9fd",
  cursor_fg = "#10131a",
  cursor_border = "#8be9fd",
  selection_fg = "#10131a",
  selection_bg = "#50fa7b",
  ansi = {
    "#1b1f2a",
    "#ff5c8a",
    "#58f6a4",
    "#ffd866",
    "#76c7ff",
    "#ff79c6",
    "#8be9fd",
    "#e6edf3",
  },
  brights = {
    "#4b5263",
    "#ff7aa2",
    "#7dfcc4",
    "#ffe38a",
    "#93d7ff",
    "#ff92d0",
    "#a8f0ff",
    "#ffffff",
  },
  tab_bar = {
    background = "#0a0d14",
    active_tab = {
      bg_color = "#1c2333",
      fg_color = "#8be9fd",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#10131a",
      fg_color = "#8a93a5",
    },
    inactive_tab_hover = {
      bg_color = "#151b26",
      fg_color = "#f8f8f2",
    },
    new_tab = {
      bg_color = "#10131a",
      fg_color = "#8a93a5",
    },
    new_tab_hover = {
      bg_color = "#151b26",
      fg_color = "#f8f8f2",
    },
  },
}

return config
