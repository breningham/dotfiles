local config = {}

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.window_frame = {
	font_size = 12,
	inactive_titlebar_bg = "#363a4f",
	active_titlebar_bg = "#181926",
	active_titlebar_border_bottom = "#181926",
	button_fg = "#cad3f5",
	button_bg = "#181926",
	button_hover_bg = "#363a4f",
	button_hover_fg = "#cad3f5",
}

config.colors = {
	tab_bar = {
		active_tab = {
			bg_color = "#24273a",
			fg_color = "#cad3f5",
		},
		inactive_tab = {
			bg_color = "#363a4f",
			fg_color = "#cad3f5",
		},
		inactive_tab_hover = {
			bg_color = "#1e2030",
			fg_color = "#cad3f5",
		},
		new_tab = {
			bg_color = "#24273a",
			fg_color = "#cad3f5",
		},
		new_tab_hover = {
			bg_color = "#5b6078",
			fg_color = "#cad3f5",
		},
	},
}

return config
