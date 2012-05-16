require 'include/ftyp'

do
	local wmv = {}

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
			

				self.source:seek(size - 50)
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
