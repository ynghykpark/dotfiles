local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 0.7
local transparent = string.format("rgba(0,0,0,%s)", opacity)
local custom_bg = "#504945"
local custom_fg = "#d4be95"
local left_edge = wezterm.nerdfonts.ple_left_half_circle_thick
local right_edge = wezterm.nerdfonts.ple_right_half_circle_thick
local selected_tab_emoji = "✨ "
local directory_emoji = "📂 "
local domain_emoji = "🌐 "

-- font settings
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" } -- disable ligatures
config.font = wezterm.font_with_fallback({
	{ family = "Iosevka Nerd Font" },
	{ family = "IBM Plex Sans KR" },
})
config.font_size = 13.5

-- helper function to get the tab title
local function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane in that tab
	return tab_info.active_pane.title
end

-- window settings
config.window_background_opacity = opacity -- set window opacity
config.window_decorations = "NONE" -- remove title bar
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.animation_fps = 10  -- Set the animation frame rate (adjust as needed)
config.max_fps = 10       -- Sets the maximum frame rate for rendering (adjust as needed)

-- tab bar settings
config.tab_max_width = 100
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
wezterm.on("format-tab-title", function(tab, _, _, _, _, _)
	local title = tab_title(tab)
	if tab.is_active then
		return {
			{ Background = { Color = transparent } },
			{ Foreground = { Color = custom_bg } },
			{ Text = left_edge },
			{ Background = { Color = custom_bg } },
			{ Foreground = { Color = custom_fg } },
			{ Text = selected_tab_emoji .. title },
			{ Background = { Color = transparent } },
			{ Foreground = { Color = custom_bg } },
			{ Text = right_edge },
		}
	else
		return {
			{ Background = { Color = transparent } },
			{ Foreground = { Color = "gray" } },
			{ Text = " " .. title .. " " },
		}
	end
end)

config.colors = {
	tab_bar = {
		background = transparent,
		new_tab = {
			bg_color = transparent,
			fg_color = "gray",
		},
	},
	foreground = "silver",
	background = "black",
	cursor_bg = "#52ad70",
	cursor_fg = "black",
	cursor_border = "#52ad70",
	selection_fg = "black",
	selection_bg = "#fffacd",
	scrollbar_thumb = "#222222",
	split = "#444444",
	ansi = {
		"#606060", -- black
		"#df9a98", -- red
		"#719672", -- green
		"#e0bb71", -- yellow
		"#96bbdc", -- blue
		"#dfbdbc", -- magenta
		"#97bcbc", -- cyan
		"#d8d8d8", -- white
	},
	brights = {
		"#757575", -- bright black
		"#e07798", -- bright red
		"#97bb98", -- bright green
		"#ffdd98", -- bright yellow
		"#badcfb", -- bright blue
		"#ffbebc", -- bright magenta
		"#96ddde", -- bright cyan
		"#ffffff", -- bright white
	},
}
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 1.0,
}

-- right status bar
wezterm.on("update-right-status", function(window, pane)
	local cwd_uri = pane:get_current_working_dir()
	local cwd = cwd_uri and cwd_uri.file_path:gsub(os.getenv("HOME"), "~"):gsub("/$", "") or "N/A"
	local domain = pane:get_domain_name()
	window:set_right_status(wezterm.format({
		-- current working directory
		{ Background = { Color = transparent } },
		{ Foreground = { Color = custom_bg } },
		{ Text = left_edge },
		{ Background = { Color = custom_bg } },
		{ Foreground = { Color = custom_fg } },
		{ Text = directory_emoji .. cwd },
		{ Background = { Color = transparent } },
		{ Foreground = { Color = custom_bg } },
		{ Text = right_edge },
		-- domain
		{ Text = " " },
		{ Background = { Color = transparent } },
		{ Foreground = { Color = custom_bg } },
		{ Text = left_edge },
		{ Background = { Color = custom_bg } },
		{ Foreground = { Color = custom_fg } },
		{ Text = domain_emoji .. domain },
		{ Background = { Color = transparent } },
		{ Foreground = { Color = custom_bg } },
		{ Text = right_edge },
	}))
end)

-- parse ssh config
local ssh_domains = {}
for host, _ in pairs(wezterm.enumerate_ssh_hosts()) do
	table.insert(ssh_domains, {
		name = host,
		remote_address = host,
		assume_shell = "Posix",
	})
end

wezterm.on("gui-startup", function()
	local mux = wezterm.mux

	-- tab 1: focus
	local tab, pane, window = mux.spawn_window({ workspace = "local", args = { "pomo" } })
	tab:window():gui_window():maximize()
	tab:set_title("focus")
	pane:split({ args = { "bash" }, direction = "Bottom", size = 0.7 })

	-- tab 2: file manager
	local tab2, _, _ = window:spawn_tab({ args = { "vifm" } })
	tab2:set_title("file manager")

	-- tab 3: system monitoring
	local tab3, _, _ = window:spawn_tab({ args = { "btop" } })
	tab3:set_title("system monitoring")

	-- tab 4 : text editor
	local tab4, _, _ = window:spawn_tab({ args = { "nvim" } })
	tab4:set_title("text editor")

	window:gui_window():perform_action(wezterm.action.ActivateTab(0), pane)
end)

-- keymaps
config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			local workspaces = {}
			table.insert(workspaces, { id = "local", label = "local" })
			for _, domain in ipairs(ssh_domains) do
				table.insert(workspaces, {
					id = "SSHMUX:" .. domain.name,
					label = domain.name,
				})
			end
			local act = wezterm.action
			window:perform_action(
				act.InputSelector({
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if not id and not label then
							wezterm.log_info("cancelled")
						else
							wezterm.log_info("id = " .. id)
							wezterm.log_info("label = " .. label)
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = label,
									spawn = { domain = { DomainName = id } },
								}),
								inner_pane
							)
						end
					end),
					title = "Workspace Switcher",
					choices = workspaces,
					fuzzy = false,
					fuzzy_description = "kuzzy find and/or make a workspace",
					description = "Choose a workspace",
				}),
				pane
			)
		end),
	},
	{
		key = "d",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			if ssh_domains then
				for _, domain in ipairs(ssh_domains) do
					window:perform_action(wezterm.action.DetachDomain({ DomainName = "SSHMUX:" .. domain.name }), pane)
				end
			else
				wezterm.log_error("No SSH domains found to detach.")
			end
		end),
	},
	{ key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "s", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = wezterm.action.ActivateTab(8) },
	{
		key = ",",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Rename Tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{ key = "[", mods = "LEADER", action = wezterm.action.MoveTabRelative(-1) }, -- Move tab left
	{ key = "]", mods = "LEADER", action = wezterm.action.MoveTabRelative(1) }, -- Move tab right
}

-- smart splits
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
smart_splits.apply_to_config(config, {
	direction_keys = {
		move = { "h", "j", "k", "l" },
		resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
	},
	modifiers = {
		move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
		resize = "CTRL", -- modifier to use for pane resize, e.g. META+h to resize to the left
	},
})

return config
