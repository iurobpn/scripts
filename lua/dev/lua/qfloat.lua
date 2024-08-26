require('dev.lua.utils')
require('utils')
local json = require('cjson')

local inspect = require('inspect')
local Log = require('dev.lua.log')

local fmt = string.format

local log = Log('qfloat')

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

find_root = {
}

local mt = {}
mt.__call = function(self)
    if vim.g.qfloat_roots then
        qfloat.roots = vim.g.qfloat_roots
    end
    if vim.g.qfloat_root_priority then
        qfloat.root_priority = vim.g.qfloat_root_priority
    end
    for _, root in ipairs(qfloat.root_priority) do
        qfloat.root_dir = find_root[root](qfloat[root])
        if qfloat.root_dir then
            qfloat.root_dir = qfloat.root_dir:gsub('/$', '')
            break
        end
    end

    return qfloat.root_dir
end
setmetatable(find_root, mt)

function find_root.main_root(main_root)
    if main_root then
        main_root = main_root:gsub('\n', '')
        return find_root.root_files({main_root})
    else
        return nil
    end
end

function find_root.git()
    local cmd = 'git rev-parse --show-toplevel'
    local fd = io.popen(cmd)
    if not fd then
        return nil
    end
    local s = fd:read('*a')
    fd:close()

    if string.match(s, 'fatal') then
        return nil
    else
        return s:gsub('\n', '')
    end
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

function find_root.root_files(file_list)
    local lfs = require("lfs")
    local home_dir = os.getenv("HOME")
    local current_dir = lfs.currentdir()
    local cdir = current_dir

    while current_dir ~= home_dir and current_dir ~= '/' do
        for _, file in ipairs(file_list) do
            local root_path = current_dir .. '/' .. file

            if file_exists(root_path) then
                lfs.chdir(cdir)
                return root_path:gsub('\n', '')
            end
        end
        -- Move to the parent directory
        lfs.chdir("..")
        current_dir = lfs.currentdir()
    end
    lfs.chdir(cdir)

    return nil
end

-- Helper function to check if a file exists
function file_exists(filename)
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end



-- local log_file = '/tmp/error_lua.log'
function qrun(cmd)
    vim.cmd.cexpr(fmt('system("%s")', cmd))
    qopen()
end

function qrun_lua(filename)
    if not filename or filename == '' then
        filename = vim.fn.expand('%:p')
    end
    qfloat.last_file = filename

    -- qrun(fmt('lua.fish %s', filename))
    lines_str = read_output(fmt('lua %s', filename))
    if not lines_str then
        print('No output')
        return
    end
    set_quickfix_list(lines_str)

    io.open(qfloat.settings_file, 'w'):write(json.encode({package = "qfloat", last_file = filename}))
    qopen();
end

function qfile(filename)
    vim.fn.cfile(filename)
    qopen()
end

function fzf_run(arg)
    local source, sink, options = arg.source, arg.sink, arg.options
    if not source then
        source = 'find . -type f'
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
    local opts = get_options({rel_width = 0.5, rel_height = 0.3, rel_row = 0.75, rel_col = 0.25})

    -- Open the quickfix window
    vim.cmd('copen')
    open_current_window_as_float(opts)
    -- qfloat.win_id = vim.fn.win_getid()

    -- Convert the quickfix window into a floating window
    -- vim.api.nvim_win_set_config(qfloat.win_id, opts)

    -- Map 'q' to close the floating quickfix window
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', ':lua qclose_link()<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '<Space>', ':lua qlink()<CR>', { noremap = true, silent = true })

    vim.cmd('normal! zt') -- cursor at the top
end
-- Function to close the floating quickfix window
function qclose()
    log:debug('qclose')
    if close_float(qfloat.winid) then
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

    if vim.fn.getqflist({idx = 0}).idx == vim.fn.getqflist({size = 1}).size then
        vim.cmd("cfirst")
    else
        vim.cmd("cnext")
    end
    vim.cmd("normal! zt") -- Center the cursor

    if is_qf then
        vim.cmd.wincmd('p')
    end
end

function is_quickfix()
    return vim.bo.filetype == 'qf'
end

-- Function to move to the previous item in quickfix list
function qprev()
    local is_qf = is_quickfix()

    if vim.fn.getqflist({idx = 0}).idx == 1 then
        vim.cmd("clast")
    else
        vim.cmd("cprevious")
    end
    vim.cmd("normal! zt") -- Center the cursor
    if is_qf then
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


vim.api.nvim_set_keymap('n', '<Tab>', ':lua qtoggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-Left>', ':lua qnext()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-Right>', ':lua qprev()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F3>', ':lua qrun_fzf()<CR>', { noremap = true, silent = true })

vim.api.nvim_create_user_command("Qtoggle", "lua qtoggle()", {})
vim.api.nvim_create_user_command("Qnext", "lua qnext()", {})
vim.api.nvim_create_user_command("Qprev", "lua qprev()", {})
vim.api.nvim_create_user_command("Qopen", "lua qopen()", {})
vim.api.nvim_create_user_command("Qfile", "lua qfile()", {})
vim.api.nvim_create_user_command("Qsearch", "lua qrun_fzf()", {})
vim.api.nvim_create_user_command("Qrun", "lua qrun_lua()", {})
vim.api.nvim_create_user_command("OpenFloat", "lua open_float()", {})
vim.api.nvim_create_user_command("CloseFloat", "lua close_float()", {})
