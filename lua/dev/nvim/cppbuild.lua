local views = require('dev.nvim.ui.views')
local utils = require('utils')
local cmake = require('dev.nvim.cmake')
local prj = require('dev.lua.project')
local fs = require('dev.lua.fs')
local runner = require('dev.nvim.runner')

local M = {
    configs = nil,
    targets = nil,

    current = {
        config = nil,
        targets = nil,
    },

    cpus = 8,
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

M.clean = function()
    local cmd = 'cmake --build --target clean --preset ' .. M.current.config.configure.name
    runner.zellij_run(cmd)
end

M.reset = function()
    local cmd = "~/git/nmpc-obs/cpp/scripts/reset_conan.fish"
    runner.zellij_run(cmd)
end

-- Command selection function
-- Timer command handler
M.command = function(args)
    local subcommand = args.fargs[1]
    if not subcommand then
        M.show()
        return
    end

    if subcommand == 'build' then
        M.build()
    elseif subcommand == 'debug' then
        M.debug()
    elseif subcommand == 'run' then
        M.run()
    elseif subcommand == 'configure' then
        M.configure()
    elseif subcommand == 'select' then
        local this = args.fargs[2]
        if this == 'config' then
            M.select_config()
        elseif this == 'target' then
            M.select_target()
        end
    elseif subcommand == 'cmake' then
        cmake.get_all()
    else
        vim.notify("Invalid command. Usage: :Timer <configure | build | run | select target | config | cmake get")
    end
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
    M.current.targets = M.current.targets or {}
    for i, t in ipairs(M.current.targets) do
        targets = targets .. t
        if i < #M.current.targets then
            targets = targets .. ', '
        end
    end

    local content = {
        'Con(f)ig :  ' .. config_name,
        'Targe(t)s: [' .. targets .. ']',
        '',
        '| (b)uild  |  (r)un   | (c)onfigure | c(l)ean | (q)uit |',
    }

    local redraw = M.win ~= nil
    if not redraw then
        M.win = views.new()
        M.win:config({
            content = content,
            title = 'C++ Build',
            title_pos = 'center',
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

    vim.api.nvim_buf_set_keymap(0, 'n', 's',    ':lua require("dev.nvim.cmake").show()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'r',    ':lua require("dev.nvim.cppbuild").run()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'f', ':lua require("dev.nvim.cppbuild").select_config()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("dev.nvim.cppbuild").select_target()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'q',   ':lua require("dev.nvim.cppbuild").close()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'c',    ':lua require("dev.nvim.cppbuild").configure()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'b',    ':lua require("dev.nvim.cppbuild").build()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'l',    ':lua require("dev.nvim.cppbuild").clean()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'a',    ':lua require("dev.nvim.cppbuild").reset()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '<Esc>',':lua require("dev.nvim.cppbuild").close()<CR>', {noremap = true, silent = true})
end

M.redraw = function()
    if M.win == nil then
        return
    end
    M.win:redraw()
end

vim.api.nvim_create_autocmd("VimResized", {
  callback = M.redraw
})

M.configure = function()
    local cmd = 'cmake --preset ' .. M.current.config.configure.name
    vim.notify('cmd: ' .. cmd)
    
    runner.zellij_run(cmd)
end

M.build = function()
    local cmd = 'cmake --build '

    if M.current.targets ~= nil and #M.current.targets >0 then
        cmd = cmd .. ' --target ' .. table.concat(M.current.targets, ' ')
    end
    if M.cpus ~= nil and M.cpus > 1 then
        cmd = cmd .. ' --parallel ' .. M.cpus
    end
    cmd = cmd .. ' --preset ' .. M.current.config.configure.name
    vim.notify('cmd: ' .. cmd)
    runner.zellij_run(cmd)
end

M.debug = function()
    if M.current.targets == nil or #M.current.targets == 0 then
        M.select_target()
    end

    local cmd = 'gdb ' .. M.current.config.configure.build_dir .. '/' .. M.current.targets[1]
    runner.zellij_run(cmd)
end
M.run = function()
    if M.current.targets == nil or #M.current.targets == 0 then
        M.select_target()
    end

    local cmd = M.current.config.configure.build_dir .. '/' .. M.current.targets[1]
    runner.zellij_run(cmd)
end

M.cmake_get_all = function()
    M.configs, M.targets = cmake.get_all()
    M.current.config = M.configs[2]
    M.current.targets = {}
end
function M.complete_command(arg_lead, cmd_line, cursor_pos)
    -- These are the valid completions for the command
    local options = { "run", "build", "configure", "cmake", "get", "target", "config", "select", "debug" }
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, options)
end

vim.api.nvim_create_user_command('Cpp', function(args)
    M.command(args)
end, { nargs = '*' , complete = M.complete_command })

vim.api.nvim_set_keymap('n', '<F10>', ':Cpp<CR>', { noremap = true, silent = true })

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
