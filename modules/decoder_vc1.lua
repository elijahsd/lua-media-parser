
do
	local vc1 = {}

	function vc1:parse()
		self.level = 0
	end

	function vc1:read(sample)
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
		

		self.source:close()
		return result
	end

	return vc1
end
