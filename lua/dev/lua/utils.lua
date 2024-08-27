require 'utils'

function set_message_errors()
-- Function to get the messages and errors from the quickfix list
    -- Capture the output of `:messages`
    local messages = vim.api.nvim_exec('messages', true)
    -- print('msg: ' .. messages)

    -- Split the messages into lines
    set_quickfix(messages)

end

-- Function to set the quickfix list from a string represening all error lines.
-- lines must be separated by '\n' to be parsed, or use the optional sep parameter.
function set_quickfix(lines_str, sep)

    sep = sep or '\n'
    local errors = parse_errors(split(lines_str, sep))
    if errors ~= nil and #errors > 0 then
        vim.fn.setqflist(errors, 'r')  -- 'r' replaces the current quickfix list
    else
        print("No errors found to populate the quickfix.")
    end
end

-- Function to parse the error lines and return a table with the errors
-- lines are a list of lines
function parse_errors(lines_list)
    local errors = {}
    for _, line in ipairs(lines_list) do
        error = parse_error(line)
        if error then
            table.insert(errors, error)
        end
    end
    return errors
end

function parse_error(line)
    local filepath, lnum, message = line:match("^%s*(.*):(%d*):(.*)")
    -- local filepath, lnum, message = line:match("([^:]+):(%d+):?(.*)")
    if filepath == nil then
        return nil
    else
        return {
            filename = filepath,
            lnum = tonumber(lnum),
            text = message, -- Using 0 to refer to the current buffer
        }
    end
end

-- require'dev.lua.qfloat'
