require 'include/ftyp'

do
	local wmv = {
		streams = {},
		codecs = {},
		frames = {},
		framescount = 1,
	}

	local codecTypes = {"video", "audio"}

	local GUIDTypes = {
		-- top GUIDs
		["\048\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "header",
		["\054\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "data",
		["\144\008\000\051\177\229\207\017\137\244\000\160\201\003\073\203"] = "simple index",
		["\211\041\226\214\218\053\209\017\052\144\000\160\201\003\073\190"] = "index",
		["\248\003\177\254\173\018\100\076\015\132\042\029\047\122\212\140"] = "media object index",
		["\208\063\183\060\074\012\003\072\077\149\237\247\182\034\143\012"] = "timecode index",
		-- header GUIDs
		["\161\220\171\140\071\169\207\017\142\228\000\192\012\032\083\101"] = "file properties",
		["\145\007\220\183\183\169\207\017\142\230\000\192\012\032\083\101"] = "stream properties",
		["\181\003\191\095\046\169\207\017\142\227\000\192\012\032\083\101"] = "header extension",
		["\064\082\209\134\029\049\208\017\163\164\000\160\201\003\072\246"] = "codec list",
		["\048\026\251\030\098\011\208\017\163\155\000\160\201\003\072\246"] = "script command",
		["\001\205\135\244\081\169\207\017\142\230\000\192\012\032\083\101"] = "marker",
		["\220\041\226\214\218\053\209\017\144\052\000\160\201\003\073\190"] = "bitrate mutual exclusion",
		["\053\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "error correction",
		["\051\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "content description",
		["\064\164\208\210\007\227\210\017\151\240\000\160\201\094\168\080"] = "extended content description",
		["\250\179\017\034\035\189\210\017\180\183\000\160\201\085\252\110"] = "content branding",
		["\206\117\248\123\141\070\209\017\141\130\000\096\151\201\162\178"] = "stream bitrate properties",
		["\251\179\017\034\035\189\210\017\180\183\000\160\201\085\252\110"] = "content encryption",
		["\020\230\138\041\034\038\023\076\185\053\218\224\126\233\040\156"] = "extended content encryption",
		["\252\179\017\034\035\189\210\017\180\183\000\160\201\085\252\110"] = "digital signature",
		["\116\212\006\024\223\202\009\069\164\186\154\171\203\150\170\232"] = "padding",
		-- stream type GUIDs
		["\064\158\105\248\077\091\207\017\168\253\000\128\095\092\068\043"] = "audio",
		["\192\239\025\188\077\091\207\017\168\253\000\128\095\092\068\043"] = "video",
		["\192\207\218\089\230\089\208\017\163\172\000\160\201\003\072\246"] = "command",
		["\000\225\027\182\078\091\207\017\168\253\000\128\095\092\068\043"] = "jfif",
		["\224\125\144\053\021\228\207\017\169\023\000\128\095\092\068\043"] = "degradable jpeg",
		["\044\034\189\145\028\242\122\073\139\109\090\168\107\252\001\133"] = "file transfer",
		["\226\101\251\058\239\071\242\064\172\044\112\169\013\113\211\067"] = "binary",
	}

	function wmv:read(sample)
		
	end

	function wmv:getBytes(bytes)
		if bytes == 0 then
			return 0
		end
		local numStr = ""
		for val = 1,bytes do
			numStr = self.source:read(1) .. numStr
		end
		return convertToSize(numStr)
	end

	function wmv:open()
		self.source:open()
	end

	function wmv:close()
		self.source:close()
	end

	function wmv:parseChunk(level, recursive)
		local parsed = false
		-- 16 bytes is a GUID
		local guid = self.source:read(16)
		if not guid then
			return false
		end

		-- 8 bytes size in le
		local size = self:getBytes(8)

		if verbose >= 2 then
			print(tostring(GUIDTypes[guid]) .. " : " .. tostring(level) .. " : " .. size)
		end

		if level == 0 then
			if GUIDTypes[guid] == "data" then
				self.source:seek(16)
				-- packets size
				local packetsNumber = self:getBytes(8)
				self.source:seek(2)

				-- parse the packet:
				for val = 1, packetsNumber do
					-- error correction
					local flags = self:getBytes(1)
					local errorCorrectionDataLength = 0
					if bit.band(flags, 0x80) == 0x80 then
						-- error correction present
						errorCorrectionDataLength = bit.band(flags, 0x0F)
						self.source:seek(errorCorrectionDataLength)
					end

					if bit.band(flags, 0x10) == 0 then
						-- opaque data not present
						local multiple = false
						local lengthTypeFlags = self:getBytes(1)
						local propertyFlags = self:getBytes(1)
						if bit.band(lengthTypeFlags, 0x01) == 0x01 then
							multiple = true
						end

						local sequenceSizeType = bit.blogic_rshift(bit.band(lengthTypeFlags, 0x06), 1)
						local paddingSizeType = bit.blogic_rshift(bit.band(lengthTypeFlags, 0x18), 3)
						local packetSizeType = bit.blogic_rshift(bit.band(lengthTypeFlags, 0x60), 5)
						sequenceSizeType = sequenceSizeType == 3
							and 4 or sequenceSizeType
						paddingSizeType = paddingSizeType == 3
							and 4 or paddingSizeType
						packetSizeType = packetSizeType == 3
							and 4 or packetSizeType
						local packetLength = self:getBytes(packetSizeType)
						local sequence = self:getBytes(sequenceSizeType)
						local paddingLength = self:getBytes(paddingSizeType)

						local replicatedDataLengthType = bit.band(propertyFlags, 0x03)
						local offsetIntoMediaObjectLengthType = bit.blogic_rshift(bit.band(propertyFlags, 0x0C), 2)
						local mediaObjectNumberLengthType = bit.blogic_rshift(bit.band(propertyFlags, 0x30), 4)
						local streamNumberLengthType = bit.blogic_rshift(bit.band(propertyFlags, 0xC0), 6)
						replicatedDataLengthType = replicatedDataLengthType == 3
							and 4 or replicatedDataLengthType
						offsetIntoMediaObjectLengthType = offsetIntoMediaObjectLengthType == 3
							and 4 or offsetIntoMediaObjectLengthType
						mediaObjectNumberLengthType = mediaObjectNumberLengthType == 3
							and 4 or mediaObjectNumberLengthType
						streamNumberLengthType = streamNumberLengthType == 3
							and 4 or streamNumberLengthType

						local sendTime = self:getBytes(4)
						local duration = self:getBytes(2)

						-- start payload data
						local offset = 1
							+ errorCorrectionDataLength
							+ 2
							+ packetSizeType
							+ sequenceSizeType
							+ paddingSizeType
							+ 4 + 2
							if packetLength == 0 then
								packetLength = self.minPacket
							end

						local compressedPayload = false
						if multiple then
							local payloadFlags = self:getBytes(1)
							local payloadsNumber = bit.band(payloadFlags, 0x3F)
							local payloadLengthType = bit.blogic_rshift(bit.band(payloadFlags, 0xC0), 6)
							payloadLengthType = payloadLengthType == 3
								and 4 or payloadLengthType
							offset = offset + 1

							for payloads = 1, payloadsNumber do
								local streamNumber = self:getBytes(1)
								streamNumber = bit.band(streamNumber, 0x7F)
								local mediaObjectNumber = self:getBytes(mediaObjectNumberLengthType)
								local offsetIntoMediaObject = self:getBytes(offsetIntoMediaObjectLengthType)
								local replicatedDataLength = self:getBytes(replicatedDataLengthType)
								local presentationTime = 0

								-- replicated data
								if replicatedDataLength == 1 then
									compressedPayload = true
								end

								if compressedPayload then
									presentationTime = offsetIntoMediaObject
									offsetIntoMediaObject = 0
									local presentationTimeDelta = self:getBytes(1)
									offset = offset + 1
								else
									self.source:seek(replicatedDataLength)
									offset = offset + replicatedDataLength
								end

								local payloadLength = self:getBytes(payloadLengthType)

								-- payload data
								if compressedPayload then
									local subOffset = 0
									while subOffset < payloadLength do
										local subPayloadData = self:getBytes(1)
										subOffset = subOffset + 1
										-- GET DATA HERE
										if streamNumber == self.streams.video
											and offsetIntoMediaObject == 0 then
											self.frames[self.framescount] = self.source:seek()
											self.framescount = self.framescount + 1
										end
										self.source:seek(subPayloadData)
										subOffset = subOffset + subPayloadData
									end
								else
									-- GET DATA HERE
									if streamNumber == self.streams.video
										and offsetIntoMediaObject == 0 then
										self.frames[self.framescount] = self.source:seek()
										self.framescount = self.framescount + 1
									end
									self.source:seek(payloadLength)
								end

								if streamNumber == self.streams.video
									and verbose >= 2 then
									print("packet size : "
										.. tostring(packetLength)
										.. " payload data size : "
										.. tostring(payloadLength)
										.. " compressed : "
										.. tostring(compressedPayload))
								end

								offset = offset
									+ 1
									+ mediaObjectNumberLengthType
									+ offsetIntoMediaObjectLengthType
									+ replicatedDataLengthType
									+ payloadLengthType
									+ payloadLength
							end
						else
							local streamNumber = self:getBytes(1)
							streamNumber = bit.band(streamNumber, 0x7F)
							local mediaObjectNumber = self:getBytes(mediaObjectNumberLengthType)
							local offsetIntoMediaObject = self:getBytes(offsetIntoMediaObjectLengthType)
							local replicatedDataLength = self:getBytes(replicatedDataLengthType)
							local presentationTime = 0

							-- replicated data
							if replicatedDataLength == 1 then
								compressedPayload = true
							end

							if compressedPayload then
								presentationTime = offsetIntoMediaObject
								local presentationTimeDelta = self:getBytes(1)
								offset = offset + 1
							else
								self.source:seek(replicatedDataLength)
								offset = offset + replicatedDataLength
							end

							offset = offset
								+ 1
								+ mediaObjectNumberLengthType
								+ offsetIntoMediaObjectLengthType
								+ replicatedDataLengthType

							-- payload data
							if compressedPayload then
								local subOffset = 0
								while subOffset < (packetLength - offset - paddingLength) do
									local subPayloadData = self:getBytes(1)
									subOffset = subOffset + 1
									-- GET DATA HERE
									if streamNumber == self.streams.video
										and offsetIntoMediaObject == 0 then
										self.frames[self.framescount] = self.source:seek()
										self.framescount = self.framescount + 1
									end
									self.source:seek(subPayloadData)
									subOffset = subOffset + subPayloadData
								end
								offset = offset + subOffset
							else
								-- GET DATA HERE
								if streamNumber == self.streams.video
									and offsetIntoMediaObject == 0 then
									self.frames[self.framescount] = self.source:seek()
									self.framescount = self.framescount + 1
								end
							end

							if streamNumber == self.streams.video
								and verbose >= 2 then
								print("packet size : "
									.. tostring(packetLength)
									.. " payload data size : "
									.. tostring(packetLength - offset - replicatedDataLength)
									.. " compressed : "
									.. tostring(compressedPayload))
							end
						end
						self.source:seek(packetLength - offset)
					else
						loge("opaque data")
						return false
					end
				end
				parsed = true
			end

			if GUIDTypes[guid] == "header" then
				local objectsNumber = self:getBytes(4)
				self.source:seek(2)
				for var = 1,objectsNumber do
					self:parseChunk(level + 1, false)
				end
				parsed = true
			end
		end

		if level == 1 then
			if GUIDTypes[guid] == "stream properties" then
				local streamType = self.source:read(16)
				self.source:seek(32)

				local flags = self:getBytes(2)
				local streamNumber = bit.band(flags, 0x7F)

				if verbose >= 1 then
					print("stream type = " .. GUIDTypes[streamType] .. " : " .. tostring(streamNumber))
				end

				self.streams[
					GUIDTypes[streamType]
					] = streamNumber

				self.source:seek(size - 74)
				parsed = true
			end

			if GUIDTypes[guid] == "codec list" then
				self.source:seek(16)

				local entries = self:getBytes(4)
				for val = 1,entries do
					local codecType = self:getBytes(2)
					local codecNameLength = self:getBytes(2)
					local codecNameWChar = self.source:read(codecNameLength*2)
					local codecName = ""
					for ind = 1, codecNameLength*2 do
						if string.byte(codecNameWChar, ind) ~= 0 then
							codecName = codecName .. string.char(string.byte(codecNameWChar, ind))
						end
					end
					if verbose >= 1 then
						logi(codecName)
					end

					self.codecs[
						codecTypes[codecType] or 0
					] = codecName

					self.content = "vc1"

					self.source:seek(self:getBytes(2)*2)
					self.source:seek(self:getBytes(2))
				end

				parsed = true
			end

			if GUIDTypes[guid] == "file properties" then
				self.source:seek(68)
				self.minPacket = self:getBytes(4)
				if verbose >= 2 then
					print("minimum packet length : " .. tostring(self.minPacket))
				end
				self.source:seek(8)
				parsed = true
			end
		end

		if not parsed then
			self.source:seek(size - 24)
		end

		if recursive then
			return self:parseChunk(level, true)
		end
	end

	function wmv:parse()
		self.level = 1
		self.source:open()
		self:parseChunk(0, true)
		self.source:close()
	end

	return wmv
end
