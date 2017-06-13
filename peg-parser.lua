local lpeg = require "lpeg-funcs"
local peg = {}

local P, V = lpeg.P, lpeg.V
local T = lpeg.T -- lpeglabel

local grammar = lpeg.P {
	"G",
	G = lpeg.Skip * Rule^1,
	
}

--[[
Function: parse(input)

Input: a grammar in PEG format, described in https://github.com/vsbenas/parser-gen

Output: if parsing successful - a table of grammar rules, else - runtime error

Example input: "Program <- stmt* / SPACE;
				stmt <- ('a' / 'b')+;
				SPACE <- '';"
Example output: {
	{rulename = "Program", 	rule = {action = "or", op1 = {action = "zero-or-more", op1 = "stmt"}, op2 = "SPACE"}},
	{rulename = "stmt", 	rule = {action = "one-or-more", op1 = {action="or", op1 = "'a'", op2 = 'b'}},
	{rulename = "SPACE",	rule = "''", token=1},

}

The rules are further processed and turned into lpeg compatible format in parser-gen.lua

]]--
function peg.pegToAST(input)
	return grammar:match(input)
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	lpeg.print_r(peg.pegToAST(arg[1]));
end

return peg