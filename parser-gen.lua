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

local function isfinal(t)
	if t["t"] or t["nt"] or t["r"] or t["func"] then
		return true
	else
		return false
	end
end

local function isaction(t)
	if t["action"] then
		return true
	else
		return false
	end
end


local function isrule(t)
	if t["rulename"] then
		return true
	else
		return false
	end
end
local function isgrammar(t)
	if type(t) == "table" then
		return isrule(t[1])
	else
		return false
	end
end

local function finalNode (t)
	if t["t"] then
		return "t", t["t"] -- terminal
	elseif t["nt"] then
		return "nt", t["nt"], istoken(t) -- nonterminal
	elseif t["r"] then
		return "r", t["r"] -- range
	elseif t["func"] then
		return "func", t["func"] -- function
	else
		return nil
	end
end

local function buildgrammar (ast)
	local builder = {}
	local initial
	for i, v in ipairs(ast) do
		if i == 1 then
			initial = v["rulename"]
			table.insert(builder, initial)
		end
		builder[v["rulename"]] = traverse(v["rule"])
	end
	return builder
end

-- lpeg functions

local function applyaction(action, op1, op2, labels)
	if op2 then
		return action.."("..op1..","..op2..")"
	else
		return action.."("..op1..")"
	end
end
local function applyfinal(action, term, token)
	if token then
		return action.."("..term.." `token`)"
	else
	return action.."("..term..")"
	end
end
local function applygrammar(gram)
	peg.print_r(gram)
end
local function build(ast, defs)
	
end


function traverse(ast)
	if not ast then
		return nil 
	end
	
	if isfinal(ast) then
	
		local typefn, fn, tok = finalNode(ast)
		return applyfinal(typefn, fn, tok)
		
	elseif isaction(ast) then
	
		local act, op1, op2, labs, ret1, ret2
		act = ast["action"]
		op1 = ast["op1"]
		op2 = ast["op2"]
		labs = ast["condition"] -- recovery operations
		
		-- post-order traversal
		ret1 = traverse(op1)
		ret2 = traverse(op2)
		
		return applyaction(act, ret1, ret2, labs)
		
	elseif isgrammar(ast) then
		
		local g = buildgrammar (ast)
		return applygrammar (g)
		
	else
		error("Unsupported AST")	
	end
end

print(traverse({
	{rulename = "Program",	rule = {action = "or", op1 = {action = "*", op1 = {nt = "stmt"}}, op2 = {nt = "SPACE", token="1"}}},
	{rulename = "stmt", 	rule = {action = "+", op1 = {action="or", op1 = {t = "a"}, op2 = {t = "b"}}}},
	{rulename = "SPACE",	rule = {t=""}, token=1},
}))


local function compile (input, defs)
	if iscompiled(input) then return input end
	if not mem[input] then
		-- test for errors
		re.compile(input,defs)
		-- build ast
		ast = peg.pegToAST(input)
		-- rebuild lpeg grammar
		ret = build(ast,defs)
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