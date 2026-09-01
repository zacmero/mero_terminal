local M = {}

function M:peek(job)
	local child, err = Command("chafa")
		:arg({
			"-f",
			"symbols",
			"--size",
			string.format("%dx%d", math.max(10, job.area.w), math.max(5, job.area.h)),
			tostring(job.file.url),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return ya.preview_widget(job, ui.Text(string.format("Failed to spawn chafa: %s", err or "unknown")):area(job.area):wrap(ui.Wrap.YES))
	end

	local output, err = child:wait_with_output()
	if not output then
		return ya.preview_widget(job, ui.Text(string.format("Failed to run chafa: %s", err or "unknown")):area(job.area):wrap(ui.Wrap.YES))
	elseif output.status.code ~= 0 then
		return ya.preview_widget(job, ui.Text(string.format("Chafa error (%d): %s", output.status.code, output.stderr)):area(job.area):wrap(ui.Wrap.YES))
	end

	local text = ui.Text.parse(output.stdout)
	ya.preview_widget(job, text:area(job.area))
end

function M:seek() end

return M
