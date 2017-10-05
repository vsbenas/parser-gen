local m = require "lpeglabel"
local peg = require "peg-parser"
local eg = require "errorgen"
local s = require "stack"

-- create stack for tokens inside captures. nil - not inside capture, 0 - inside capture, 1 - token found inside capture
local tokenstack = s.Stack:Create()



local subject, errors, errorfunc

-- Lua 5.1 compatibility:
local unpack = unpack or table.unpack


local Predef = { nl = m.P"\n", cr = m.P"\r", tab = m.P"\t" }


local mem = {} -- for compiled grammars

local function updatelocale()
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
	mem = {}
end

updatelocale()

local definitions = {}
local tlabels = {}
local totallabels = 0
local tlabelnames = {} -- reverse table
local tdescs = {}
local trecs = {} -- recovery for each error


local function defaultsync(patt)
	return (m.P(1)^-1) * (-patt * m.P(1))^0
end

-- TODO: store these variables for each grammar
local SKIP = (Predef.space + Predef.nl)
local SYNC = defaultsync(SKIP)


local recovery = true
local skipspaces = true
local buildast = true

local function sync (patt)
	return patt --(-patt * m.P(1))^0 * patt^0 -- skip until we find the pattern and consume it(if we do)
end


local function pattspaces (patt)
	if skipspaces then
		return patt * SKIP^0
	else
		return patt
	end
end

local function token (patt)
	local incapture = tokenstack:pop() -- returns nil if not in capture
	if not incapture then
		return pattspaces(patt)
	end
	tokenstack:push(1)
	return patt
end




-- functions used by the tool

local function iscompiled (gr)
	return m.type(gr) == "pattern"
end

local function istoken (t)
	return t["token"] == "1"
end

local function isfinal(t)
	return t["t"] or t["nt"] or t["func"] or t["s"] or t["num"]
end

local function isaction(t)
	return t["action"]
end


local function isrule(t)
	return t and t["rulename"]
end
local function isgrammar(t)
	if type(t) == "table" and not(t["action"]) then
		return isrule(t[1])
	end
	return false
end

local function iscapture (action)
	return action == "=>" or action == "gcap" or action == "scap" or action == "subcap" or action == "poscap"
end

local function finalNode (t)
	if t["t"] then
		return"t",t["t"] -- terminal
	elseif t["nt"] then
		return "nt", t["nt"], istoken(t) -- nonterminal
	elseif t["func"] then
		return "func", t["func"] -- function
	elseif t["s"] then
		return "s", t["s"]
	elseif t["num"] then
		return "num", t["num"]
	end
	return nil
end
local bg = {} -- local variable to keep global function buildgrammar


local function addspaces (caps)
	local hastoken = tokenstack:pop()
	if hastoken == 1 then
		return pattspaces(caps)
	end
	return caps
end

local function applyaction(action, op1, op2, labels,tokenrule)
	if action == "or" then
		if labels then -- labels = {{s="errName"},{s="errName2"}}
			for i, v in ipairs(labels) do
				local labname = v["s"]
				local lab = tlabels[labname]
				if not lab then
					error("Label '"..labname.."' undefined")
				end
				labels[i] = lab
			end
			return m.Rec(op1,op2,unpack(labels))
		end
		return op1 + op2
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
	elseif action == "^LABEL" then
		local lab = tlabels[op2]
		if not lab then
			error("Label '"..op2.."' unspecified using setlabels()")
		end
		return op1 + m.T(lab)
	elseif action == "->" then
		return op1 / op2
	-- in captures we add SPACES^0
	elseif action == "=>" then
		return addspaces(m.Cmt(op1,op2))
	elseif action == "tcap" then
		return m.Ct(op1) -- nospaces
	elseif action == "gcap" then
		return addspaces(m.Cg(op1, op2))
	elseif action == "bref" then
		return m.Cb(op1) --m.Cmt(m.Cb(op1), equalcap) -- do we need to add spaces to bcap?
	elseif action == "poscap" then
		return addspaces(m.Cp())
	elseif action == "subcap" then
		return addspaces(m.Cs(op1))
	elseif action == "scap" then
		return addspaces(m.C(op1)) 
	elseif action == "anychar" then
		if buildast and not tokenrule then
			return m.C(m.P(1))
		end
		return m.P(1)
	elseif action == "label" then
		local lab = tlabels[op1]
		if not lab then
			error("Label '"..op1.."' unspecified using setlabels()")
		end
		return m.T(lab) -- lpeglabel
	elseif action == "%" then
		if definitions[op1] then
			return definitions[op1]
		elseif Predef[op1] then
			return Predef[op1]
		else
			error("Definition for '%"..op1.."' unspecified(use second parameter of parser-gen.compile())")
		end
	elseif action == "invert" then
		return m.P(1) - op1
	elseif action == "range" then
		local res = m.R(op1)
		if not tokenrule then
			if buildast then
				res = m.C(res)
			end
			res = token(res)
		end
		return res
	else
		error("Unsupported action '"..action.."'")
	end
