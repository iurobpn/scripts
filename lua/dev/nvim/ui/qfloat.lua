require'dev.nvim.ui.float'
local fs = require('dev.lua.fs')
local utils = require('utils')

local json = require('cjson')

local inspect = require('inspect')
local Log = require('dev.lua.log')

local fmt = string.format

local log = Log('qfloat_log')

qfloat = {
    win_id = nil,
    last_file = '',
}

function read_output(cmd)
    local fd = io.popen(cmd)
    local s = fd:read('*a')
    fd:close()
    return s
end

function init()
    if vim.g.proj and vim.g.proj.qfloat then
        for k, v in pairs(vim.g.proj.qfloat) do
            qfloat[k] = v
        end
    end
    vim.g.proj.register('qfloat', qfloat)
end

-- local log_file = '/tmp/error_lua.log'
function qrun(cmd)
    vim.cmd.cexpr(fmt('system("%s")', cmd))
    qopen()
end

function qrun_lua(filename)
    if not filename or filename == '' then
        filename = fs.get_current_file()
    end
    qfloat.last_file = filename

    -- qrun(fmt('lua.fish %s', filename))
    vim.cmd.cexpr(fmt('system("lua.fish %s")', filename))

    local f = io.open(qfloat.settings_file, 'w')
    f:write(json.encode(qfloat))
    f:close()
    vim.cmd('copen')
    qopen()

    -- print('Quickfix list updated, entering qopen()')
    -- qopen();
end

function qfile(filename)
    vim.fn.cfile(filename)
    qopen()
end

function qrun_fzf()
    local source = 'fd . --type f'
    local sink = function(selected)
        if selected and #selected > 0 then
            qrun_lua(selected)
        end
    end
    local options = '--prompt="Select a file> "'

    fzf_run({source = source, sink = sink, options = options})
end

-- Store the window ID globally
-- Function to open the quickfix list in a floating window
function qopen(...)
    local opts = {...}
    opts = opts[1] or {}
    vim.cmd('cclose')
    vim.cmd('copen')

    -- Check if the quickfix list is empty
    local n_lines = vim.fn.getqflist({size = 1}).size
    if n_lines == 0 then
        print("Quickfix list is empty.")
        return
    end

    -- Calculate window size and position
    -- local opts = get_options({rel_width = 0.5, rel_height = 0.3, rel_row = 0.75, rel_col = 0.25})

    --
    -- Open the quickfix window
    -- print('filename in qopen(): ' .. filename)
    local win = Window({
        width = 0.5,
        height = 0.3,
        row = 0.75,
        col = 0.25,
        current = true,
        modifiable = false,
    })
    -- get quickfix win id
    if id == 0 then
        print('Quickfix window not found')
        return
    end
    -- print('Window: ' .. inspect(win))
    win:add_map('n', '<CR>', ':lua qclose_link()<CR>', { noremap = true, silent = true })
    win:add_map('n', '<Space>', ':lua qlink()<CR>', { noremap = true, silent = true })
    -- qclose_qfix()
    win:open()
    qfloat.win_id = win.id
    -- win:
    vim.cmd('normal! zt') -- cursor at the top
end

-- Function to close the floating quickfix window
function qclose()
    if Window.close(qfloat.winid) then
        qfloat.win_id = nil
    else
        print("No floating quickfix window to close.")
    end
end

-- Store the window ID of the floating quickfix window
function qtoggle()
    vim.opt.filetype = 'lua'
    if qfloat.win_id and vim.api.nvim_win_is_valid(qfloat.win_id) then
        qclose()
    elseif vim.tbl_isempty(vim.fn.getqflist()) then
        if vim.o.filetype == 'lua' then
            if qfloat.last_file and qfloat.last_file ~= '' then
                qrun_lua(qfloat.last_file)
            else
                qrun_fzf()
            end
        else
            print("Quickfix list is empty.")
        end
    else
        qopen()
    end
end

-- Function to move to the next item in quickfix list
function qnext()
    local is_qf = is_quickfix()
    if is_qf then
        if vim.fn.getqflist({idx = 0}).idx == vim.fn.getqflist({size = 1}).size then
            vim.cmd("cfirst")
        else
            vim.cmd("cnext")
        end
        vim.cmd("normal! zt") -- Center the cursor
    else
        vim.cmd.wincmd('p')
    end
end

function is_quickfix()
    return vim.bo.filetype == 'qf'
end

-- Function to move to the previous item in quickfix list
function qprev()
    local is_qf = is_quickfix()

    if is_qf then
        if vim.fn.getqflist({idx = 0}).idx == 1 then
            vim.cmd("clast")
        else
            vim.cmd("cprevious")
        end
        vim.cmd("normal! zt") -- Center the cursor
    else
        vim.cmd.wincmd('p')
    end
end

