-- tmuxstatus.nvim - Display Neovim data in tmux status line

local M = {}
local timer = nil

-- Widget registry
M.widgets = {}

-- Default configuration
M.config = {
	hide_vim_statusbar = false,
	update_events = { "BufEnter", "BufLeave", "WinEnter", "ModeChanged" },
	update_interval = 100, -- ms debounce
}

-- Check if running inside tmux
local function in_tmux()
	return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

-- Set a tmux global variable
local function set_tmux_var(name, value)
	if not in_tmux() then return end
	-- Escape single quotes in the value
	local escaped_value = value:gsub("'", "'\"'\"'")
	vim.fn.system(string.format("tmux set-option -g @%s '%s'", name, escaped_value))
end

-- Register a widget with validation
function M.register(name, opts)
	opts = opts or {}
	
	-- Validate widget name
	if not name or type(name) ~= "string" or name == "" then
		error("tmuxstatus: Widget name must be a non-empty string")
	end

	-- Validate tmux variable name
	local tmux_var = opts.tmux_var or name
	if not tmux_var:match("^[a-zA-Z0-9_]+$") then
		error("tmuxstatus: tmux_var must contain only letters, numbers, and underscores")
	end

	-- Store widget configuration
	M.widgets[name] = vim.tbl_deep_extend("force", {
		fn = function() return "" end,
		format = "%s",
		tmux_var = tmux_var,
		events = M.config.update_events,
		condition = function() return true end,
	}, opts)
end

-- Update a specific widget's value in tmux
function M.update_widget(name)
	if not in_tmux() then return end

	local widget = M.widgets[name]
	if not widget then return end

	-- Check if widget condition is met
	if not widget.condition() then
		set_tmux_var(widget.tmux_var, "")
		return
	end

	-- Safely get widget value with error handling
	local success, value = pcall(widget.fn, widget)
	if not success then
		vim.notify("tmuxstatus: Error in widget '" .. name .. "': " .. value, vim.log.levels.ERROR)
		set_tmux_var(widget.tmux_var, "")
		return
	end

	-- Format the value
	if value and value ~= "" then
		value = string.format(widget.format, value)
	end
	
	set_tmux_var(widget.tmux_var, value or "")
end

-- Update all registered widgets (with debouncing)
function M.update_all()
	if timer then timer:stop() end
	
	timer = vim.defer_fn(function()
		for name in pairs(M.widgets) do
			M.update_widget(name)
		end
	end, M.config.update_interval)
end

-- Setup function - main entry point
function M.setup(opts)
	opts = opts or {}
	
	-- Merge user config with defaults
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	if not in_tmux() then 
		vim.notify("tmuxstatus: Not running in tmux, plugin disabled", vim.log.levels.WARN)
		return 
	end

	-- Hide Neovim Statusbar
	if M.config.hide_vim_statusbar then 
		vim.opt.laststatus = 0
	end

	-- Load predefined widgets
	local w = require('tmuxstatus.widgets')

	-- Register widgets from configuration
	if opts.widgets then
		for _, widget in ipairs(opts.widgets) do
			local widget_def = widget

			-- If no custom fn provided, use predefined widget
			if not widget.fn and w[widget.name] then
				widget_def = vim.tbl_deep_extend("force", {}, w[widget.name], widget)
			end

			M.register(widget_def.name, widget_def)
		end
	end

	-- Collect all unique events from widgets
	local event_set = {}
	for _, widget in pairs(M.widgets) do
		for _, event in ipairs(widget.events) do
			event_set[event] = true
		end
	end

	-- Convert event set to list
	local event_list = {}
	for event in pairs(event_set) do
		table.insert(event_list, event)
	end

	-- Setup autocmds to trigger updates
	if #event_list > 0 then
		vim.api.nvim_create_autocmd(event_list, {
			group = vim.api.nvim_create_augroup("TmuxStatus", { clear = true }),
			callback = M.update_all
		})
	end

	-- Trigger initial update
	M.update_all()

	-- Clear all widget variables
	local clear_all = function()
		for name in pairs(M.widgets) do
			local widget = M.widgets[name]
			set_tmux_var(widget.tmux_var, "")
		end
	end

	-- Clear all widget variables when Neovim exits
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("TmuxStatusCleanup", { clear = true }),
		callback = clear_all
	})

	-- Clear all widget variables when Neovim FocusLost
	vim.api.nvim_create_autocmd("FocusLost", {
		group = vim.api.nvim_create_augroup("TmuxStatusCleanup", { clear = true }),
		callback = clear_all
	})

	-- Trigger update on FocusGained
	vim.api.nvim_create_autocmd("FocusGained", {
		group = vim.api.nvim_create_augroup("TmuxStatus", { clear = true }),
		callback = M.update_all
	})

end

return M
