-- Claude Code Statusline - Neovim Plugin
-- Display Claude Code metrics in Neovim
-- Issue #117

---@diagnostic disable: undefined-global
-- The `vim` global is provided by Neovim at runtime

local M = {}

-- Default configuration
M.config = {
  statusline_path = vim.fn.expand('~/.claude/statusline/statusline.sh'),
  refresh_interval = 5000, -- ms
  show_cost = true,
  show_mcp = true,
  show_repo = true,
  show_icon = true,
  icons = {
    claude = '',
    clean = '',
    dirty = '',
    mcp = '',
    cost = '',
  },
}

-- Cached data
local cached_data = nil
local last_fetch = 0
local fetch_in_progress = false

-- Highlight groups
local highlights = {
  ClaudeTitle = { fg = '#89b4fa', bold = true },
  ClaudeBorder = { fg = '#6c7086' },
  ClaudeLabel = { fg = '#a6adc8' },
  ClaudeValue = { fg = '#cdd6f4' },
  ClaudeCost = { fg = '#a6e3a1' },
  ClaudeMcp = { fg = '#f9e2af' },
  ClaudeClean = { fg = '#a6e3a1' },
  ClaudeDirty = { fg = '#f38ba8' },
}

-- Setup highlight groups
local function setup_highlights()
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- Parse JSON output from statusline
local function parse_json(output)
  if not output or output == '' then
    return nil
  end
  local ok, data = pcall(vim.json.decode, output)
  if ok and type(data) == 'table' then
    return data
  end
  return nil
end

-- Async fetch using vim.loop
local function fetch_data_async(callback)
  if fetch_in_progress then
    if callback then callback(cached_data) end
    return
  end

  local path = M.config.statusline_path
  if vim.fn.filereadable(path) ~= 1 then
    if callback then callback(nil) end
    return
  end

  fetch_in_progress = true
  local stdout = vim.loop.new_pipe(false)
  local output = ''

  local handle
  handle = vim.loop.spawn(path, {
    args = { '--json' },
    stdio = { nil, stdout, nil },
  }, function(code)
    stdout:close()
    handle:close()
    fetch_in_progress = false

    vim.schedule(function()
      if code == 0 then
        local data = parse_json(output)
        if data then
          cached_data = data
          last_fetch = vim.loop.now()
        end
      end
      if callback then callback(cached_data) end
    end)
  end)

  if handle then
    stdout:read_start(function(err, chunk)
      if chunk then
        output = output .. chunk
      end
    end)
  else
    fetch_in_progress = false
    if callback then callback(nil) end
  end
end

-- Synchronous fetch (for statusline)
local function fetch_data_sync()
  local now = vim.loop.now()
  if cached_data and (now - last_fetch) < M.config.refresh_interval then
    return cached_data
  end

  local path = M.config.statusline_path
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local handle = io.popen(path .. ' --json 2>/dev/null')
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

  return cached_data
end

-- Get formatted status string (for statusline)
function M.status()
  local data = fetch_data_sync()
  if not data then
    return ''
  end

  local parts = {}

  -- Icon
  if M.config.show_icon then
    table.insert(parts, M.config.icons.claude)
  end

  -- Repository info
  if M.config.show_repo and data.repository then
    local icon = data.repository.status == 'clean'
      and M.config.icons.clean
      or M.config.icons.dirty
    table.insert(parts, icon .. ' ' .. (data.repository.name or 'unknown'))
  end

  -- Cost
  if M.config.show_cost and data.cost then
    local cost = data.cost.session or 0
    if cost > 0 then
      table.insert(parts, M.config.icons.cost .. string.format('$%.2f', cost))
    end
  end

  -- MCP
  if M.config.show_mcp and data.mcp and data.mcp.total > 0 then
    table.insert(parts, string.format('%s %d/%d',
      M.config.icons.mcp,
      data.mcp.connected or 0,
      data.mcp.total or 0))
  end

  return table.concat(parts, ' │ ')
end

-- Get full data for detailed view
function M.get_data()
  return fetch_data_sync()
end

-- Lualine component
function M.lualine_component()
  return {
    function()
      return M.status()
    end,
    icon = nil, -- Icon is included in status()
    cond = function()
      return vim.fn.filereadable(M.config.statusline_path) == 1
    end,
    color = { fg = '#89b4fa' },
  }
