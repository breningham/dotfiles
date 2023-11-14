local wezterm = require("wezterm")
local keys = require("keys")
local appearance = require("appearance")

local config = {
	color_scheme = "Catppuccin Macchiato",
	font = wezterm.font("Maple Mono NF"),
	default_prog = { "/usr/bin/fish" },
	window_background_opacity = 1,
	text_background_opacity = 1,
	use_fancy_tab_bar = true,
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	integrated_title_buttons = { "Close", "Hide", "Maximize" },
	integrated_title_button_style = "Gnome",
	integrated_title_button_alignment = "Left",
	front_end = "WebGpu",
	enable_scroll_bar = true,
	enable_wayland = true,
	window_padding = appearance.window_padding,
	window_frame = appearance.window_frame,
	colors = appearance.colors,
	keys = keys,
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- if in nvim then hide the scrollbar
wezterm.on("update-status", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if pane:is_alt_screen_active() then
		overrides.enable_scroll_bar = false
	else
		overrides.enable_scroll_bar = true
	end
	window:set_config_overrides(overrides)
end)

return config
