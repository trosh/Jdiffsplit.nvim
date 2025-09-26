local M = {}

function M.get_output(cwd, command)
	local out = vim.system(command, { cwd = cwd }):wait()
	if out.code ~= 0 then
		print(out.stderr)
		return nil
	end
	return out.stdout
end

function M.Jdiffsplit(splitcmd, revision)
	if revision == "" then revision = "@-" end
	-- Save the current buffer's filename
	local path = vim.api.nvim_buf_get_name(0)
	local folder   = vim.fn.fnamemodify(path, ':h')
	local filename = vim.fn.fnamemodify(path, ':t')
	-- Get the short description of the target revision
	local change_id = assert(M.get_output(folder, {
		"jj", "show", "--no-patch", revision,
		"--template", "change_id.shortest()", }))
	-- Get the state of the file in the target revision
	local file_contents = assert(M.get_output(folder, {
		"jj", "file", "show", filename, "--revision", revision, }))
	-- Create a new split with a scratch buffer
	vim.cmd(splitcmd .. " new")
	vim.opt_local.buftype   = 'nofile'
	vim.opt_local.bufhidden = 'wipe'
	vim.opt_local.swapfile  = false
	vim.api.nvim_buf_set_name(0,
		string.format('%s:%s(%s)', path, change_id, revision)
	)
	-- Split the file contents into lines
	local lines = vim.split(file_contents, "\n")
	-- If the file had a final newline (as it should)…
	if #lines > 0 and lines[#lines] == "" then
		-- … Remove the resulting empty element
		table.remove(lines, #lines)
		-- TODO if there was EOL, ensure the buffer has no EOL
	end
	-- Insert the lines into the buffer
	vim.api.nvim_buf_set_lines(0, -2, -1, false, lines)
	-- Make the new buffer read-only
	vim.cmd('setlocal readonly')
	-- Configure syntax highlighting based on the filename
	local filetype = vim.fn.fnamemodify(path, ':e')
	vim.bo.filetype = filetype
	vim.bo.syntax   = filetype
	-- Enable diff mode for both buffers
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	vim.cmd('norm! zR') -- open folds
	--vim.cmd('norm! gg') -- cursor on first line
	--vim.cmd('norm! ]c') -- cursor on first change
	--vim.cmd('norm! zz') -- center view around cursor
	--vim.cmd('wincmd p') -- Return to the new buffer
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
