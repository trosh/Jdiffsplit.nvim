local M = {}

function M.Jdiffsplit(splitcmd, revision)
	if revision == "" then revision = "@-" end
	local change_id = vim.fn.system(
		string.format("jj show --no-patch -T 'change_id.shortest()' %s",
			vim.fn.shellescape(revision)
		)
	)
	-- Save the current buffer's filename
	local filename = vim.api.nvim_buf_get_name(0)
	-- Execute the command
	local cmd = string.format(
		'jj file show -r %s %s',
		vim.fn.shellescape(revision),
		vim.fn.shellescape(filename)
	)
	local output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		print(output)
		return nil
	end
	-- Create a new split with a scratch buffer
	vim.cmd(splitcmd .. " new")
	vim.opt_local.buftype   = 'nofile'
	vim.opt_local.bufhidden = 'wipe'
	vim.opt_local.swapfile  = false
	vim.api.nvim_buf_set_name(0,
	string.format('%s:%s(%s)', filename, revision, change_id))
	-- Split the output into lines
	local lines = vim.split(output, "\n")
	-- If the output has a final newline (as it should)…
	if #lines > 0 and lines[#lines] == "" then
		-- … Remove the resulting empty element
		table.remove(lines, #lines)
	end
	-- Insert the lines into the buffer
	vim.api.nvim_buf_set_lines(0, -2, -1, false, lines)
	-- Make the new buffer read-only
	vim.cmd('setlocal readonly')
	-- Enable diff mode for both buffers
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	local filetype = vim.fn.fnamemodify(filename, ':e')
	vim.bo.filetype = filetype
	vim.bo.syntax   = filetype
end

function M.setup(opts)
	opts = opts or {} -- Merge user options with defaults
	vim.api.nvim_create_user_command(
		'Jdiffsplit',
		function(opts) M.Jdiffsplit("split", opts.args) end,
		{ nargs = "?" }
	)
	vim.api.nvim_create_user_command(
		'Jvdiffsplit',
		function(opts) M.Jdiffsplit("vert", opts.args) end,
		{ nargs = "?" }
	)
end

return M
