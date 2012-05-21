require 'include/ftyp'

do
	local sampleTableParsing = false

	-- moov trak mdia minf stbl

	local mp4 = {
		sampleTable = {
			sampleSizes = {},
			sampleTimes = {},
			sampleDeltaTimes = {},
			chunks = {},
			chunkOffsets = {},
		}
	}

	function mp4:skipBytes(bytes, state)
		state.offset = state.offset + bytes
		return self.source:seek(bytes)
	end

	function mp4:getBytes(bytes, state)
		state.offset = state.offset + bytes
		return self.source:read(bytes)
	end

	function mp4:read(sample)
		-- must be an iterator
		if self.samplesCount
			and self.samplesCount > 0
			and sample >= 0
			and sample < self.samplesCount then

			local samples = 0
			local currentChunk = 0
			local samplesInCurrentChunk = 0
			local extradata = ""
			while samples < sample do
				-- get samples for current chunk
				currentChunk = currentChunk + 1
				for var = 1, table.getn(self.sampleTable.chunks) do
					if self.sampleTable.chunks[var].firstChunk <= currentChunk
						and (var == table.getn(self.sampleTable.chunks)
						or self.sampleTable.chunks[var+1].firstChunk > currentChunk) then

						samplesInCurrentChunk = self.sampleTable.chunks[var].samplesPerChunk
						samples = samples + self.sampleTable.chunks[var].samplesPerChunk
						break
					end
				end
			end
			local sampleInChunk = samplesInCurrentChunk - (samples - sample)
			local chunkOffset = self.sampleTable.chunkOffsets[currentChunk]
			-- sum of all chunk samples
			local offsetInChunk = 0
			local currentChunkSample = samples - samplesInCurrentChunk + 1
			while currentChunkSample < sample do
				offsetInChunk = offsetInChunk + self.sampleTable.sampleSizes[currentChunkSample]
				currentChunkSample = currentChunkSample + 1
			end
			local fullOffset = chunkOffset + offsetInChunk
			self.source:seek(fullOffset)
			if verbose >= 2 then
				logi("offset :" .. tostring(fullOffset))
			end
			extradata = " "
				.. (self.sampleTable.sampleTimes[sample]
					and math.floor(self.sampleTable.sampleTimes[sample])
					or "undefined")
				.. " + "
				.. (self.sampleTable.sampleDeltaTimes[sample] or "0")
				.. " usec "
				.. self.sampleTable.sampleSizes[sample]
				.. " bytes "
			return self.source.fh, extradata
		end
	end

	function mp4:open()
		self.source:open()
	end

	function mp4:close()
		self.source:close()
	end

	function mp4:adjustParseState(parseState)
		for val = 1, parseState.level do
			if not parseState.offsets[val] then
				parseState.offsets[val] = 0
			end
			parseState.offsets[val] = parseState.offsets[val] + parseState.offset
		end
		while parseState.level > 1
			and parseState.offsets[parseState.level] == parseState.sizes[parseState.level] do
			parseState.level = parseState.level - 1
		end
		if parseState.offset < parseState.sizes[parseState.level] then
			parseState.level = parseState.level + 1
			parseState.offsets[parseState.level] = 0
		end
	end

	function mp4:parseChunk(parseState)
		parseState.offset = 0
		local size = convertToSize(self:getBytes(4, parseState))
		parseState.sizes[parseState.level] = size
		local atom = self:getBytes(4, parseState)
		if not size or not atom then
			return false
		end

		if atom ~= "moov"
			and atom ~= "trak"
			and atom ~= "mdia"
			and atom ~= "minf"
			and atom ~= "stbl"
			and atom ~= "stsd"
			and atom ~= "avc1" then

			if atom == "mdhd" then
				self:skipBytes(12, parseState)
				self.timescale = convertToSize(self:getBytes(4, parseState))
				self:skipBytes(8, parseState)
			end
			if atom == "esds" then
				self:skipBytes(4, parseState)
				local esdsType = convertToSize(self:getBytes(1, parseState))
				if (esdsType == 0x03) then
					local nextByte
					repeat
						nextByte = convertToSize(self:getBytes(1, parseState))
					until bit.band(nextByte, 0x80) == 0
					self:skipBytes(2, parseState)

					local esFlags = convertToSize(self:getBytes(1, parseState))
					local streamDependenceFlag = bit.band(esFlags, 0x80)
					local urlFlag = bit.band(esFlags, 0x40)
					local OCRStreamFlag = bit.band(esFlags, 0x20)

					if streamDependenceFlag ~= 0 then
						self:skipBytes(2, parseState)
					end

					if urlFlag ~= 0 then
						local urlLength = convertToSize(self:getBytes(4, parseState))
						self:skipBytes(urlLength + 1, parseState)
					end

					if OCRStreamFlag ~= 0 then
						self:skipBytes(2, parseState)
					end

					esdsType = convertToSize(self:getBytes(1, parseState))
				end
				if (esdsType == 0x04) then
					repeat
						nextByte = convertToSize(self:getBytes(1, parseState))
					until bit.band(nextByte, 0x80) == 0
					local objTypeID = convertToSize(self:getBytes(1, parseState))
					if objTypeID >= 0x60 and objTypeID <= 0x65 then
						self.content = "mpeg2"
					end
				end
				
				self:skipBytes(size - parseState.offset, parseState)
			end
			if atom == "mp4v" then
				self.content = "mpeg4"
				sampleTableParsing = true
			end
			if atom == "avcC" then
				self:skipBytes(4, parseState)
				self.nalLength = 1 + bit.band(convertToSize(self:getBytes(1, parseState)), 3)
			end
			if sampleTableParsing then
				if atom == "stsz" and size > 20 then
					-- sample sizes
					self:skipBytes(8, parseState)
					self.samplesCount = convertToSize(self:getBytes(4, parseState))
					for var = 1, self.samplesCount do
						self.sampleTable.sampleSizes[var] = convertToSize(self:getBytes(4, parseState))
					end
				end
				if atom == "stsc" then
					-- sample to chunks entries
					self:skipBytes(4, parseState)
					local entries = convertToSize(self:getBytes(4, parseState))
					for var = 1, entries do
						self.sampleTable.chunks[var] = {
							firstChunk = convertToSize(self:getBytes(4, parseState)),
							samplesPerChunk = convertToSize(self:getBytes(4, parseState)),
						}
						self:skipBytes(4, parseState)
					end
				end
				if atom == "stco" or atom == "co64" then
					-- sample to chunks offset
					self:skipBytes(4, parseState)
					local entries = convertToSize(self:getBytes(4, parseState))
					for var = 1, entries do
						local offset
						if atom == "stco" then
							offset = convertToSize(self:getBytes(4, parseState))
						else
							offset = convertToSize(self:getBytes(8, parseState))
						end
						self.sampleTable.chunkOffsets[var] = offset
					end
				end
				if atom == "stts" then
					self:skipBytes(4, parseState)
					local entries = convertToSize(self:getBytes(4, parseState))
					local currentTime = 0
					for var = 1, entries do
						local samplesCount = convertToSize(self:getBytes(4, parseState))
						local samplesDuration = convertToSize(self:getBytes(4, parseState))
						local sampleDuration = samplesDuration*1000000/self.timescale
						for s = 1, samplesCount do
							self.sampleTable.sampleTimes[s] = currentTime
							currentTime = currentTime + sampleDuration
						end
					end
				end
				if atom == "ctts" then
					
				end
			end
			self:skipBytes(size - parseState.offset, parseState)
		else
			if atom == "stbl" then
				sampleTableParsing = false
			end

			if atom == "stsd" then
				self:skipBytes(8, parseState)
			end

			if atom == "avc1" then
				self.content = "avc"
				sampleTableParsing = true
				self:skipBytes(78, parseState)
			end
		end

		if verbose >= 1 then
			print(string.rep("  ", parseState.level) .. " " .. tostring(atom) .. " : " .. tostring(size))
		end

		self:adjustParseState(parseState)

		return self:parseChunk(parseState)
	end

	function mp4:parse()
		self.level = 1
		self.source:open()
		self:parseChunk({ level = 1 , offset = 0, offsets = {}, sizes = {}, })
		self.source:close()
	end

	function mp4:dump()
		
	end

	return mp4
end
