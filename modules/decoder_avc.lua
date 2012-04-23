require 'include/bit'
require 'include/ftyp'

do
	local avc = {}

	function avc:parse()
		self.level = 0
	end

	function avc:read(sample)
		-- returns frame data
		local result = frame:new()
		result.description = "No data"

		self.source:open()
		framepointer = self.source:read(sample)
		if not framepointer then
			self.source:close()
			return nil
		end

		-- hack: framepointer is an file descriptor
		framepointer:read(self.source.nalLength or 4)
		local nalType = convertToSize(framepointer:read(1))
		nalType = bit.band(nalType, 0x1F)
		if nalType >= 1 and nalType <= 5 then
			local bitreader = dofile("include/bitreader.lua")
			local state = {
				fh = framepointer,
				data = "",
				i = 1,
				bit = 8,
			}
			state.data = framepointer:read(1)
			bitreader.get_ue_golomb(state)
			local golomb = bitreader.get_ue_golomb(state)
			if golomb == 2
				or golomb == 4
				or golomb == 7
				or golomb == 9 then
				result.description = "I frame"
			end
			if golomb == 0
				or golomb == 3
				or golomb == 5
				or golomb == 8 then
				result.description = "P frame"
			end
			if golomb == 1
				or golomb == 6 then
				result.description = "B frame"
			end
		end
		self.source:close()
		return result
	end

	function avc:getFrames()
		local currentSample = 0
		return function()
			currentSample = currentSample + 1
			return self:read(currentSample)
		end
	end

	return avc
end
