vim.g.RessurectSessionDir = "~/.vimsession/"
vim.g.RessurectSAutoWipeout = true

local function getSessionDir(name)
	return vim.fn.expand(vim.g.RessurectSessionDir .. "/" .. name .. ".fsession")
end

local function lstat(path)
	if not #path then
		return nil
	end
	return vim.loop.fs_lstat(vim.fn.expand(path))
end

local function realpath(path)
	if not #path then
		return nil
	end
	return vim.loop.fs_realpath(vim.fn.expand(path))
end

local function readfile(path)
	if not #path then
		return nil
	end
	return vim.fn.readfile(vim.fn.expand(path)) or {}
end

local function writefile(data, path)
	vim.fn.writefile(data, vim.fn.expand(path))
end

return {
	setup = function(param)
		param = vim.tbl_extend("keep", param, {
			session_dir = vim.g.RessurectSessionDir,
			auto_wipeout = vim.g.RessurectSAutoWipeout,
		})
		param.session_dir = vim.fn.expand(param.session_dir)
		vim.g.RessurectSAutoWipeout = param.auto_wipeout
		if not realpath(param.session_dir) then
			vim.g.RessurectSessionDir = param.session_dir
		end

		local session_dir_stat = lstat(vim.g.RessurectSessionDir)
		if not session_dir_stat then
			vim.fn.mkdir(vim.fn.expand(vim.g.RessurectSessionDir))
		end
	end,
	save = function(name)
		vim.print(name)
		if not (name and #name) then
			return
		end
		local session_path = getSessionDir(name)
		local bufs = vim.tbl_filter(function(buf_id)
			return vim.api.nvim_buf_is_loaded(buf_id)
		end, vim.api.nvim_list_bufs())
		local bufs_stat = vim.tbl_map(function(buf_id)
			local path = vim.api.nvim_buf_get_name(buf_id)
			local resultlstat = nil
			if realpath(path) then
				resultlstat = lstat(path)
			end
			if resultlstat then
				resultlstat = resultlstat.mtime.nsec
			end
			return { name = path, lastmod = resultlstat }
		end, bufs)
		local valid_buf_path = vim.tbl_filter(function(buf_stat)
			return buf_stat.lastmod and buf_stat.lastmod ~= 0
		end, bufs_stat)
		table.sort(valid_buf_path, function(a, b)
			return a.lastmod > b.lastmod
		end)

		local mapped = vim.tbl_map(function(buf_stat)
			return buf_stat.name
		end, valid_buf_path)
		writefile(mapped, session_path)
	end,
	load = function(name)
		vim.print(name)
		if not (name and #name) then
			return
		end
		if vim.g.RessurectSAutoWipeout then
			vim.cmd([[bufdo bwipeout]])
		end
		local session_path = getSessionDir(name)
		if not lstat(session_path) then
			return
		end
		local paths = readfile(session_path)
		--
		for _, path in ipairs(paths) do
			if lstat(path) then
				vim.schedule(function()
					vim.cmd.edit(path)
				end)
			end
		end
	end,
}
