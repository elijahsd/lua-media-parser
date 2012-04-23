-- Main file
-- Usage lua main.lua <source>

opts = loadfile("options.lua")
if opts then opts() end

dofile("log.lua")
dofile("mediasource.lua")

args = args or {...}
s = args[1]

if not s then
	loge("no uri provided")
	os.exit(1)
end

framesProvider = mediaSource:createSource(s)

for frame in framesProvider:getFrames() do
	frame:dump()
end
