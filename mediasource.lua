
sourceLevels = {
	[0] = "decoder",
	"demuxer",
	"depacketizer",
	"datasource",
}

mediaSource = {
	level = 0,    -- level from sourceLevels
	uri = "",     -- uri
	content = "", -- content of this source
	source = nil, -- mediasource from lower level
}

-- MediaSource API begin
function mediaSource:open() end
function mediaSource:close() end
function mediaSource:read() end
function mediaSource:seek() end

function mediaSource:getFrames()
	logw("dummy getFrames")
	return function() end
end

function mediaSource:parse()
	self.level = 3
	s, f = string.find(self.uri, "^.*://")
	if (s and f) then
		self.content = string.sub(string.sub(self.uri, string.find(self.uri, "^.*://")), 1, -4)
	else
		self.content = "file"
	end
	return true
end
-- MediaSource API end

function mediaSource:new(o, s)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.uri = s
	return o
end

function mediaSource:findModule(level, content)
	while level >= 0 do
		local f = loadfile("modules/" .. sourceLevels[level] .. "_" .. content .. ".lua")
		if not f then
			logw("no module found : " .. sourceLevels[level] .. "_" .. content .. ".lua")
			level = level - 1
		else
			logi("loading : " .. sourceLevels[level] .. "_" .. content)
			return f
		end
	end
end

function mediaSource:createSource(filename)
	local state = {}
	local function getSource()
		local function iterator(state, source)
			state.source = source
			source:parse()
			local f = (source.level ~= 0)
				and source.content and string.len(source.content) > 0
				and mediaSource:findModule(source.level, source.content)
			if not f then
				return nil
			end
			local newsource = f()
			newsource = newsource
				and newsource.parse
				and mediaSource:new(newsource, filename)
			if not newsource then
				return nil
			end
			newsource.source, source = source, newsource
			return source
		end
		return iterator, state, mediaSource:new(nil, filename)
	end
	for source in getSource() do end
	return state.source
end
