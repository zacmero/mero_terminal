th.git = th.git or {}
th.git.unstaged = ui.Style():fg("blue")
th.git.staged = ui.Style():fg("green")
th.git.added = ui.Style():fg("green")
th.git.untracked = ui.Style():fg("yellow")
th.git.deleted = ui.Style():fg("red"):bold()
th.git.updated = ui.Style():fg("magenta")
th.git.clean = ui.Style():fg("green")
th.git.unstaged_sign = "M"
th.git.staged_sign = "M"
th.git.added_sign = "A"
th.git.untracked_sign = "?"
th.git.deleted_sign = "D"
th.git.updated_sign = "U"
th.git.clean_sign = " "

require("git"):setup({
	order = 1500,
})

require("full-border"):setup()

function Linemode:size_and_mtime()
	local time = self._file.cha.mtime
	local res = ""
	if time then
		local t = math.floor(time)
		if os.date("%Y", t) == os.date("%Y") then
			res = os.date("%b %d %H:%M", t)
		else
			res = os.date("%b %d %Y", t)
		end
	end

	local size = self._file:size()
	return ui.Line(string.format("%s | %s", size and ya.readable_size(size) or "-", res))
end
