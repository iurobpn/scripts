local fzf_lua = require('fzf-lua')

local nvim = {
    utils = require('dev.nvim.utils')
}

local json = require('cjson')
local float = require('dev.nvim.ui.float')
local query = require('dev.lua.tasks.query')
local utils = require('utils')
local pv = require('dev.nvim.ui.fzf_previewer')

require('class')

local M = {


}

-- M = class(M, {constructor = function(self, filename)
--     if filename ~= nil then
--         self.filename = filename
--     end
--     self.sql = sql.Sql(self.path .. self.filename)
--     return self
-- end})

function M.params_to_string(parameters)
    local str = ''
    if parameters == nil then
        return str
    end
    for k,v in pairs(parameters) do
        str = str .. '[' .. k .. ':: ' .. v .. '] '
    end
    return str
end

function M.tags_to_string(tags)
    local str = ''
    if tags == nil then
        return str
    end
    for _,tag in ipairs(tags) do
        str = str ..  tag .. ' '
    end
    return str
end

function M.open_context_window(filename, line_nr)
    local context_width = math.floor(vim.o.columns * 0.4)
    local context_height = math.floor(vim.o.lines * 0.5)
    local context_row = math.floor((vim.o.lines - context_height) / 4)
    local context_col = math.floor(vim.o.columns * 0.55)

    local content = nvim.utils.get_context(filename, line_nr)

    local win = nvim.ui.views.fit()
    win:config(
        {
            -- relative = 'editor',
            -- size = {
            --     absolute = {
            --         width = context_width,
            --         height = context_height,
            --     },
            -- },

            position = {
                absolute = {
                    row = context_row,
                    col = context_col,
                },
            },
            buffer = nvim.ui.views.get_scratch_opt(),
            border = 'single',
            content = content,
            options = {
                buffer = {
                    modifiable = false,
                },
                window = {
                    winbar = 'file context on line ' .. line_nr,
                }
            },
        }
        
    )

    win:open()
    -- vim.cmd('set ft=markdown')
    --get last line nr
    line_nr = math.floor(#content/2)
    vim.api.nvim_win_set_cursor(win.vid, {line_nr, 0})
end

function M.tostring(tasks)
    local tasks_qf = M.format_tasks(tasks)
    local out = ''
    for _, task in pairs(tasks_qf) do
        out = out .. string.format('%s:%d: %s\n', task.filename, task.lnum, task.text)
    end

    return out
end

function M.set_custom_hl(buf, line)

    local entry = vim.api.nvim_buf_get_lines(buf, line-1, line, false)
    
    entry = entry[1]
    if entry == nil then
        print(string.format('could not get line %d from buffer', line))
        return
    end
    local due_date = entry:match("due:: (%d%d%d%d%-%d%d%-%d%d)")
    if due_date == nil then
        print('no due date found')
        return
    end
    local gruvbox = require('config.gruvbox-colors').get_colors()
    local hl_group = 'MetaTags'
    vim.api.nvim_set_hl(0, hl_group, { fg = gruvbox.gray , italic = true })  -- Adjust the color as needed
    -- Define the namespace for extmarks (you can use the same namespace for multiple extmarks)
    local ns_id = vim.api.nvim_create_namespace('previewer_due')
    -- Create your custom highlight group with color similar to comments

    -- Set virtual text at a given line (line 2 in this case, 0-based index)
    vim.api.nvim_buf_set_extmark(buf, ns_id, line-1, 0, {
        virt_text = { { string.format("(due: %s) ", due_date), hl_group } },  -- Text and optional highlight group
        virt_text_pos = "inline",
        priority = 100,
        -- virt_text_pos = "eol",  -- Places the virtual text at the end of the line
    })
end

function M.to_lines(tasks)
    local _, files_qf = M.format_tasks(tasks)
    local out = {}
    for _, file_qf in pairs(files_qf) do
        -- local file = task.filename:sub(path:len()+1, task.filename:len())
        -- if file[1] == '/' then
        --     file = file.sub(2, file:len())
        -- end
        table.insert(out, string.format('%s:%d:', file_qf.file, file_qf.line))
    end
    vim.cmd('lcd ' .. query.Query.path)

    return out
end

function M.format_file_line(tasks)
    if tasks == nil then
        error('tasks is nil')
    end
    local out = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(out,string.format('%s:%d:', task.filename, task.line_number))
    end

    return out
end

function M.format_tasks_short(tasks)
    local tasks_qf = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags)})
    end

    return tasks_qf