end

local function applyfinal(action, term, tokenterm, tokenrule)

	if action == "t" then
		local res = m.P(term)
		if not tokenrule then
			if buildast then
				res = m.C(res)
			end
			if skipspaces then
				res = token(res)
			end
		end
		return res
	elseif action == "nt" then
		if skipspaces and tokenterm and (not tokenrule) then
			return token(m.V(term))
		else
			return m.V(term)
		end
	elseif action == "func" then
		if definitions[term] then
			return definitions[term]
		else
			error("Definition for function '"..term.."' unspecified (use second parameter of parser-gen.compile())")
		end
	elseif action == "s" then -- simple string
		return term
	elseif action == "num" then -- numbered string
		return tonumber(term)
	end
end


local function applygrammar(gram)
	return m.P(gram)
end

local function traverse (ast, tokenrule)
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
		
		-- post-order traversal
		if iscapture(act) then
			tokenstack:push(0) -- not found any tokens yet
		end
		
		ret1 = traverse(op1, tokenrule)
		ret2 = traverse(op2, tokenrule)
		
		
		return applyaction(act, ret1, ret2, labs, tokenrule)
		
	elseif isgrammar(ast) then
		--
		local g = bg.buildgrammar (ast)
		return applygrammar (g)
		
	else
		peg.print_r(ast)
		error("Unsupported AST")	
	end

end

local function specialrules(ast, builder)
	-- initialize values
	SKIP = (Predef.space + Predef.nl)
	skipspaces = true
	SYNC = nil
	recovery = true
	-- find SPACE and SYNC rules
	for i, v in ipairs(ast) do
		local name = v["rulename"]
		local rule
		if name == "SKIP" then
			rule = traverse(v["rule"], true)
			if v["rule"]["t"] == '' then
				skipspaces = false
			else
				skipspaces = true
				SKIP = rule
			end
			builder[name] = rule
		elseif name == "SYNC" then
			rule = traverse(v["rule"], true)
			if v["rule"]["t"] == '' then-- SYNC <- ''
				recovery=false
			else
				recovery= true
				SYNC = rule
			end
			builder[name] = rule
		end
	end
	if not SYNC and recovery then
		SYNC = defaultsync(SKIP)
	end
end

local function recorderror(position,label)
	-- call error function here
	local line, col = peg.calcline(subject, position)
	local desc
	if label == 0 then
		desc = "Syntax error"
	else
		desc = tdescs[label]
	end
	if errorfunc then
		local temp = string.sub(subject,position)
		local strend = string.find(temp, "\n") 
		local sfail =  string.sub(temp, 1, strend)
		errorfunc(desc,line,col,sfail,trecs[label])
	end

	local err = { line = line, col = col, label=tlabelnames[label], msg = desc }
	table.insert(errors, err)

end
local function record(label)
	return (m.Cp() * m.Cc(label)) / recorderror
end

local function buildrecovery(grammar)

	local synctoken = pattspaces(sync(SYNC))
	local grec = grammar
	
	for k,v in pairs(tlabels) do

		if trecs[v] then -- custom sync token
			grec = m.Rec(grec,record(v) * pattspaces(trecs[v]), v)
		else -- use global sync token
			grec = m.Rec(grec,record(v) * synctoken, v)
		end
	end
	return grec
	
