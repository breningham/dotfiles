local wezterm = require("wezterm")

local act = wezterm.action

return {
	{
		key = "C",
		mods = "CTRL",
		action = act.CopyTo("ClipboardAndPrimarySelection"),
	},
	{
		key = "V",
		mods = "CTRL",
		action = act.PasteFrom("Clipboard"),
	},
	{
		key = "V",
		mods = "CTRL",
		action = act.PasteFrom("PrimarySelection"),
	},
	{
		key = "P",
		mods = "CTRL",
		action = act.ActivateCommandPalette,
	},
	{
		key = "%",
		mods = "CTRL|SHIFT|ALT",
		action = act.SplitPane({
			direction = "Down",
			size = { Percent = 25 },
		}),
	},
}
