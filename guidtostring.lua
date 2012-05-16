
require 'include/hex'

local guids = {
	
}

for i,v in ipairs(guids) do
	local result = string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 7, 8))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 5, 6))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 3, 4))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 1, 2))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 11, 12))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 9, 10))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 15, 16))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 13, 14))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 17, 18))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 19, 20))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 21, 22))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 23, 24))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 25, 26))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 27, 28))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 29, 30))))
	.. string.format("\\%3d", hex.to_dec("0x" .. tostring(string.sub(v, 31, 32))))
	print(string.gsub(result, "\ ", "0"))
end
