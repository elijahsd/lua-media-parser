-- cloned from lua-mkv project

local B = {}

-- local ord    = string.byte
local ord    = function(state)
	if state.i > string.len(state.data) then
		state.data = state.data .. state.fh:read(1)
	end
	return string.byte(state.data, state.i, state.i)
end
local ceil   = math.ceil

B.get_bit = function (state)
	-- local byte = ord(state.data, state.i, state.i)
	local byte = ord(state)
	if byte ~= nil then
		local v = (byte%(2^(state.bit+1)) >= 2^state.bit)
		if state.bit == 0 then
			state.i = state.i + 1
			state.bit = 7
		else
			state.bit = state.bit - 1
		end
		return v, state
	end
	return nil
end

B.iterator = function (string)
	return B.get_bit, {data=string, i=1, bit=7}
end

B.get_golomb = function (state)
	local nrbits, rb_v, rb_c, nr = nil, 0, 0, 0
	while true do
		local v = B.get_bit(state)
		if v == nil then break end
		if nrbits ~= nil then
			rb_c = rb_c + 1
			if v then
				rb_v = rb_v + 2^(nrbits - rb_c)
			end
		else
			if v then
				nrbits = nr
			else
				nr = nr + 1
			end
		end
		if nrbits ~= nil and rb_c == nrbits then
			return 2^nrbits - 1 + rb_v, state
		end
	end
	return nil
end

B.read_bits = function (state, nrbits)
	local s = 0
	for i=0,nrbits-1 do
		local v = B.get_bit(state)
		if v == nil then return nil end
			if v then
				s = s + 2^(nrbits - i - 1)
			end
		end
	return s
end

B.get_ue_golomb = B.get_golomb

B.get_se_golomb = function(state)
	local v = B.get_golomb(state)
	return -1^(v+1)* ceil(v/2)
end

return B
