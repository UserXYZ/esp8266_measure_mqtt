--modified from git source lua_modules/base64/base64_v2.lua
--by Floyd
local moduleName = ...
local M = {}
_G[moduleName] = M

local tab = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	function M.dec(data)
		local a,b = data:gsub('=','A')
		local out = ''
		local l = 0
		for i=1,a:len() do
			l=l+tab:find(a:sub(i,i))-1
			if i%4==0 then
				out=out..string.char(bit.rshift(l,16),bit.band(bit.rshift(l,8),255),bit.band(l,255))
				l=0
			end
			l=bit.lshift(l,6)
		end
		return out:sub(1,-b-1)
	end
return M
