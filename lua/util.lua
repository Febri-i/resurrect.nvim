return {
	lstat = function(path)
		if not #path then
			return nil
		end
		return vim.loop.fs_lstat(vim.fn.expand(path))
	end,
	realpath = function(path)
		if not #path then
			return nil
		end
		return vim.loop.fs_realpath(vim.fn.expand(path))
	end,
	readfile = function(path)
		if not #path then
			return {}
		end
		return vim.fn.readfile(vim.fn.expand(path)) or {}
	end,
	writefile = function(data, path)
		vim.fn.writefile(data, vim.fn.expand(path))
	end,
}