end

function M.format_tasks(tasks_in)
    local tasks = {}
    local files = {}
    for _, task  in pairs(tasks_in) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks, '- [ ] ' .. (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags))
        table.insert(files, {file = task.filename, line = task.line_number})
    end

    return tasks, files
end


function M.query_by_due()
    local q = query.Query()
    local tasks = q:select_by_tag_and_due()

    return tasks
end

function M.query_by_tag_and_due(tag)
    local q = query.Query()
    local tasks = q:select_by_tag_and_due(tag)

    return tasks
end

function M.query_by_tag(tag)
    local q = query.Query()
    local tasks = q:select_by_tag(tag)

    return tasks
end

function M.parse_entry(entry_str)
    -- Assume an arbitrary entry in the format of 'file:line'
    local task_splited = utils.split(entry_str, ':')
    if task_splited == nil then
        error('task_splited is nil')
    end
    local path = task_splited[1]
    local line = task_splited[2]
    return {
        path = string.format('"%s"', path),
        line = tonumber(line) or 1,
        col = 1,
    }
end

function M.fzf_query_due(tag, ...)
    local opts = {...}
    opts = opts[1] or {}

    if opts.due == nil then
        opts.due = {order = 'ASC'}
    end
    M.fzf_query(tag, opts)
end

M.search = function(tag, ...)
    return M.query_tag(tag, ...)
end

M.query_tag = function(tag, ...)
    local opts = {...}
    opts = opts[1] or {}
    local tasks
    if opts == nil or opts.due == nil then
        tasks = M.query_by_tag(tag)
    else
        local order = nil
        if opts.due ~= nil and opts.due.order ~= nil then
            order = opts.due.order
        end
        tasks = M.query_by_tag_and_due(tag, order)
    end
    return tasks
end

function M.select(query)
    return M.picker.select_tasks(query)
end

function M.fzf_query(tasks, ...)
    -- local tasks = M.query_tag(tag, ...)
    -- local str_tasks = M.to_lines(tasks)
    local opts = {...}
    opts = opts[1] or {}

    -- debug
    local sink = opts.sink or function(selected)
        if selected then
            for _, task in ipairs(selected) do
                local filename, line_nr = utils.get_file_line(task, ':')
                if filename and line_nr then
                    vim.cmd.edit(filename)
                    vim.fn.cursor(line_nr, 1)
                end
            end
        end
    end

    fzf_lua.fzf_exec(tasks, {
        previewer = pv.Previewer,
        prompt    = 'Tasks❯ ',
        cwd       = query.Query.path,
        fzf_opts = {
            ["--no-sort"] = true,
        },

        -- actions inherit from 'actions.files' and merge
        actions = {
            ["default"] =  sink
        },
    })
    -- require'fzf-lua'.files(str_tasks, task_query_opts)
end

function M.open_window(tag,due)
    local tasks_tb
    if due == nil then
        due = false
        tasks_tb = M.query_by_tag(tag)
    else
        tasks_tb = M.query_by_tag_and_due(tag)
    end

    local tasks_line, files = M.format_tasks(tasks_tb)
    local win = dev.nvim.ui.views.scratch(tasks_line, {
        title = (tag or '') .. ' tasks',
        title_pos = 'center',
        size = {
            flex = true,
        },
    })

    win:open()
    vim.cmd("set ft=markdown")
    vim.api.nvim_win_set_option(0, 'winhighlight', 'Normal:Normal')
    for _, file in ipairs(files) do
        -- M.set_custom_hl(win.buf, i)
        win:set_buf_links(files)
    end
    vim.opt.wrap = false
    vim.opt.number = false
    vim.opt.relativenumber = false
    M.highlight_tags(win.buf)
    local opts = vim.api.nvim_win_get_config(win.vid)

    -- Reapply the configuration to the floating window
    vim.cmd.hi('clear FloatTitle')
    -- win.buffer
end

