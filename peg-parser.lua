local lpeg = require "lpeglabel"
local peg = {}
lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space
local alpha = lpeg.alpha


local grammar = P (1)

function peg.parse(input)
	return input
end

return peg