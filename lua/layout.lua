local util = require("util")
local writefile = util.writefile
local readfile = util.readfile
local lstat = util.lstat

local function buffer_is_valid(buffer_id)
	if not vim.api.nvim_buf_is_valid(buffer_id) then
		return false
	end

	if not vim.api.nvim_buf_is_loaded(buffer_id) then
		return false
	end

	local file_path = vim.api.nvim_buf_get_name(buffer_id)
	if not file_path and not #file_path then
		return false
	end

	local flstat = lstat(file_path)
	if flstat then
		return file_path
	end

	return false
end

local function start_with_empty_window()
	pcall(function()
		local window_list = vim.api.nvim_list_wins()
		for _, window_id in pairs(window_list) do
			vim.api.nvim_win_close(window_id, false)
		end
	end)
	vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, true))
	return vim.api.nvim_get_current_win()
end

local function create_split(buf)
	vim.cmd.vsplit()
	local win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win_id, buf)
	return win_id
end

local function clean_win(win_id)
	vim.api.nvim_buf_delete(vim.api.nvim_win_get_buf(win_id), { force = true })
end

-- keeping things dry
local function apply_split_move(nr, target, type)
	vim.fn.win_splitmove(nr, target, {
		vertical = type == "row",
	})
end

local function put_buffer_accordingly(layout, buf_map)
	local root = start_with_empty_window()
	local win_map = {}
	local function recursive_put_buffer(current_layout, parent_win, parent_type)
		if current_layout.type == "leaf" then
			if current_layout.path then
				local winid = create_split(buf_map[current_layout.path])
				apply_split_move(winid, parent_win, parent_type)
				win_map[current_layout.path] = winid
			end
		else
			local tmp_root = create_split(vim.api.nvim_create_buf(true, true))

			apply_split_move(tmp_root, parent_win, parent_type)

			for _, child in ipairs(current_layout.children) do
				recursive_put_buffer(child, tmp_root, current_layout.type)
			end
			clean_win(tmp_root)
		end
	end

	recursive_put_buffer(layout, root, layout.type)

	clean_win(root)
	return win_map
end

local function apply_layout_win_size(layout, win_map)
	local function recursive_apply_size(current_layout)
		if current_layout.type == "leaf" then
			local win_id = win_map[current_layout.path]
			if not win_id then
				return
			end
			if not vim.api.nvim_win_is_valid(win_id) then
				return
			end
			if current_layout.width then
				vim.api.nvim_win_set_width(win_id, current_layout.width)
			end

			if current_layout.height then
				vim.api.nvim_win_set_height(win_id, current_layout.height)
			end
		elseif current_layout.children then
			for _, children in pairs(current_layout.children) do
				recursive_apply_size(children)
			end
		end
	end

	recursive_apply_size(layout)
end

local function process_layout(layout, buf_map)
	local win_map = put_buffer_accordingly(layout, buf_map)
	apply_layout_win_size(layout, win_map)
end

local function load_layout(path)
	if not lstat(path) then
		return
	end
	local file_data = readfile(path)
	local layout = vim.fn.json_decode(table.concat(file_data, "\n")) or {}
	if vim.tbl_isempty(layout) then
		return
	end
	if not layout.files or not layout.layout then
		return
	end
	local totalLoaded = 0
	local buf_map = {}
	for _, filepath in ipairs(layout.files) do
		vim.schedule(function()
			vim.cmd.edit(filepath)
			totalLoaded = totalLoaded + 1
			buf_map[filepath] = vim.api.nvim_get_current_buf()
			if totalLoaded >= #layout.files then
				process_layout(layout.layout, buf_map)
			end
		end)
	end
end

local function create_layout(path)
	-- Save every file path so we can load them before applying position later when loading layout
	local files = {}

	local function recursive_parse_winlayout(layout)
		if not layout and #layout < 2 then
			return {}
		end
		local tbl = {}
		if layout[1] == "leaf" then
			local buf_path = buffer_is_valid(vim.api.nvim_win_get_buf(layout[2]))
			if buf_path then
				tbl.type = layout[1]
				tbl.height = vim.api.nvim_win_get_height(layout[2])
				tbl.width = vim.api.nvim_win_get_width(layout[2])
				tbl.path = buf_path
				table.insert(files, buf_path)
				if tbl.height >= vim.go.lines - 3 then
					tbl.height = 9999
				end
			end
		else
			local childrens = layout[2]
			tbl.children = vim.tbl_map(function(child_layout)
				return recursive_parse_winlayout(child_layout)
			end, childrens)
			tbl.children = vim.tbl_filter(function(table)
				return not vim.tbl_isempty(table)
			end, tbl.children)
			tbl.type = layout[1]
		end

		return tbl
	end

	local layout = recursive_parse_winlayout(vim.fn.winlayout())
	writefile({ vim.fn.json_encode({ files = files, layout = layout }) }, path)
end

return {
	load = load_layout,
	save = create_layout,
}
