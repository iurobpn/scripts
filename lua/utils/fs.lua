local lfs = require('lfs')
local utils = require('utils')

-- Helper function to check if a file exists
local M = {}

function M.file_exists(filename)
    if type(filename) ~= 'string' then
        vim.notify('Filename must be a string', vim.log.levels.ERROR)
        return false
    end
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

-- get current file in vim/neovim
function M.get_current_file()
    if vim ~= nil then
        return vim.fn.expand('%:p')
    else
        return ''
    end
end

-- get basename from path, the last part of the path without a /
function M.basename(path)
    return M.get_filename(path)
end
function M.get_filename(path)
    local parts = utils.split(path, '/')
    return parts[#parts]
end

-- get a path from a path/file or path
function M.get_path(filepath)
    if M.is_dir(filepath) then
        return filepath
    end
    local is_root = filepath:sub(1,1) == '/'
    local parts = utils.split(filepath, '/')
    parts[#parts] = nil
    local out = table.concat(parts, '/')
    out = is_root and '/' .. out or out
    return out
end

-- get a path from a path/file or path
function M.downdir(filepath)
    local is_root = filepath:sub(1,1) == '/'
    if filepath == '/'  then
        return '/'
    end
    local parts = utils.split(filepath, '/')
    if #parts <= 1 then
        return '.'
    end
    parts[#parts] = nil
    local out = table.concat(parts, '/')
    out = is_root and '/' .. out or out
    return out
end

function M.get_file_extension(path)
    local parts = utils.split(path, '.')
    return parts[#parts]
end

function M.is_dir(path)
    return lfs.attributes(path, 'mode') == 'directory'
end
function M.is_file(path)
    return lfs.attributes(path, 'mode') == 'file'
end

return M

