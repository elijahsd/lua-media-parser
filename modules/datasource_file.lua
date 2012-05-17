
do
	local file = {}

	function file:open()
		self.fh = io.open(self.uri, "rb")
		return self.fh
	end

	function file:close()
		if self.fh then
			self.fh:close()
		end
	end

	function file:read(bytes)
		if self.fh and bytes ~= 0  then
			return self.fh:read(bytes)
		end
	end

	function file:seek(bytes)
		if self.fh then
			if bytes and bytes ~= 0 then
				self:read(bytes)
			else
				return self.fh:seek()
			end
		end
	end

	function file:parse()
		self.level = 3
		if string.find(self.uri, "%.%w+$") then
			self.content = string.sub(string.sub(self.uri, string.find(self.uri, "%.%w+$")), 2)
		end
	end

	return file
end