function M.open_due_window(tag)
    local tasks_tb = M.query_by_tag_and_due(tag)
    local tasks_line, files = M.format_tasks(tasks_tb)
    local win = dev.nvim.ui.views.scratch(tasks_line, {
        title = (tag or '') .. ' tasks',
        title_pos = 'center',
        size = {
            flex = true,
        },
    })

    win:open()
    vim.cmd("set ft=markdown")
    vim.api.nvim_win_set_option(0, 'winhighlight', 'Normal:Normal')
    for _, file in ipairs(files) do
        -- M.set_custom_hl(win.buf, i)
        win:set_buf_links(files)
    end
    vim.opt.wrap = false
    vim.opt.number = false
    vim.opt.relativenumber = false
    M.highlight_tags(win.buf)
    local opts = vim.api.nvim_win_get_config(win.vid)

    -- Reapply the configuration to the floating window
    vim.cmd.hi('clear FloatTitle')
    -- win.buffer
end

-- Function to highlight the pattern
function M.highlight_tags(bufnr)
    local ns_id = vim.api.nvim_create_namespace("highlight_tags")

    -- Define the orange highlight group
    vim.api.nvim_set_hl(0, 'PatternHighlight', {fg = '#FFA500'})  -- Orange color (Hex: #FFA500)

    -- Define the pattern
    local pattern = '\\[\\w\\+:: [\\w\\d:\\-/]\\+\\]'  -- Escaped Lua pattern for your desired regex
    -- Get total lines in the buffer
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    -- Loop through each line and apply highlights
    for line_num = 0, line_count - 1 do
        -- Get the line content
        local line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1]

        -- Find matches using vim.fn.matchstrpos, which returns start and end of a match
        local start_pos, end_pos = 0, 0
        repeat
            local res = vim.fn.matchstrpos(line, pattern, end_pos)
            start_pos = tonumber(res[2]) + 1  -- Convert to 1-based index
            end_pos = tonumber(res[3]) + 1  -- Convert to 1-based index
            if start_pos > 0 and end_pos > 0 then
                -- Highlight the match with higher priority to overlay link highlights
                vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'PatternHighlight', line_num, start_pos, end_pos, {priority = 150})
            end
        until start_pos == 0 and end_pos == 0  -- Stop if no more matches are found
    end
end

M.init = function()
    -- dev.lua.tasks.indexer.index()
    M.tasks = M.load_tasks()
end

function M.open_current_tag()
    local tag = vim.fn.expand('<cWORD>')
    tag = tag:match('#(%w+)')
    if tag == nil then
        vim.notify('No tag found')
        return
    end
    M.open_window(tag)
end

M.load_tasks = function()
    local json_file = M.path .. '/' .. M.filepath .. '/tasks.json'
    local fd = io.open(json_file, 'r')
    if fd == nil then
        print('Failed to open ' .. json_file)
        return
    end
    M.json_tasks = fd:read('*a')
    
    M.tasks = json.decode(json_tasks)
end

function M.complete(arg_lead, cmd_line, cursor_pos)
    -- These are the valid completions for the command
    local options = { "due", "#main", "#today", "#important", "#res", "#research" }
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, options)
end

M.command = function(args)
    local cmd = args.fargs[1]
    if cmd == 'due' then
        M.open_window(args.fargs[2],true)
    else
        M.open_window(args.fargs[2])
    end
end

-- create_command
vim.api.nvim_create_user_command('TaskOpenTagDue', 'lua dev.lua.tasks.views.open_due_window(<args>)', {
    nargs = 1,
})
vim.api.nvim_create_user_command('TaskTagDue', 'lua dev.lua.tasks.views.fzf_query_due(<args>)', {
    nargs = 1,
})
vim.api.nvim_create_user_command('TaskTagSearch', 'lua dev.lua.tasks.views.fzf_query(<args>)', {
    nargs = 1,
})
vim.api.nvim_create_user_command('Tasks', function(args)
    M.command(args)
end, { nargs = '*' , complete = M.complete})
vim.api.nvim_set_keymap('n', '<F11>', ':TaskTagSearch ', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F9>', ':TaskTagDue ', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F9>', ':Tasks ', {noremap = true, silent = true})

function M.open_window_by_tag(tag)
    local tasks_qf = M.query_by_tag(tag)
    float.qset(tasks_qf)
    float.qopen()
end

return M
