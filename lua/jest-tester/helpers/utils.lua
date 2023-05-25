local M = {}

--- Revers a list-like table
---@param list List
---@return List
M.reverse_list_table = function(list)
	local len = #list
	local result = vim.deepcopy(list)
	for i = 1, math.floor(len / 2) do
		result[i], result[len - i + 1] = result[len - i + 1], result[i]
	end
	return result
end

return M