end

-- Helper to safely get nested value
local function safe_get(tbl, ...)
  local val = tbl
  for _, key in ipairs({...}) do
    if type(val) ~= 'table' then return nil end
    val = val[key]
  end
  return val
end

-- Helper to pad string
local function pad(str, width, align)
  str = tostring(str or '')
  local padding = width - #str
  if padding <= 0 then return str:sub(1, width) end
  if align == 'right' then
    return string.rep(' ', padding) .. str
  end
  return str .. string.rep(' ', padding)
end

-- Show floating window with details
function M.show_details()
  fetch_data_async(function(data)
    if not data then
      vim.notify('No Claude Code data available', vim.log.levels.WARN)
      return
    end

    local width = 45
    local inner = width - 4  -- Account for borders and padding

    -- Build content lines with highlight info
    local content = {}
    local hl_ranges = {}  -- {line, col_start, col_end, hl_group}

    local function add_line(text, hl)
      table.insert(content, text)
      if hl then
        table.insert(hl_ranges, {#content, 0, #text, hl})
      end
    end

    local function add_kv(label, value, value_hl)
      local line = '  ' .. pad(label .. ':', 12) .. ' ' .. tostring(value or 'N/A')
      table.insert(content, line)
      if value_hl then
        local start = 15  -- After label
        table.insert(hl_ranges, {#content, start, #line, value_hl})
      end
    end

    -- Header
    add_line('', nil)
    add_line('  ' .. M.config.icons.claude .. ' Claude Code Statusline', 'ClaudeTitle')
    add_line('  Version: ' .. (safe_get(data, 'version') or 'unknown'), 'ClaudeLabel')
    add_line('', nil)
    add_line('  ─────────────────────────────────────', 'ClaudeBorder')

    -- Repository section
    add_line('', nil)
    add_line('  Repository', 'ClaudeTitle')
    add_kv('Name', safe_get(data, 'repository', 'name'), 'ClaudeValue')
    add_kv('Branch', safe_get(data, 'repository', 'branch'), 'ClaudeValue')

    local status = safe_get(data, 'repository', 'status') or 'unknown'
    local status_hl = status == 'clean' and 'ClaudeClean' or 'ClaudeDirty'
    add_kv('Status', status, status_hl)
    add_kv('Commits', safe_get(data, 'repository', 'commits_today'), 'ClaudeValue')

    -- Cost section
    add_line('', nil)
    add_line('  ─────────────────────────────────────', 'ClaudeBorder')
    add_line('', nil)
    add_line('  ' .. M.config.icons.cost .. ' Cost', 'ClaudeTitle')
    add_kv('Session', string.format('$%.2f', safe_get(data, 'cost', 'session') or 0), 'ClaudeCost')
    add_kv('Daily', string.format('$%.2f', safe_get(data, 'cost', 'daily') or 0), 'ClaudeCost')
    add_kv('Weekly', string.format('$%.2f', safe_get(data, 'cost', 'weekly') or 0), 'ClaudeCost')
    add_kv('Monthly', string.format('$%.2f', safe_get(data, 'cost', 'monthly') or 0), 'ClaudeCost')

    -- MCP section
    if data.mcp and data.mcp.total > 0 then
      add_line('', nil)
      add_line('  ─────────────────────────────────────', 'ClaudeBorder')
      add_line('', nil)
      add_line('  ' .. M.config.icons.mcp .. ' MCP Servers', 'ClaudeTitle')
      add_kv('Status', string.format('%d/%d connected',
        data.mcp.connected or 0, data.mcp.total or 0), 'ClaudeMcp')

      if data.mcp.servers then
        for _, server in ipairs(data.mcp.servers) do
          add_line('    • ' .. server, 'ClaudeValue')
        end
      end
    end

    -- GitHub section
    if data.github and data.github.enabled then
      add_line('', nil)
      add_line('  ─────────────────────────────────────', 'ClaudeBorder')
      add_line('', nil)
      add_line('   GitHub', 'ClaudeTitle')
      add_kv('CI Status', data.github.ci_status or 'N/A', 'ClaudeValue')
      add_kv('Open PRs', data.github.open_prs or 0, 'ClaudeValue')
    end

    add_line('', nil)
    add_line('  Press q or <Esc> to close', 'ClaudeLabel')
    add_line('', nil)

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    -- Apply highlights
    for _, hl in ipairs(hl_ranges) do
      vim.api.nvim_buf_add_highlight(buf, -1, hl[4], hl[1] - 1, hl[2], hl[3])
    end

    -- Calculate window size and position
    local height = #content
    local win_width = width
    local win_height = math.min(height, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - win_height) / 2)
    local col = math.floor((vim.o.columns - win_width) / 2)

    -- Create floating window
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = win_width,
      height = win_height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' Claude Code ',
      title_pos = 'center',
    })

    -- Set window options
    vim.api.nvim_win_set_option(win, 'winblend', 10)
    vim.api.nvim_win_set_option(win, 'cursorline', false)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'claude-statusline')

    -- Close keymaps
    local close = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end

    vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true })
    vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
    vim.keymap.set('n', '<CR>', close, { buffer = buf, nowait = true })
  end)
