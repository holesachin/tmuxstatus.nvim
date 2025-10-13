local M = {}

-- Buffer list widget
M.buffers = {
	tmux_var = "nvim_buffers",
	separator = " | ",
	max_length = 80,
	highlight_current = true,
	highlight_format = "#[fg=red,bold]%s#[default]",
	filter = function(name) return name ~= "" end,
	fn = function(self)
		local current_buf = vim.api.nvim_get_current_buf()
		local buffers = {}

		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
				local name = vim.api.nvim_buf_get_name(buf)
				local short = vim.fn.fnamemodify(name, ":t")
				if self.filter(short) then
					if self.highlight_current and buf == current_buf then
						table.insert(buffers, string.format(self.highlight_format, short))
					else
						table.insert(buffers, short)
					end
				end
			end
		end

		local result = table.concat(buffers, self.separator)
		if #result > self.max_length then
			result = result:sub(1, self.max_length - 3) .. "..."
		end
		return result
	end
}

-- Current file widget
M.current_file = { 
	tmux_var = "nvim_file",
	modifier = ":t",
	fn = function(self)
		local name = vim.fn.expand("%")
		if name == "" then return "" end
		return vim.fn.fnamemodify(name, self.modifier)
	end
}

-- Mode widget
M.mode = { 
	tmux_var = "nvim_mode",
	fn = function()
		local mode_map = {
			n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE",
			["\22"] = "V-BLOCK", c = "COMMAND", s = "SELECT", S = "S-LINE",
			["\19"] = "S-BLOCK", R = "REPLACE", t = "TERMINAL"
		}
		return mode_map[vim.fn.mode()] or vim.fn.mode()
	end
}

return M
