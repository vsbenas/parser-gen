local lpeg = require "lpeglabel"
local relabel = require "relabel"
--local lpeglabel = require "lpeglabel"
lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space
local alpha = lpeg.alpha

local parser = {}

function parser.parse(input,grammar,errorfunction)
	return input
end

return parser