-- Function to get the file and line number of the quickfix entry of the line '.'
function qget_link()
    local line = vim.fn.getline('.')
    print('qlink: before split')
    local list_item = utils.split(line, '|')
    print('qlink: after split')

    if list_item == nil or #list_item < 2 then
        print("No quickfix entry found(qget_link).")
        return nil
    end
    local file = list_item[1]
    local n_line = list_item[2]
    return file, n_line
end


-- Function to open the file at the current line
function qlink()
    local file, line = qget_link()
    if file == nil or line == nil then
        print('qlink error: No quickfix entry found.')
        return
    end
    vim.cmd('wincmd k') -- Center the cursor
    vim.cmd('edit ' .. file)
    vim.fn.cursor(line, 0)
    vim.cmd('wincmd p') -- Center the cursor
end

function qopen_close()
    qopen({close_current = true})
end

-- Function to open the file at the current line and close the quickfix window
function qclose_link()
    -- local qf_entry = vim.fn.getqflist({ idx = 0 }) -- Get the current quickfix entry
    local file, line = qget_link()
    if file == nil or line == nil then
        print('qclose_link error: No quickfix entry found.')
        return
    end
    print('file: ' .. file)

    vim.cmd('cclose') -- Close the quickfix window
    vim.cmd('edit ' .. file) -- Open the file
    vim.fn.cursor(line, 0) -- Move to the correct line
end

function update_time(buf)
    local time = os.date("%H:%M:%S")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {time})
end

function qmessage()
    local messages = vim.api.nvim_exec('messages', true)
    qstring(messages)
    qopen()
end

-- function to set the quickfix list from a string represening all error lines.
function qset(errors)
        vim.fn.setqflist(errors, 'r')  -- 'r' replaces the current quickfix list
end

-- Function to set the quickfix list from a string represening all error lines.
-- lines must be separated by '\n' to be parsed, or use the optional sep parameter.
function qstring(lines_str, sep)

    sep = sep or '\n'
    local errors = qparse_all(utils.split(lines_str, sep))
    if errors ~= nil and #errors > 0 then
        qset(errors)
    else
        print("No errors found to populate the quickfix.")
    end
end

-- Function to parse the error lines and return a table with the errors
-- lines are a list of lines
function qparse_all(lines_list)
    local errors = {}
    for _, line in ipairs(lines_list) do
        -- print('line: ' .. line)
        error = qparse(line)
        -- inspect(error, 'error: ')
        if error then
            table.insert(errors, error)
        end
    end
    return errors
end


-- clean e list of errors for lua
function qparse(line)
    local filepath, lnum, message = line:match("^%s*(.*):(%d*):(.*)")
    -- local filepath, lnum, message = line:match("([^:]+):(%d+):?(.*)")
    if filepath == nil then
        filepath, lnum, message = line:match("^%s*(.*):(%d+)(.*)")
        if filepath == nil then
            print("Error parsing line: " .. line)
            return nil
        else
            return {
                filename = filepath,
                lnum = tonumber(lnum),
                text = message, -- Using 0 to refer to the current buffer
            }
        end
    end
end

--close the quickfix window if it is open
function qclose_qfix()
    -- Check if a quickfix window is open
    for _, win in ipairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then
            vim.api.nvim_win_close(win.winid, true)
        end
    end
end
-- Check if a quickfix window is open
local function is_quickfix_open()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      return true
    end
  end
  return false
end

-- Function to open the quickfix list in a floating window and close the original quickfix window
function open_floating_quickfix()
  -- Close the original quickfix window if it's open
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd('cclose')
      break
    end
  end

  -- Create a floating window to display the quickfix list
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.3)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Open the quickfix list
  vim.cmd('copen')

  -- Get the buffer number of the quickfix list
  local qf_buf = vim.fn.getqflist({ winid = 1 }).winid

  -- If a quickfix window exists, transform it into a floating window
  if qf_buf ~= 0 then
    -- Set up the floating window options
    vim.api.nvim_win_set_config(qf_buf, {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
    })
  end
end

-- Example usage

vim.api.nvim_set_keymap('n', '<Tab>', ':lua qtoggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-Left>', ':lua qprev()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-Right>', ':lua qnext()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F3>', ':lua qrun_fzf()<CR>', { noremap = true, silent = true })

vim.api.nvim_create_user_command("Qtoggle", "lua qtoggle()", {})
vim.api.nvim_create_user_command("Qnext", "lua qnext()", {})
vim.api.nvim_create_user_command("Qprev", "lua qprev()", {})
vim.api.nvim_create_user_command("Qopen", "lua qopen()", {})
vim.api.nvim_create_user_command("Qfile", "lua qfile()", {})
vim.api.nvim_create_user_command("Qsearch", "lua qrun_fzf()", {})
vim.api.nvim_create_user_command("Qrun", "lua qrun_lua()", {})
vim.api.nvim_create_user_command("Qclose", "lua Window.close()", {})
vim.api.nvim_create_user_command("Qmessage", "lua qmessage()", {})
