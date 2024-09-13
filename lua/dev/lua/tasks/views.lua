local fzf = require('dev.nvim.fzf')
local nvim = {
    utils = require('dev.nvim.utils')
}

local float = require('dev.nvim.ui.float')
local query = require('dev.lua.tasks.query')
local utils = require('utils')

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
            modifiable = false,
            content = content,
            options = {
                winbar = 'file context on line ' .. line_nr,
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

function M.to_lines(tasks)
    local tasks_qf = M.format_tasks(tasks)
    local out = {}
    local path = query.Query.path
    for _, task in pairs(tasks_qf) do
        -- local file = task.filename:sub(path:len()+1, task.filename:len())
        -- if file[1] == '/' then
        --     file = file.sub(2, file:len())
        -- end
        table.insert(out, string.format('%s:%d:', task.filename, task.lnum))
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
function M.format_tasks(tasks)
    local tasks_qf = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags)})
    end

    return tasks_qf
end

function M.query_by_tag(tag)
    local q = query.Query()
    local tasks = q:select_by_tag(tag)

    return tasks
end

function M.fzf_query(tag)
    local tasks = M.query_by_tag(tag)
    local str_tasks = M.to_lines(tasks)

    local builtin = require("fzf-lua.previewer.builtin")

    -- Inherit from the "buffer_or_file" previewer
    local MyPreviewer = builtin.buffer_or_file:extend()

    function MyPreviewer:new(o, opts, fzf_win)
        MyPreviewer.super.new(self, o, opts, fzf_win)
        setmetatable(self, MyPreviewer)
        return self
    end

    function MyPreviewer:parse_entry(entry_str)
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
    local opts = require('config.fzf')

    local task_query_opts = {
        -- previewer = 'builtin',
        multi     = true,  -- Allow multiple selections
        prompt    = 'Tasks❯ ',
        cwd       = query.Query.path,

        fzf_opts = {
            ['--preview-window'] = 'nohidden,down,50%',
            ['--preview'] = {
                type = "cmd",
                fn = function(items)
                    local task = utils.split(items[1], ':')
                    return string.format('bat --style=default --color=always --highlight-line=%s "%s"', task[2], task[1])
                end
            }

            -- ["--preview"] = 'bat --style=numbers --color=always --theme=gruvbox-dark --highlight-line=$(echo {} | cut -d: -f2) "$(echo {} | cut -d: -f1)"', 
            -- do not include bufnr in fuzzy matching
            -- tiebreak by line no.
            -- ["--delimiter"] = ":",
            -- ["--nth"]       = '1',
            -- ["--tiebreak"]  = 'index',
        },
        -- actions inherit from 'actions.files' and merge
        actions = {
            ["default"] = function(selected)
                if selected then
                    for _, task in ipairs(selected) do
                        local task_splited = utils.split(task, ':')
                        if task_splited == nil then
                            error('task_splited is nil')
                        end
                        local filename = task_splited[1]
                        local line_nr = task_splited[2]
                        if filename and line_nr then
                            vim.cmd.edit(filename)
                            vim.fn.cursor(tonumber(line_nr), 1)
                        end
                    end
                end
            end
        },
    }
    -- for k, v in pairs(task_query_opts) do
    --     opts[k] = task_query_opts[v]
    -- end

    -- require'fzf-lua'.files(str_tasks, task_query_opts)
    fzf.exec(str_tasks, task_query_opts)
        -- prompt = 'Search> ',
        -- fzf_opts = {
            -- ["--delimiter"] = ':',
            -- ["--with-nth"] = 1,
            -- ["--nth"] = 1,
            -- ["--preview-window"] = "right:60%",
            -- ["--preview"] = 'bat --style=numbers --color=always --theme=gruvbox-dark --highlight-line=$(echo {} | cut -d: -f2) $(echo {} | cut -d: -f1)', 
        -- },
        -- preview = {
        --     border         = 'border',        -- border|noborder, applies only to
        --     -- native fzf previewers (bat/cat/git/etc)
        --     wrap           = 'nowrap',        -- wrap|nowrap
        --     hidden         = 'nohidden',      -- hidden|nohidden
        --     vertical       = 'down:45%',      -- up|down:size
        --     horizontal     = 'right:60%',     -- right|left:size
        --     layout         = 'flex',          -- horizontal|vertical|flex
        --     -- flip_columns   = 120,             -- #cols to switch to horizontal on flex
        --     -- Only used with the builtin previewer:
        --     -- title          = true,            -- preview border title (file/buf)?
        --     -- title_pos      = "center",        -- left|center|right, title alignment
        --     -- scrollbar      = 'float',         -- `false` or string:'float|border'
        --     -- -- float:  in-window floating border
        --     -- -- border: in-border chars (see below)
        --     -- scrolloff      = '-2',            -- float scrollbar offset from right
        --     -- -- applies only when scrollbar = 'float'
        --     -- scrollchars    = {'█', '' },      -- scrollbar chars ({ <full>, <empty> }
        --     -- -- applies only when scrollbar = 'border'
        --     -- delay          = 100,             -- delay(ms) displaying the preview
        --     -- -- prevents lag on fast scrolling
        --     -- winopts = {                       -- builtin previewer window options
        --     --     number            = true,
        --     --     relativenumber    = false,
        --     --     cursorline        = true,
        --     --     cursorlineopt     = 'both',
        --     --     cursorcolumn      = false,
        --     --     signcolumn        = 'no',
        --     --     list              = false,
        --     --     foldenable        = false,
        --     --     foldmethod        = 'manual',
        --     -- },
        -- },

        -- previewers = {
        --     -- Enable syntax highlighting for the preview window.
        --     bat = {
        --         cwd = query.Query.path,
        --         enabled = true,
        --         theme = 'gruvbox-dark',  -- Choose your preferred theme
        --         args = '--style=numbers --color=always --theme=gruvbox-dark --highlight-line=$(echo {} | cut -d: -f2) $(echo {} | cut -d: -f1)',
        --     }
        -- },
            -- })
            --    sink = function(selected)
            --     -- capture the selected tasks
            --     local selected_tasks = {}
            --     for _, task_line in ipairs(selected) do
            --         -- extract file and line information (and other data)
            --         table.insert(selected_tasks, task_line)
            --     end
            --
            --     -- prompt for refining the search on the selected tasks
            --     m.prompt_refine_search(selected_tasks)
            -- end
end

-- create_command
vim.api.nvim_create_user_command('TaskFzf', M.fzf_query, {
    nargs = 1,
    complete = 'customlist,v:lua.dev.nvim.tasks.complete_tag',
})
vim.api.nvim_set_keymap('n', '<F11>', ':TaskFzf ', {noremap = true, silent = true})

function M.open_window_by_tag(tag)
    local tasks_qf = M.query_by_tag(tag)
    float.qset(tasks_qf)
    float.qopen()
end

return M
