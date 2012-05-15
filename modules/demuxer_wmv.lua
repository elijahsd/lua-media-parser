require 'include/ftyp'

do
	local wmv = {}

	local GUIDTypes = {
		-- top GUIDs
		["\048\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "ASF file",
		["\054\038\178\117\142\102\207\017\166\217\000\170\000\098\206\108"] = "data",
		["\144\008\000\051\177\229\207\017\137\244\000\160\201\003\073\203"] = "simple index",
		["\211\041\226\214\218\053\209\017\052\144\000\160\201\003\073\190"] = "index",
		["\248\003\177\254\173\018\100\076\015\132\042\029\047\122\212\140"] = "media object",
		["\208\063\183\060\074\012\003\072\077\149\237\247\182\034\143\012"] = "timecode",
		-- header GUIDs
		
	}

	function wmv:read(sample)
		
	end

	function wmv:getBytes(bytes)
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

	function wmv:parseChunk(level, objectsLeft)
		--[[
			maximum two levels
			if necessary more the objectsLeft values
			for every level must be saved outside the function
		]]--
		if objectsLeft == 0 then
			objectsLeft = nil
			level = level - 1
		end
		
		local parsed = false
		-- 16 bytes is a GUID
		local guid = self.source:read(16)
		if not guid then
			return false
		end

		-- 8 bytes size in le
		local size = self:getBytes(8)

		if verbose >= 2 then
			print(tostring(GUIDTypes[guid]) .. " : " .. size)
		end

		if GUIDTypes[guid] == "data"
			and level == 0 then
			self.source:seek(16)
			-- packets size
			local packetsNumber = self:getBytes(8)
			self.source:seek(2)
			

			self.source:seek(size - 50)
			parsed = true
		end

		if GUIDTypes[guid] == "ASF file"
			and level == 0 then
			local objectsNumber = self:getBytes(4)
			self.source:seek(2)
			local offset = 30
			return self:parseChunk(level + 1, objectsNumber)
--			for var = 1,objectsNumber do
--				self:parseChunk(level + 1)
--			end
--			parsed = true
		end

		if not parsed then
			self.source:seek(size - 24)
		end
		return self:parseChunk(level, objectsLeft and objectsLeft - 1)
	end

	function wmv:parse()
		self.level = 1
		self.source:open()
		self:parseChunk(0)
		self.source:close()
	end

	return wmv
end
