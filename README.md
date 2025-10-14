# tmuxstatus.nvim

Display Neovim information in your tmux status line. Show buffers, files, modes, and custom data with a simple widget-based system.

---
## Installation

**lazy.nvim:**
```lua
{ 'holesachin/tmuxstatus.nvim', opts = {} }
```

**packer.nvim:**
```lua
use { 'holesachin/tmuxstatus.nvim' }
```

---
## Quick Start

**Neovim config:**
```lua
require('tmuxstatus').setup({
  widgets = {
    { name = 'mode' },
    { name = 'current_file' },
    { name = 'buffers' },
  }
})
```

**tmux.conf:**
```bash
set -g status-right "#{@nvim_mode} | #{@nvim_file} | #{@nvim_buffers}"
```

---
## Built-in Widgets

| Widget         | Variable        | Description                        |
| -------------- | --------------- | ---------------------------------- |
| `mode`         | `@nvim_mode`    | Current mode (NORMAL, INSERT, etc) |
| `current_file` | `@nvim_file`    | Active file name                   |
| `buffers`      | `@nvim_buffers` | List of open buffers               |

**Widget options:**
```lua
{
  name = 'current_file',
  modifier = ':p',  -- :t (filename), :p (full path), :~ (relative to home)
},
{
  name = 'buffers',
  separator = ' · ',
  max_length = 60,
  highlight_current = true,
  highlight_format = '#[fg=yellow]%s#[default]',
  filter = function(name) return name ~= "" end,
}
```

---
## Custom Widgets

**Method 1: Inline function**
```lua
{
  name = 'git_branch',
  tmux_var = 'nvim_git',
  fn = function()
    return vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  end,
  format = " %s",
  events = { "BufEnter" },
  condition = function() return true end,
}
```

**Method 2: Register programmatically**
```lua
local tmuxstatus = require('tmuxstatus')

tmuxstatus.register('line_count', {
  tmux_var = 'nvim_lines',
  fn = function()
    return tostring(vim.api.nvim_buf_line_count(0))
  end,
  format = "Lines: %s",
})
```

---
## Widget Options

- `name` - Widget identifier (required)
- `tmux_var` - tmux variable name (defaults to name)
- `fn` - Function returning the widget value
- `format` - Format string for the value
- `events` - Neovim events triggering updates
- `condition` - Function to show/hide widget

---
## Configuration

**Method 1: All widgets in setup**
```lua
require('tmuxstatus').setup({
  -- Events that trigger widget updates
  update_events = { "BufEnter", "BufLeave", "WinEnter", "ModeChanged" },
  
  -- Debounce delay in milliseconds
  update_interval = 100,
  
  -- Widget definitions
  widgets = {
    { name = 'mode' },
    { name = 'current_file', modifier = ':t' },
    { 
      name = 'buffers',
      separator = ' | ',
      max_length = 80,
      highlight_current = true,
      highlight_format = '#[fg=red,bold]%s#[default]',
      filter = function(name) return name ~= "" end,
    },
    -- Custom widget example
    {
      name = 'git_branch',
      tmux_var = 'nvim_git',
      fn = function()
        return vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
      end,
      format = " %s",
      events = { "BufEnter", "FocusGained" },
      condition = function() return vim.fn.isdirectory('.git') == 1 end,
    },
  }
})
```

**Method 2: Register widgets separately**
```lua
local tmuxstatus = require('tmuxstatus')

tmuxstatus.setup({
  widgets = {
    { name = 'mode' },
    { name = 'current_file' },
  }
})

-- Register additional widgets after setup
tmuxstatus.register('git_branch', {
  tmux_var = 'nvim_git',
  fn = function()
    return vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  end,
  format = " %s",
})
```

---
## License

MIT

---
