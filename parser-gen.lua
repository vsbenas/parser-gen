local m = require "lpeglabel"
local peg = require "peg-parser"
local re = require "relabel"

local Predef = { nl = m.P"\n" }
m.locale(Predef)
local any = m.P(1)
Predef.a = Predef.alpha
Predef.c = Predef.cntrl
Predef.d = Predef.digit
Predef.g = Predef.graph
Predef.l = Predef.lower
Predef.p = Predef.punct
Predef.s = Predef.space
Predef.u = Predef.upper
Predef.w = Predef.alnum
Predef.x = Predef.xdigit
Predef.A = any - Predef.a
Predef.C = any - Predef.c
Predef.D = any - Predef.d
Predef.G = any - Predef.g
Predef.L = any - Predef.l
Predef.P = any - Predef.p
Predef.S = any - Predef.s
Predef.U = any - Predef.u
Predef.W = any - Predef.w
Predef.X = any - Predef.x

local mem = {} -- for compiled grammars
local definitions = {}
local tlabels = {}

-- lpeglabel related functions:
local function sync (patt)
	return (-patt * l.P(1))^0 -- skip until we find pattern
end

local Skip = (Predef.space)^0

local function setSpace(patt)
	Skip = patt^0
end

local function token (patt)
	return patt * Skip
end


local function sym (str)
	return token(m.P(str))
end

local function kw (str)
	return token(m.P(str))
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

	return m.type(gr) == "pattern"
end

local function istoken (t)
	return t["token"] == "1"
end

local function isfinal(t)
	if t["t"] or t["nt"] or t["func"] or t["s"] then
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
	elseif t["func"] then
		return "func", t["func"] -- function
	elseif t["s"] then
		return "s", t["s"]
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
		local istokenrule = v["token"] == "1"
		--peg.print_r(v["rule"])
		builder[v["rulename"]] = traverse(v["rule"], istokenrule)
	end
	return builder
end
local function equalcap (s, i, c)
  if type(c) ~= "string" then return nil end
  local e = #c + i
  if s:sub(i, e - 1) == c then return e else return nil end
end


local function applyaction(action, op1, op2, labels)
	if action == "or" then
		if labels then
			return m.Rec(op1,op2,labels)
		else
			return op1 + op2
		end
	elseif action == "and" then
		return op1 * op2
	elseif action == "&" then
		return #op1
	elseif action == "!" then
		return -op1
	elseif action == "+" then
		return op1^1
	elseif action == "*" then
		return op1^0
	elseif action == "?" then
		return op1^-1
	elseif action == "^" then
		return op1^op2
	elseif action == "->" then
		return op1 / op2
	elseif action == "=>" then
		return m.Cmt(op1, op2)
	elseif action == "tcap" then
		return m.Ct(op1)
	elseif action == "gcap" then
		return m.Cg(op1, op2)
	elseif action == "bref" then
		return m.Cmt(m.Cb(op1), equalcap)
	elseif action == "poscap" then
		return m.Cp()
	elseif action == "subcap" then
		return m.Cs(op1)
	elseif action == "scap" then
		return m.C(op1)
	elseif action == "anychar" then
		return m.P(1)
	elseif action == "label" then
		return m.T(op1) -- lpeglabel
	elseif action == "%" then
		if Predef[op1] then
			return Predef[op1]
		end
		return definitions[op1]
	elseif action == "invert" then
		return m.P(1) - op1
	elseif action == "range" then
		return m.R(op1)
	else
		error("Unsupported action '"..action.."'")
	end
end
local function applyclass(t)
	return ''
end
local function applyfinal(action, term, token, tokenrule)
	if action == "t" then
		return m.P(term)
	elseif action == "nt" then
		return m.V(term)
	elseif action == "func" then
		return definitions[term]
	elseif action == "s" then
		return term
	end
end


local function applygrammar(gram)
	return m.P(gram)
end


local function build(ast, defs)
	if defs then
		definitions = defs
	end
	return traverse(ast)
end



function traverse(ast, tokenrule)
	if not ast then
		return nil 
	end
	
	if isfinal(ast) then
	
		local typefn, fn, tok = finalNode(ast)
		return applyfinal(typefn, fn, tok, tokenrule)
		
	elseif isaction(ast) then
	
		local act, op1, op2, labs, ret1, ret2
		act = ast["action"]
		op1 = ast["op1"]
		op2 = ast["op2"]
		labs = ast["condition"] -- recovery operations
		
		if act == "class" then
			return applyclass(op1)
		else
			-- post-order traversal
			ret1 = traverse(op1, tokenrule)
			ret2 = traverse(op2, tokenrule)
			
			return applyaction(act, ret1, ret2, labs)
		end
		
	elseif isgrammar(ast) then
		--
		local g = buildgrammar (ast)
		return applygrammar (g)
		
	else
		peg.print_r(ast)
		error("Unsupported AST")	
	end

end

local function compile (input, defs)
	if iscompiled(input) then return input end
	if not mem[input] then
		-- test for errors
		re.setlabels(labels)
		re.compile(input,defs)
		-- build ast
		ast = peg.pegToAST(input)
		-- rebuild lpeg grammar
		ret = build(ast,defs)
		mem[input] = ret -- store if the user forgets to compile it
	end
	return mem[input]
end

local function setlabels (t)
	return peg.setlabels(t)
end


local function parse (input, grammar, defs, errorfunction)
	if not iscompiled(grammar) then
		cp = compile(grammar,defs)
		grammar = cp
	end
	local r, e, sfail = m.match(grammar,input)
	if not r then
		local line, col = re.calcline(input, #input - #sfail)
		local msg = "Error at line " .. line .. " (col " .. col .. "): "
		local err
		if e == 0 then 
			err = "Syntax error"
		else 
			err = errmsgs[e]
		end
		return r, msg ..  err .. " before '" .. sfail .. "'"
	end
	return r
end

local pg = {compile=compile, setlabels=setlabels, parse=parse}

return pg