local templater = require 'lustache'
local M = {
    templater = templater,
    templates = nil,
    config = {
        template_dir = '/home/gagarin/.config/nvim/templates',
    },
}
M.templates = {
    author  = 'Iuro Nascimento',
    email = 'iuro@ufmg.br',
    Today = function()
        return os.date('%A %d %B %Y')
    end,
    today = function()
        os.date('%Y-%m-%d')
    end,
    year  = function()
        os.date('%Y')
    end,
    month = function()
        os.date('%m')
    end,
    day   = function()
        os.date('%d')
    end,
    time  = function()
        os.date('%H:%M:%S')
    end,
    date  = function()
        os.date('%Y-%m-%d %H:%M:%S')
    end,
    root = M.config.template_dir,
}

M.templates.reminders = function()
    local today = os.date('%a')
    local templ
    if today == "Sun" or today == "Sat" then
        templ = 'weekndday.tpl'
    else
        templ = 'workday.tpl'
    end
    local filename
    if M.templates.root == '' then
        filename = templ
    else
        filename = M.templates.root .. '/' .. templ
    end
    local file = io.open(filename, 'r')
    if not file then
        print(string.format('File %s does not exist', filename))
        return ''
    end
    local file_content = file:read("*all")
    file:close()
    return M.templater:render(file_content, M.templates)
end

-- create a command to insert the template
-- :lua require('templater').insert_template()
function M.expand(text)
    return M.templater:render(text, M.templates)
end

function M.expand_file(template_file)
    if template_file == nil then
        require'dev.nvim.fzf'.run({
            source_append = M.templates.root,
            sink = function(selected)
                M.expand_file(selected)
            end,
        })
        
        return
    end
    print("template file: ")
    require'utils'.pprint(template_file)
    local file = io.open(template_file, 'r')
    if file == '' or file == nil or not file then
        print(string.format('Template file %s does not exist', template_file))
        return ''
    end
    local file_content = file:read("*all")
    file:close()
    local content = require'utils'.split(M.expand(file_content), '\n')
    if type(content) == 'string' then
        content = {content}
    end
    if vim then
        vim.api.nvim_put(content, 'l', true, false)
    else
        return content
    end
end
vim.api.nvim_create_user_command('TemplIns', function()
    M.expand_file()
end, {})
return M
