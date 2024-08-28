require'dev.nvim.ui.float'
require('dev.lua.fs')
require('dev.lua.utils')
require('utils')

local json = require('cjson')

local inspect = require('inspect')
local Log = require('dev.lua.log')

local fmt = string.format

local log = Log('qfloat_log')

qfloat = {
    win_id = nil,
    last_file = '',
    root_priority = {'main_root', 'git', 'root_files'},
    settings_file = '.settings.json',
    root_dir = nil,
    main_root = '.root',
    root_files = { -- not tested
        'root.tex',
    },
}

function read_output(cmd)
    local fd = io.popen(cmd)
    local s = fd:read('*a')
    fd:close()
    return s
end

function init()
    qfloat.root_dir = find_root()
    if not qfloat.root_dir then
        print('Project root directory not found')
        return
    else
        print('Project root directory: ' .. qfloat.root_dir)
    end

    local filename = qfloat.root_dir .. '/' .. qfloat.settings_file
    local fd = io.open(filename, 'r')
    if fd then
        local s = fd:read('*a')
        local settings = nil
        if s and s ~= '' then
            settings = json.decode(s)
            for k, v in pairs(settings) do
                qfloat[k] = v
            end
        end
        fd:close()
    else
        print('settings file not found')
    end
end



-- local log_file = '/tmp/error_lua.log'
function qrun(cmd)
    vim.cmd.cexpr(fmt('system("%s")', cmd))
    qopen()
end

function qrun_lua(filename)
    if not filename or filename == '' then
        filename = get_current_file()
    end
    qfloat.last_file = filename

    -- qrun(fmt('lua.fish %s', filename))
    vim.cmd.cexpr(fmt('system("lua.fish %s")', filename))

    f = io.open(qfloat.settings_file, 'w')
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

function fzf_run(arg)
    local source, sink, options = arg.source, arg.sink, arg.options
    if not source then
        source = 'fd . --type f --hidden --follow --exclude .git --exclude .gtags'
    end

    if not sink then
        sink = function(selected)
            qfloat.last_file = selected
        end
    end
    vim.fn['fzf#run']({source = source, sink = sink, options = options})
end

function qrun_fzf()
    local source = 'find . -type f'
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
function qopen()
    -- Check if the quickfix list is empty
    local lines = vim.fn.getqflist({size = 1}).size
    if lines == 0 then
        print("Quickfix list is empty.")
        return
    end

    -- Calculate window size and position
    -- local opts = get_options({rel_width = 0.5, rel_height = 0.3, rel_row = 0.75, rel_col = 0.25})

    --
    -- Open the quickfix window
    -- print('filename in qopen(): ' .. filename)
    vim.cmd('copen')
    win = Window({
        width = 0.5,
        height = 0.3,
        row = 0.75,
        col = 0.25,
        current = true,
        modifiable = false,
    })
    -- print('Window: ' .. inspect(win))
    win:add_map('n', '<CR>', ':lua qclose_link()<CR>', { noremap = true, silent = true })
    win:add_map('n', '<Space>', ':lua qlink()<CR>', { noremap = true, silent = true })
    win:open()
    qfloat.win_id = win.id

    -- win:
    -- open_current_window_as_float(opts)

    -- Convert the quickfix window into a floating window
    -- vim.api.nvim_win_set_config(qfloat.win_id, opts)

    -- Map 'q' to close the floating quickfix window
    -- vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', ':lua qclose_link()<CR>', { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(0, 'n', '<Space>', ':lua qlink()<CR>', { noremap = true, silent = true })

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

function qget_link()
    local line = vim.fn.getline('.')
    local list_item = split(line, '|')
    if #list_item < 2 then
        print("No quickfix entry found.")
        return nil
    end
    local file = list_item[1]
    local n_line = list_item[2]
    return file, n_line
end

function qlink()
    local file, line = qget_link()
    if not file or not line then
        print("No quickfix entry found.")
        return
    end
    vim.cmd('wincmd k') -- Center the cursor
    vim.cmd('edit ' .. file)
    vim.fn.cursor(line, 0)
    vim.cmd('wincmd p') -- Center the cursor
end

-- Function to open the file at the current line and close the quickfix window
function qclose_link()
    -- local qf_entry = vim.fn.getqflist({ idx = 0 }) -- Get the current quickfix entry
    local file, line = qget_link()

    vim.cmd('cclose') -- Close the quickfix window
    vim.cmd('edit ' .. file) -- Open the file
    vim.fn.cursor(line, 0) -- Move to the correct line
end

function update_time(buf)
    local time = os.date("%H:%M:%S")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {time})
end

function qmessage()
    set_message_errors()
    qopen()
end

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