end
local usenode = false

local function usenodes(val)
	usenode = val
end


function bg.buildgrammar (ast)
	local builder = {}
	specialrules(ast, builder)
	local initialrule
	for i, v in ipairs(ast) do
		local istokenrule = v["token"] == "1"
		local isfragment = v["fragment"] == "1"
		local isnode = v["node"] == "1"
		
		if isnode and not usenodes then
			error("Node mode disabled - please use parser-gen.usenodes(true) before compiling the grammar")
		end
		
		local name = v["rulename"]
		local isspecial = name == "SKIP" or name == "SYNC"
		local rule = v["rule"]
		if i == 1 then
			initialrule = name
			table.insert(builder, name) -- lpeg syntax
			builder[name] = traverse(rule, istokenrule)
		else
			if not builder[name] then -- dont traverse rules for SKIP and SYNC twice
				builder[name] = traverse(rule, istokenrule)
			end
		end
		if buildast and not isfragment and not isspecial and ((not usenode) or (usenode and isnode)) then 
			if istokenrule then
				builder[name] = m.C(builder[name])
			end
			builder[name] = m.Ct(m.Cg(m.Cc(name),"rule") * m.Cg(m.Cp(),"pos") * builder[name]) 
		end
	end

	if skipspaces then
		builder[initialrule] = SKIP^0 * builder[initialrule] -- skip spaces at the beginning of the input
	end
	if recovery then
		builder[initialrule] = buildrecovery(builder[initialrule]) -- build recovery on top of initial rule
	end
	return builder
end




local function build(ast, defs)
	if defs then
		definitions = defs
	end
	if isgrammar(ast) then
		return traverse(ast)
	else
		SKIP = (Predef.space + Predef.nl)
		skipspaces = true
		SYNC = nil
		recovery = true
		SYNC = defaultsync(SKIP)
		local res = SKIP ^0 * traverse(ast)
		if buildast then
			res = m.Ct(res)
		end
		return res -- input is not a grammar - skip spaces and sync by default
	end
end



-- recovery grammar




-- end



-- t = {errName="Error description",...}
local function setlabels (t, errorgen)
	local index
	if errorgen then
		index = totallabels + 1
	else
		-- reset error tables
		index = 1
		tlabels = {}
		
		tdescs = {}
		trecs = {}
	end
	for key,value in pairs(t) do
		if index >= 255 then
			error("Error label limit reached(255)")
		end
		if type(value) == "table" then -- we have a recovery expression
			tdescs[index] = value[1]

			trecs[index] = traverse(peg.pegToAST(value[2]), true)-- PEG to LPEG
		else
			tdescs[index] = value
		end
		tlabels[key] = index
		tlabelnames[index] = key -- reverse table
		index = index + 1
	end
	totallabels = index-1
end


local function compile (input, defs, generrors, nocaptures)
	if iscompiled(input) then 
		return input 
	end
	if not mem[input] then
		buildast = true
		if nocaptures then
			buildast=false
		end
		--re.setlabels(tlabels)
		--re.compile(input,defs)
		-- build ast
		local ast = peg.pegToAST(input)
		if generrors then
			local follow = eg.follow(ast)
			local errors = eg.adderrors(ast, follow)
			setlabels (errors, true) -- add errors generated by errorgen
		end
		local gram = build(ast,defs)
		if not gram then
			-- find error using relabel module
			
		end
		mem[input] = gram-- store if the user forgets to compile it
	end
	return mem[input]
end






local function parse (input, grammar, errorfunction)
	if not iscompiled(grammar) then

		local cp = compile(grammar)
		grammar = cp
	end
	-- set up recovery table
	errorfunc = errorfunction
	subject = input
	errors = {}
	-- end
	local r, e, sfail = m.match(grammar,input)
	if not r then
		recorderror(#input - #sfail, e)
	end
	if #errors == 0 then errors=nil end
	return r, errors
end






local pg = {compile=compile, setlabels=setlabels, parse=parse,follow=follow, calcline = peg.calcline, usenodes = usenodes}

return pg
