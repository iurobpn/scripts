local M = {
    root_priority = {'main_root', 'git', 'root_files'},
    settings_file = '.settings.json',
    root_dir = nil,
    find_root = {},
    query_user_root = false,
    main_root = '.root',
    root_files = { -- not tested
        'root.tex',
    },
}

function M.init()
    if vim ~=nil and vim.g.enable_project == nil then
        vim.g.enable_project = true
    end
    if vim == nil or not vim.g.enable_project then
        return
    end
    M.root_dir = find_root()
    if not M.root_dir then
        print('Project root directory not found')
        return
    else
        print('Project root directory: ' .. M.root_dir)
        vim.g.root_dir = M.root_dir
    end

    local filename = M.root_dir .. '/' .. M.settings_file
    local fd = io.open(filename, 'r')
    if fd then
        local s = fd:read('*a')
        local settings = nil
        if s and s ~= '' then
            settings = json.decode(s)
            for k, v in pairs(settings) do
                M[k] = v
            end
        end
        fd:close()
    else
        print('settings file not found')
    end

    local t_period = 30000
    -- save the settings every 30 s
    vim.fn.defer_fn(function()
        M.save_settings()
    end, t_period)
end

function M.save_settings()
    local filename = M.root_dir .. '/' .. M.settings_file
    settings = {}
    for k, v in pairs(M) do
        if k ~= 'find_root' then
            settings[k] = v
        end
    end
    local fd = io.open(filename, 'w')
    if fd then
        fd:write(json.encode(settings))
        fd:close()
    else
        print('Error saving settings')
    end
end


function M.find_root.main_root(main_root)
    if main_root then
        main_root = main_root:gsub('\n', '')
        return M.find_root.root_files({main_root})
    else
        return false
    end
end

function M.find_root.git()
    local cmd = 'git rev-parse --show-toplevel'
    local fd = io.popen(cmd)
    if not fd then
        return false
    end
    local s = fd:read('*a')
    fd:close()

    if string.match(s, 'fatal') then
        return false
    else
        return s:gsub('\n', '')
    end
end

function M.find_root.root_files(file_list)
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

    return false
end
return M;
