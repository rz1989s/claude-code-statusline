-- Claude Code Statusline - Neovim Plugin
-- Display Claude Code metrics in Neovim

local M = {}

-- Default configuration
M.config = {
  statusline_path = vim.fn.expand('~/.claude/statusline/statusline.sh'),
  refresh_interval = 5000, -- ms
  show_cost = true,
  show_mcp = true,
  show_repo = true,
}

-- Cached data
local cached_data = nil
local last_fetch = 0

-- Parse JSON output from statusline
local function parse_json(output)
  local ok, data = pcall(vim.json.decode, output)
  if ok then
    return data
  end
  return nil
end

-- Fetch statusline data
local function fetch_data()
  local now = vim.loop.now()
  if cached_data and (now - last_fetch) < M.config.refresh_interval then
    return cached_data
  end

  local handle = io.popen(M.config.statusline_path .. ' --json 2>/dev/null')
  if not handle then
    return nil
  end

  local output = handle:read('*a')
  handle:close()

  local data = parse_json(output)
  if data then
    cached_data = data
    last_fetch = now
  end

  return data
end

-- Get formatted status string
function M.status()
  local data = fetch_data()
  if not data then
    return ''
  end

  local parts = {}

  -- Repository info
  if M.config.show_repo then
    local icon = data.repository.status == 'clean' and '' or ''
    table.insert(parts, icon .. ' ' .. data.repository.name)
  end

  -- Cost
  if M.config.show_cost then
    table.insert(parts, string.format('$%.2f', data.cost.session))
  end

  -- MCP
  if M.config.show_mcp and data.mcp.total > 0 then
    table.insert(parts, string.format(' %d/%d', data.mcp.connected, data.mcp.total))
  end

  return table.concat(parts, ' │ ')
end

-- Get full data for detailed view
function M.get_data()
  return fetch_data()
end

-- Lualine component
function M.lualine_component()
  return {
    function()
      return M.status()
    end,
    icon = '',
    cond = function()
      return vim.fn.filereadable(M.config.statusline_path) == 1
    end,
  }
end

-- Show floating window with details
function M.show_details()
  local data = fetch_data()
  if not data then
    vim.notify('No Claude Code data available', vim.log.levels.WARN)
    return
  end

  local lines = {
    '╭─────────────────────────────────────╮',
    '│     Claude Code Statusline          │',
    '│           v' .. data.version .. string.rep(' ', 23 - #data.version) .. '│',
    '├─────────────────────────────────────┤',
    '│ Repository                          │',
    '│   Name:    ' .. data.repository.name .. string.rep(' ', 25 - #data.repository.name) .. '│',
    '│   Branch:  ' .. data.repository.branch .. string.rep(' ', 25 - #data.repository.branch) .. '│',
    '│   Status:  ' .. data.repository.status .. string.rep(' ', 25 - #data.repository.status) .. '│',
    '│   Commits: ' .. tostring(data.repository.commits_today) .. string.rep(' ', 25 - #tostring(data.repository.commits_today)) .. '│',
    '├─────────────────────────────────────┤',
    '│ Cost                                │',
    string.format('│   Session: $%-22.2f│', data.cost.session),
    string.format('│   Daily:   $%-22.2f│', data.cost.daily),
    string.format('│   Weekly:  $%-22.2f│', data.cost.weekly),
    string.format('│   Monthly: $%-22.2f│', data.cost.monthly),
    '├─────────────────────────────────────┤',
    '│ MCP Servers                         │',
    string.format('│   Connected: %-23s│', data.mcp.connected .. '/' .. data.mcp.total),
    '╰─────────────────────────────────────╯',
  }

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 39
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'none',
  })

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- Close on any key
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Create user commands
  vim.api.nvim_create_user_command('ClaudeStatusline', function()
    M.show_details()
  end, { desc = 'Show Claude Code statusline details' })

  vim.api.nvim_create_user_command('ClaudeStatuslineRefresh', function()
    cached_data = nil
    last_fetch = 0
    vim.notify('Claude statusline cache cleared', vim.log.levels.INFO)
  end, { desc = 'Refresh Claude Code statusline data' })
end

return M
