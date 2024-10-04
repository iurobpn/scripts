local views = require('dev.nvim.ui.views')
local utils = require('utils')
local cmake = require('dev.nvim.cmake')
local prj = require('dev.lua.project')
local fs = require('dev.lua.fs')

local M = {
    configs = nil,
    targets = nil,

    current = {
        config = nil,
        targets = nil,
    }
}

M.get_config_names = function(configs)
    local names = {}
    for i, config in ipairs(configs) do
        table.insert(names, tostring(i) .. ': ' .. config.configure.name)
    end
    return names
end

-- a functionusing fzflua to select a config
-- and a target
M.select_config = function()
    local config_names = M.get_config_names(M.configs)
    local config = require('fzf-lua').fzf_exec(config_names, {
        prompt = 'Select a config>',
        actions = {
            ["default"] = function(selected)
                local sel  = utils.split(selected[1], ':')
                M.current.config = M.configs[tonumber(sel[1])]
                M.show()
            end
        }
    })
end

M.select_target = function()
    local target_names = M.targets
    require('fzf-lua').fzf_exec(target_names,
        {
            prompt = "Select a target>",
            actions = {
                ["default"] = function(selected)
                    utils.pprint(selected, 'selected: ')
                    M.current.targets = selected
                    M.show()
                end
            }
        }
    )
end

-- build the selected config and target
M.init = function()

    -- check if a settings file exists using the prj module
    -- if it does not exist, return and print a warning
    -- if it does, then load the settings file
    -- and recover the last selected config and target
    -- and show the selected config and target

    if (not fs.file_exists('CMakePresets.json')) and (not fs.file_exists('CMakeUserPresets.json')) and (not fs.file_exists('CMakeLists.txt')) then
        vim.notify('Not a c++ preject')
        return
    end

    local m = prj.get('cppbuild')
    if m ~= nil then
        local win = M.win 
        for k, v in pairs(m) do
            M[k] = v
        end
        M.win = win
    end

    prj.register('cppbuild', M, {'win'})

    if M.current.config ~= nil and M.current.targets ~= nil then
        return
    end

    -- check if the current working dir has the CMakePresets.json file
    -- if not, return and print a warning
    -- if it has, then load the configs and targets
    -- and select a config and a target
    -- then show the selected config and target

    if M.configs == nil or M.targets == nil then
        M.configs, M.targets = cmake.get_all()
    end
    M.current.config = M.configs[1]
    M.current.targets = {M.targets[1]}
end

M.close = function()
    M.win:close()
    M.win = nil
end

-- create a window to show the  selected config and target
-- also, if the user wants to build (b), run (r) the build command
-- and show the output in the window created, it can press b to build
-- and q to close the window.
-- if the user wants to change the config or target, it can press c or t
--  to select a new config or target
M.show = function()
    local config_name = 'None'
    if M.current.config and M.current.config.configure and M.current.config.configure.name then
        config_name = M.current.config.configure.name
    end
    local targets = ''
    for i, t in ipairs(M.current.targets) do
        targets = targets .. t
        if i < #M.current.targets then
            targets = targets .. ', '
        end
    end
    local content = {
        'Config:  ' .. config_name,
        'Targets: [' .. targets .. ']',
        '',
        '(b)uild, (r)un, change (c)onfig, change (t)arget r (q)uit'
    }

    local redraw = M.win ~= nil
    if not redraw then
        M.win = views.new()
        M.win:config({
            content = content,
            position = 'center',
            option = {
                buffer = {
                    bufhidden = 'wipe',
                }
            }
        })
        M.win:open()
    else
        print('draw')
        M.win:set_content({''})
        M.win:set_content(content)
    end
    M.win:fit()

    vim.api.nvim_buf_set_keymap(0, 'n', 'b', ':lua require("dev.nvim.cmake").show()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'r', ':lua require("dev.nvim.cmake").run()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'c', ':lua require("dev.nvim.cppbuild").select_config()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("dev.nvim.cppbuild").select_target()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua require("dev.nvim.cppbuild").close()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '<Esc>', ':lua require("dev.nvim.cppbuild").close()<CR>', {noremap = true, silent = true})
end

vim.api.nvim_create_user_command("CppShow", 'lua dev.nvim.cppbuild.show()', {})

M.print = function()
    print('Config: ', vim.inspect(M.current.config))
    print('Target: ', vim.inspect(M.current.targets))
end
-- M.win = views.new()
-- M.win:config({
--     content = 'Hello World',
-- })
-- M.win:open()
M.init()


return M
