local function get_output(cwd, command)
	local out = vim.system(command, { cwd = cwd }):wait()
	if out.code ~= 0 then
		print(out.stderr)
		return nil
	end
	return out.stdout
end

local function Jdiffsplit(vertical, revision)
	if revision == "" then revision = "@-" end
	-- Save the current buffer's filename
	local bufname = vim.api.nvim_buf_get_name(0)
	local path   = vim.fn.fnamemodify(bufname, ':p')
	local folder = vim.fn.fnamemodify(path, ':h')
	local folder = vim.trim(assert(get_output(folder, {
		"jj", "workspace", "root", })))
	local relpath = vim.trim(assert(get_output(folder, {
		"realpath", "--relative-to", folder, path })))
	-- Get the short description of the target revision
	local change_id = assert(get_output(folder, {
		"jj", "show", "--no-patch", revision, "--template", "change_id", }))
	local change_id_short = assert(get_output(folder, {
		"jj", "show", "--no-patch", revision, "--template", "change_id.shortest()", }))
	local tmpdir = vim.trim(assert(get_output(folder, { "mktemp", "--dry-run" })))
	local tmpbase = vim.trim(assert(get_output(folder, { "basename", tmpdir })))
	local tmp_filename = tmpdir .. "/" .. relpath
	assert(get_output(folder, { "jj", "workspace", "add", tmpdir, "--revision", "root()", }))
	assert(get_output(tmpdir, { "jj", "restore", relpath, "--from", change_id, }))
	---- Create a new split with the temporary file
	if vertical then
		vim.cmd.vsplit(tmp_filename)
	else
		vim.cmd.split(tmp_filename)
	end
	vim.opt_local.bufhidden = 'wipe'
	vim.opt_local.swapfile  = false
	local changerev = string.format('change %s, rev %s', relpath, change_id_short, revision)
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	vim.cmd('diffthis')
	vim.cmd('wincmd p')
	vim.cmd('norm! zR') -- open folds
	----vim.cmd('norm! gg') -- cursor on first line
	----vim.cmd('norm! ]c') -- cursor on first change
	----vim.cmd('norm! zz') -- center view around cursor
	----vim.cmd('wincmd p') -- Return to the new buffer
	local acmd = vim.api.nvim_create_autocmd
	acmd( { "BufUnload" }, {
		pattern = tmp_filename,
		callback = function()
			assert(get_output(tmpdir, { "jj", "abandon", }))
			assert(get_output(tmpdir, { "jj", "workspace", "forget", }))
			assert(get_output(folder, { "rm", "-rf", tmpdir }))
		end,
		once = true })
	acmd( { "WinEnter" }, {
		pattern = tmp_filename,
		callback = function() print(changerev) end, })
	acmd( { "BufWritePost" }, {
		pattern = tmp_filename,
		callback = function()
			assert(get_output(tmpdir, { "jj", "st", }))
			assert(get_output(folder, {
				"jj", "restore", relpath, "--restore-descendants",
				"--from", tmpbase.."@", "--to", change_id }))
		end, })
end

local function setup(opts)
	opts = opts or {} -- Merge user options with defaults
	vim.api.nvim_create_user_command(
		'Jdiffsplit',
		function(opts) Jdiffsplit(false, opts.args) end,
		{ nargs = "?" }
	)
	vim.api.nvim_create_user_command(
		'Jvdiffsplit',
		function(opts) Jdiffsplit(true, opts.args) end,
		{ nargs = "?" }
	)
end

return { setup = setup }
