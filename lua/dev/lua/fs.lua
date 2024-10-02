local lfs = require('lfs')
local utils = require('utils')

-- Helper function to check if a file exists
local M = {}

function M.file_exists(filename)
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

function M.get_current_file()
    if vim ~= nil then
        return vim.fn.expand('%:p')
    else
        return ''
    end
end

function M.get_filename(path)
    local parts = utils.split(path, '/')
    return parts[#parts]
end

function M.get_file_extension(path)
    local parts = utils.split(path, '.')
    return parts[#parts]
end

function is_dir(path)
    return lfs.attributes(path, 'mode') == 'directory'
end
function is_file(path)
    return lfs.attributes(path, 'mode') == 'file'
end

return M

