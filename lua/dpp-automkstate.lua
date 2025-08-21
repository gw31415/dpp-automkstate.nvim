local mkstate_args = nil

local function setup(...)
	mkstate_args = { ... }
end

local waiting = 0
local locker = nil

local group = vim.api.nvim_create_augroup('dpp-automkstate', {})

local function watch(parent)
	if not mkstate_args then
		vim.cmd 'echoerr "dpp-automkstate: You must call setup() first"'
		return
	end

	local parent_realpath = vim.uv.fs_realpath(parent) or ''
	local parent_stat = vim.uv.fs_stat(parent_realpath)
	if parent_stat and parent_stat.type == 'directory' then
		parent_realpath = parent_realpath .. '/'
	end

	local function is_inside_dir(file)
		local resolved_file = vim.uv.fs_realpath(file) or file

		return resolved_file and resolved_file:sub(1, #parent_realpath) == parent_realpath
	end

	return vim.api.nvim_create_autocmd('BufWritePost', {
		group = group,
		callback = function()
			if is_inside_dir(vim.fn.expand '%:p') and (waiting == 0 or waiting == 1) then
				waiting = waiting + 1
				vim.api.nvim_create_autocmd('User', {
					pattern = 'Dpp:makeStatePost',
					once = true,
					callback = function()
						waiting = waiting - 1
						if waiting == 0 and locker then
							vim.api.nvim_del_autocmd(locker)
							locker = nil
						end
					end,
				})

				if waiting == 1 then -- First time (because after increment)
					-- Locking for Dpp:makeStatePost event
					locker = vim.api.nvim_create_autocmd('VimLeave', {
						callback = function()
							vim.cmd 'echo "dpp-automkstate: state making...."'

							-- Polling for Dpp:makeStatePost event
							local try = 20
							while waiting > 0 and try > 0 do
								vim.wait(100)
								try = try - 1
							end
							if try == 0 then
								vim.cmd 'echoerr "dpp-automkstate: Timeout while waiting for Dpp:makeStatePost event"'
							end
						end
					})

					require 'dpp'.make_state(unpack(mkstate_args))
				else -- waiting == 2 (Second time)
					vim.api.nvim_create_autocmd('User', {
						pattern = 'Dpp:makeStatePost',
						once = true,
						callback = function()
							require 'dpp'.make_state(unpack(mkstate_args))
						end,
					})
				end
			end
		end
	})
end

return {
	setup = setup,
	watch = watch,
}
