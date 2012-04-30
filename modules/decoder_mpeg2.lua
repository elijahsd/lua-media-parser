
do
	local mpeg2 = {}

	function mpeg2:parse()
		self.level = 0
	end

	function mpeg2:read(sample)
		-- returns frame data
		local result = frame:new()
		result.description = "-------"

		self.source:open()
		framepointer = self.source:read(sample)
		if not framepointer then
			self.source:close()
			return nil
		end

		-- hack: frame is an file descriptor
		local header = framepointer:read(4)
		local expectPIC = "\000\000\001\000"
		local expectSEQ = "\000\000\001\179"
		if header == expectPIC then
			local frametype = convertToSize(framepointer:read(2))
			frametype = bit.band(frametype, 56)
			if frametype == 8 then
				result.description = "  I frame"
			end
			if frametype == 16 then
				result.description = "  P frame"
			end
			if frametype == 24 then
				result.description = "  B frame"
			end
			if frametype == 32 then
				result.description = "  D frame"
			end
		else
			if header == expectSEQ then
				local sequenceData0 = convertToSize(framepointer:read(1))
				local sequenceData1 = convertToSize(framepointer:read(1))
				local sequenceData2 = convertToSize(framepointer:read(1))
				local width = bit.bor(
					bit.blshift(sequenceData0, 4),
					bit.blogic_rshift(sequenceData1, 4))
				local height = bit.bor(
					bit.blshift(bit.band(sequenceData1, 0x0F), 8),
					sequenceData2)
				result.description = " SEQ: "
					.. width
					.. "x"
					.. height
			end
		end

		self.source:close()
		return result
	end

	return mpeg2
end
