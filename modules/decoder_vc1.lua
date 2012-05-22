require 'include/ftyp'

do
	local frameTypesAdvanced = {
		[0] = "     P frame",
		      "     B frame",
		      "     I frame",
		      "    BI frame",
		      "     skipped",
	}

	local frameTypesNoB = {
		[0] = "     I frame",
		      "     P frame",
	}

	local frameTypesB = {
		[0] = "     P frame",
		      "     I frame",
		      "     B frame",
	}

	local bitreader = dofile("include/bitreader.lua")

	local vc1 = {}

	function vc1:parse()
		self.level = 0
	end

	function vc1:read(sample)
		-- returns frame data
		local result = frame:new()
		result.description = "-------"

		self.source:open()
		local extradata = ""
		framepointer, extradata = self.source:read(sample)
		if not framepointer then
			self.source:close()
			return nil
		end

		-- hack: frame is an file descriptor
		local state = {
			fh = framepointer,
			data = "",
			i = 1,
			bit = 7,
		}
		state.data = framepointer:read(1)

		if not self.source.advanced then
			local toSkip = 2
			if self.source.rangered == 1 then
				toSkip = toSkip + 1
			end
			if self.source.finterpflag == 1 then
				toSkip = toSkip + 1
			end

			bitreader.read_bits(state, toSkip)
			if self.source.maxB > 0 then
				local signs = 0
				while not bitreader.get_bit(state) and signs ~= 2 do
					signs = signs + 1
				end
				result.description = frameTypesB[signs]
			else
				if bitreader.get_bit(state) then
					result.description = frameTypesNoB[1]
				else
					result.description = frameTypesNoB[0]
				end
			end
		else
			-- TODO: Interlaced is not supported yet
			local signs = 0
			while bitreader.get_bit(state) and signs ~= 4 do
				signs = signs + 1
			end
			result.description = frameTypesAdvanced[signs]
		end

		self.source:close()
		return result
	end

	return vc1
end
