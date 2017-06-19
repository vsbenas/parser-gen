local lpeg = require "lpeglabel"
local peg = require "peg-parser"

lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space
local alpha = lpeg.alpha


local mem = {} -- for compiled grammars


-- lpeglabel related functions:
local function sync (patt)
	return (-patt * P(1))^0 -- skip until we find pattern
end

local Skip = (space)^0

local function setSpace(patt)
	Skip = patt^0
end

local function token (patt)
	return patt * Skip
end


local function sym (str)
	return token(P(str))
end

local function kw (str)
	return lpeg.token(P(str))
end


local function try (patt, err)
	return patt + T(err)
end

local function throws (patt,err) -- if pattern is matched throw error
	return patt * T(err)
end

-- end

-- functions used by the tool

local function iscompiled (gr)
	return lpeg.type(gr) == "pattern"
end

local function istoken (t)
	return t["token"] == "1"
end

local function finalNode (t)
	if t["t"] then
		return "t" -- terminal
	elseif t["nt"]
		return "nt" -- nonterminal
	elseif t["r"]
		return "r" -- range
	elseif t["func"]
		return "func" -- function
end



local function traverse(ast)
	if not ast then return nil
	fn = finalNode(ast)
	if(
	else
		act = ast["action"]
		op1 = ast["op1"]
		op2 = ast["op2"]
		labs = ast["condition"] -- recovery operations
		ret1 = traverse(op1)
		ret2 = traverse(op2)
		apply(act, op1, op2, labs)
	end
end

-- lpeg functions

local function apply(action, op1, op2, labels)
	

end


local function buildgrammar(ast, defs)
	
end




local function compile (input, defs)
	if iscompiled(input) then return input end
	if not mem[input] then
		-- test for errors
		re.compile(input,defs)
		-- build ast
		ast = peg.pegToAST(input)
		-- rebuild lpeg grammar
		ret = buildgrammar(ast,defs)
		mem[input] = ret -- store if the user forgets to compile it
	end
	return mem[input]
end

local tlabels = {}

local function setlabels (t)
	for key,value in pairs(t) do
		if (not type(key) == "number") or key < 1 or key > 255 then
			error("Invalid error label key '"..key.."'. Error label keys must be integers from 1 to 255")
		end
		if not type(value) == "string" then
			error("Invalid error label value. Error label values must be strings.")
		end
	end
	tlabels = t
end



local function parse (input, grammar, errorfunction)
	if not iscompiled(grammar) then
		cp = compile(grammar) -- cannot use definitions here
		grammar = cp
	end
	
	return input
end

local pg = {}

return pg