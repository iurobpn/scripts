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
    print('filename: ', filename)
    local file = io.open(filename)
    if not file then
        print(string.format('File %s does not exist', filename))
        return ''
    end
    local file_content = file:read('*a')
    print('file_content')  
    print(file_content)
    file:close()
    return M.templater:render(file_content, M.templates)
end

-- create a command to insert the template
-- :lua require('templater').insert_template()
function M.expand(text)
    return M.templater:render(text, M.templates)
end

function M.expand_file(template_file)
    if template_file == nil or template_file == '' then
        require'fzf-lua'.fzf_exec('fd . -tf ' .. M.templates.root, {
            prompt = 'Select> ',
            actions = {
                ['default'] = function(selected)
                    print('selected: ', selected[1])
                    M.expand_file(selected[1])
                end,
            },
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
    local content = require'utils'.split2(M.expand(file_content), '\n')
    if type(content) == 'string' then
        content = {content}
    end
    if vim then
        vim.api.nvim_put(content, 'l', true, false)
    else
        return content
    end
end
vim.api.nvim_create_user_command('TemplIns', function(opt)
    M.expand_file(opt.args)
end, {nargs='?'})
return M
