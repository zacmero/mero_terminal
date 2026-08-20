local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
local scroll_bar_width = 5
local forced_front_end = os.getenv("MERO_WEZTERM_FRONTEND")

local function to_roman(value)
	local numerals = {
		{ 1000, "M" },
		{ 900, "CM" },
		{ 500, "D" },
		{ 400, "CD" },
		{ 100, "C" },
		{ 90, "XC" },
		{ 50, "L" },
		{ 40, "XL" },
		{ 10, "X" },
		{ 9, "IX" },
		{ 5, "V" },
		{ 4, "IV" },
		{ 1, "I" },
	}
	local result = {}

	for _, numeral in ipairs(numerals) do
		while value >= numeral[1] do
			result[#result + 1] = numeral[2]
			value = value - numeral[1]
		end
	end

	return table.concat(result)
end

wezterm.on("update-right-status", function(window, _pane)
	local mux_window = window:mux_window()
	if not mux_window then
		return
	end

	local tabs = mux_window:tabs_with_info()
	local active_table = window:active_key_table()
	local show_close_hint = active_table == "confirm_close_tab"

	if #tabs <= 1 and not show_close_hint then
		window:set_right_status("")
		return
	end

	local cells = {}

	if show_close_hint then
		cells[#cells + 1] = {
			Foreground = {
				Color = "#7cb8ff",
			},
		}
		cells[#cells + 1] = {
			Attribute = {
				Intensity = "Bold",
			},
		}
		cells[#cells + 1] = { Text = "close? ↵" }
	end

	for index, tab in ipairs(tabs) do
		if #cells > 0 or index > 1 then
			cells[#cells + 1] = { Text = " " }
		end

		cells[#cells + 1] = {
			Foreground = {
				Color = tab.is_active and "#24EAF7" or "#315c78",
			},
		}
		cells[#cells + 1] = {
			Attribute = {
				Intensity = tab.is_active and "Bold" or "Normal",
			},
		}
		cells[#cells + 1] = { Text = to_roman(index) }
	end

	cells[#cells + 1] = { Text = " " }
	window:set_right_status(wezterm.format(cells))
end)

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = { os.getenv("SHELL") or "/bin/bash", "-l" }

if forced_front_end and forced_front_end ~= "" then
	config.front_end = forced_front_end
elseif os.getenv("WAYLAND_DISPLAY") and os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
	config.front_end = "OpenGL"
end

config.font = wezterm.font_with_fallback({
	"CaskaydiaCove Nerd Font Mono",
	"Noto Color Emoji",
})
config.font_size = 17.0
config.line_height = 1.0
config.cell_width = 1.0
config.initial_cols = 140
config.initial_rows = 40

if os.getenv("WAYLAND_DISPLAY") and os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
	config.window_decorations = "NONE"
else
	config.window_decorations = "RESIZE"
end
config.window_padding = {
	left = 12,
	right = scroll_bar_width,
	top = 10,
	bottom = 10,
}
config.window_background_opacity = 0.96
config.adjust_window_size_when_changing_font_size = false

-- Superfile and Neovim image previews use the Kitty graphics protocol.
config.enable_kitty_graphics = true

config.window_frame = {
	active_titlebar_bg = "#161a1f",
	inactive_titlebar_bg = "#161a1f",
	font = wezterm.font_with_fallback({
		"CaskaydiaCove Nerd Font Mono",
		"Noto Color Emoji",
	}),
	font_size = 9.0,
}

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"

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
	-- Right-click = paste (like Ctrl+Shift+V)
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.Nop,
	},
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
	-- Ctrl+Right-click = context menu
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "CTRL",
		action = act.Nop,
	},
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "CTRL",
		action = wezterm.action.ShowLauncherArgs({ title = "Context", flags = "FUZZY" }),
	},
	-- Ctrl+Shift+Right-click = launcher
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "CTRL|SHIFT",
		action = act.Nop,
	},
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "CTRL|SHIFT",
		action = act.ShowLauncher,
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
	{ key = "-", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "0", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "1", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "2", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "3", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "4", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "5", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "6", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "7", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "8", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "9", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "=", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "c", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "f", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "k", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "m", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "n", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "r", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "t", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "v", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "w", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "[", mods = "SHIFT|SUPER", action = act.DisableDefaultAssignment },
	{ key = "]", mods = "SHIFT|SUPER", action = act.DisableDefaultAssignment },
	{ key = "{", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "}", mods = "SUPER", action = act.DisableDefaultAssignment },
	{ key = "w", mods = "ALT", action = act.DisableDefaultAssignment },
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
		key = "F8",
		mods = "NONE",
		action = act.SendString(string.char(0x1f) .. "\r"),
	},
	{
		key = "s",
		mods = "CTRL|SHIFT",
		action = send_if_nvim("\x1b[9002u", act.SendKey({ key = "s", mods = "CTRL|SHIFT" })),
	},
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = act.CopyTo("ClipboardAndPrimarySelection"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = act.PasteFrom("Clipboard"),
	},
}

config.key_tables = {
	confirm_close_tab = {
		{
			key = "Enter",
			action = act.CloseCurrentTab({ confirm = false }),
		},
		{
			key = "Escape",
			action = act.PopKeyTable,
		},
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
	tab_bar = {
		background = "rgba(0, 0, 0, 0)",
		inactive_tab_edge = "rgba(0, 0, 0, 0)",
	},
	scrollbar_thumb = "rgba(36, 234, 247, 0.12)",
}

return config
