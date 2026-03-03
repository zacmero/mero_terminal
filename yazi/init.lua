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
