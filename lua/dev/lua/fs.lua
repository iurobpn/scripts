
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
function get_current_file()
    return vim.fn.expand('%:p')
end