end

-- Refresh data manually
function M.refresh()
  cached_data = nil
  last_fetch = 0
  fetch_data_async(function(data)
    if data then
      vim.notify('Claude statusline refreshed', vim.log.levels.INFO)
    else
      vim.notify('Failed to refresh Claude statusline', vim.log.levels.WARN)
    end
  end)
end

-- Start background auto-refresh
local refresh_timer = nil

local function start_auto_refresh()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
  end

  refresh_timer = vim.loop.new_timer()
  refresh_timer:start(0, M.config.refresh_interval, vim.schedule_wrap(function()
    fetch_data_async()
  end))
end

local function stop_auto_refresh()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

-- Telescope integration
function M.telescope_picker()
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    vim.notify('Telescope not installed', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local data = fetch_data_sync()
  if not data then
    vim.notify('No Claude Code data available', vim.log.levels.WARN)
    return
  end

  local entries = {
    { 'Repository', data.repository and data.repository.name or 'N/A' },
    { 'Branch', data.repository and data.repository.branch or 'N/A' },
    { 'Status', data.repository and data.repository.status or 'N/A' },
    { 'Commits Today', data.repository and data.repository.commits_today or 0 },
    { '──────────', '──────────' },
    { 'Session Cost', string.format('$%.2f', data.cost and data.cost.session or 0) },
    { 'Daily Cost', string.format('$%.2f', data.cost and data.cost.daily or 0) },
    { 'Weekly Cost', string.format('$%.2f', data.cost and data.cost.weekly or 0) },
    { 'Monthly Cost', string.format('$%.2f', data.cost and data.cost.monthly or 0) },
    { '──────────', '──────────' },
    { 'MCP Servers', data.mcp and string.format('%d/%d', data.mcp.connected, data.mcp.total) or 'N/A' },
  }

  -- Add MCP server names
  if data.mcp and data.mcp.servers then
    for _, server in ipairs(data.mcp.servers) do
      table.insert(entries, { '  Server', server })
    end
  end

  pickers.new({}, {
    prompt_title = M.config.icons.claude .. ' Claude Code Statusline',
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format('%-15s %s', entry[1], entry[2]),
          ordinal = entry[1] .. ' ' .. entry[2],
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value[1] == 'Repository' then
          -- Open repo in file browser if it's the repo entry
          local path = data.repository and data.repository.path
          if path then
            vim.cmd('edit ' .. path)
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Setup highlights
  setup_highlights()

  -- Create user commands
  vim.api.nvim_create_user_command('ClaudeStatusline', function()
    M.show_details()
  end, { desc = 'Show Claude Code statusline details' })

  vim.api.nvim_create_user_command('ClaudeStatuslineRefresh', function()
    M.refresh()
  end, { desc = 'Refresh Claude Code statusline data' })

  vim.api.nvim_create_user_command('ClaudeStatuslineTelescope', function()
    M.telescope_picker()
  end, { desc = 'Open Claude Code statusline in Telescope' })

  -- Start auto-refresh if configured
  if M.config.refresh_interval > 0 then
    start_auto_refresh()
  end

  -- Cleanup on VimLeave
  vim.api.nvim_create_autocmd('VimLeave', {
    callback = stop_auto_refresh,
  })
end

return M
