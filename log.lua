
local createLog = function(c, level)
	fstr = "function log"
		.. c
		.. "(message) if loglevel >= "
		.. level
		.. " then print(\""
		.. string.upper(c)
		.. " : \" .. message) end end"
	newlog = loadstring(fstr)
	newlog()
end

createLog("e", 0)
createLog("w", 1)
createLog("i", 2)
