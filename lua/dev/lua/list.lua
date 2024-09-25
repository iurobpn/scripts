M = {}
M.remove = function(lst, idx)
    for i, _ in pairs(lst) do
    if i == idx then
        table.remove(lst, i)
            break
        end
    end
end


M.extend = function(lst1, lst2)
    for _,val in ipairs(lst2) do
        table.insert(lst1,val)
    end
    return lst1
end

return M
