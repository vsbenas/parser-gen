local lpeg = require "lpeglabel"
local peg = {}
lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space
local alpha = lpeg.alpha


local grammar = P {
	"program",
	program = P(1),
}

--[[
Function: parse(input)

Input: a grammar in PEG format, described in https://github.com/vsbenas/parser-gen

Output: if parsing successful - a table of grammar rules, else - runtime error

Example input: 	"Program <- stmt* / SPACE;
		stmt <- ('a' / 'b')+;
		SPACE <- '';"
Example output: {
	{rulename = "Program", 	rule = {action = "or", op1 = {action = "zero-or-more", op1 = "stmt"}, op2 = "SPACE"}},
	{rulename = "stmt", 	rule = {action = "one-or-more", op1 = {action="or", op1 = "'a'", op2 = 'b'}},
	{rulename = "SPACE",	rule = "''", token=1},

}

The rules are further processed and turned into lpeg compatible format in parser-gen.lua

]]--
function peg.parse(input)
	return input
end

return peg
