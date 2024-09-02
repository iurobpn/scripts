
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
    if vim ~= nil then
        return vim.fn.expand('%:p')
    else
        return ''
    end
end

