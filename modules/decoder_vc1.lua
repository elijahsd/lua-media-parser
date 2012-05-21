
do
	local frameTypes = {
		[0] = " Undef frame",
		      "     I frame",
		      "     P frame",
		      "     B frame",
		      "    BI frame",
		      "     D frame",
		      "   I/I frame",
		      "   I/P frame",
		      "   P/I frame",
		      "   P/P frame",
		      "   B/B frame",
		      "  B/BI frame",
		      "  BI/B frame",
		      " BI/BI frame",
		      " ERROR      ",
		      " ERROR      ",
	}

	local vc1 = {}

	function vc1:parse()
		self.level = 0
	end

	function vc1:read(sample)
		-- returns frame data
		local result = frame:new()
		result.description = "-------"

		self.source:open()
		local extradata = ""
		framepointer, extradata = self.source:read(sample)
		if not framepointer then
			self.source:close()
			return nil
		end

		-- hack: frame is an file descriptor
		result.description = frameTypes[bit.blogic_rshift(bit.band(convertToSize(framepointer:read(1)), 0xF0), 4)]
			.. extradata

		self.source:close()
		return result
	end

	return vc1
end
