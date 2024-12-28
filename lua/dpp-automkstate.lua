local mkstate_args = nil

local function setup(...)
	mkstate_args = { ... }
end

local waiting = 0

local group = vim.api.nvim_create_augroup('dpp-automkstate', {})

local function watch(parent)
	if not mkstate_args then
		vim.cmd 'echoerr "dpp-automkstate: You must call setup() first"'
		return
	end

	local parent_realpath = vim.uv.fs_realpath(parent)
	if vim.uv.fs_stat(parent_realpath).type == 'directory' then
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
					end,
				})

				-- Locking for Dpp:makeStatePost event
				if waiting == 1 then -- First time ( because after increment )
					vim.api.nvim_create_autocmd('VimLeave', {
						callback = function()
							vim.cmd 'echo "dpp-automkstate: state making...."'

							-- Polling for Dpp:makeStatePost event
							while waiting > 0 do
								vim.wait(100)
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
