require 'include/hex'

-- frame begin
frame = {
	description = "",
	frametype = 0,
}

function frame:dump()
	print(self.description)
end

function frame:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
-- frame end

function convertToSize(size)
	if (not size) or (string.len(size) == 0) then
		return false
	end
	local sizestr = ""
	for var = 1, string.len(size) do
		sizestr = sizestr .. string.format("%02X", string.byte(size, var))
	end
	return hex.to_dec("0x" .. sizestr)
end
