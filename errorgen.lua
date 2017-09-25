-- Error generation code for LL(1) grammars
-- AST funcs:

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
local function istoken (t)
	return t["token"] == "1"
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

--[[

function rightleaf:

returns the right-most concatenation in the AST.
used for followset keys

input: ((A B) C)
output: {"nt_C"}

input: (A / B / C) (D / 'e')
output: {"nt_D","t_e"}

input: A*
output: {'',"nt_A"}

input: !A
output: {"not_nt_A"}
]]
local function addnot(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[k] = "not_"..v
	end
	return ret
end
local function addepsilon(t)
	local ret = t
	table.insert(ret, '')
	return ret
end
local function mergetables(first,second)
	local ret = first
	for k,v in pairs(second) do 
		table.insert(ret, v) 
	end
	return ret
end

local function rightleaf(t)
	local action = t.action
	local op1 = t.op1
	local op2 = t.op2
	
	if isfinal(t) then
	
		-- todo: replace nt_A with FIRST(A)
		local typefn, fn, tok = finalNode(t)
		local ret = typefn .. "_" .. fn -- terminals: t_if, nonterminals: nt_if
		return {ret}
		
	end
	
	
	if action == "or" then
	
		return mergetables(rightleaf(op1), rightleaf(op2))
		
	elseif action == "and" then -- consider only RHS
	
		return rightleaf(op2)
		
	elseif action == "&" then
	
		return rightleaf(op1)
		
	elseif action == "!" then
	
		return addnot(rightleaf(op1))
		
	elseif action == "+" then
	
		return rightleaf(op1)
		
	elseif action == "*" or action == "?" then
	
		return addepsilon(rightleaf(op1))

	elseif action == "^" then
	
		op2 = op2["num"] -- second operand is number
		if op2 >= 1 then
			return rightleaf(op1)
		else
			return addepsilon(rightleaf(op1))
		end
		
	elseif action == "^LABEL" or action == "->" or action == "=>" or action == "tcap" or action == "gcap" or action == "subcap" or action == "scap" then
	
		return rightleaf(op1)
		
	elseif action == "bref" or action == "poscap" then
	
		return addepsilon({}) -- only empty string
		
	elseif action == "anychar" then
	
		return {"_anychar"}
		
	elseif action == "label" then
	
		return addepsilon({})
		
	elseif action == "%" then
	
		return addepsilon({})
		
	elseif action == "invert" then
	
		return addnot(rightleaf(op1))
		
	elseif action == "range" then
	
		return {"_anychar"}
		
	else
		error("Unsupported action '"..action.."'")
	end

end


local FOLLOW = {}

local function follow_aux(t, dontsplit)

	local action = t.action
	local op1 = t.op1
	local op2 = t.op2
	

	if isfinal(t) then
	
		return {t}
		
	end
	
	if action == "or" then
	
		if dontsplit then -- do not split "(B / C)" in "A (B / C)"
			return {t}
		else -- return both
			return mergetables(follow_aux(op1), follow_aux(op2))
		end
		
	elseif action == "and" then -- magic happens here
	
		-- (A (B / D)) (!E C / D)
		
		-- 1) FOLLOW(B) = FOLLOW(D) = {(!E C / D)}
		local rightset = rightleaf(op1) 
		local rhs = follow_aux(op2)
		for k,v in pairs(rightset) do
			if not FOLLOW[v] then
				FOLLOW[v] = {}
			end
			-- TODO: check if rhs already exists in FOLLOW(v)
			table.insert(FOLLOW[v],rhs)
			
		end
		
		-- 2) FOLLOW(A) = {(B / D)}
		
		return follow_aux(op1)
		
		
	elseif action == "&" then
	
		return follow_aux(op1)
		
	elseif action == "!" then
	
		return {action="!", op1=follow_aux(op1)}
		
	elseif action == "+" then
	
		return follow_aux(op1)
		
	elseif action == "*" then
	
		return addepsilon(follow_aux(op1))
		
	elseif action == "?" then
		
		return addepsilon(follow_aux(op1))
		
	elseif action == "^" then
	
		op2 = op2["num"]
		
		if op2 >= 1 then
			return follow_aux(op1)
		else
			return addepsilon(follow_aux(op1))
		end
		
	elseif action == "^LABEL" or action == "->" or action == "=>" or action == "tcap" or action == "gcap" or action == "subcap" or action == "scap" then
	
		return follow_aux(op1)
		
	elseif action == "bref" or action == "poscap" then
	
		return addepsilon({}) -- only empty string
		
	elseif action == "anychar" then
	
		return {"_anychar"}
		
	elseif action == "label" then
	
		return addepsilon({})
		
	elseif action == "%" then
	
		return addepsilon({})
		
	elseif action == "invert" then
	
		return {t} -- whole table
		
	elseif action == "range" then
	
		return {"_anychar"}
		
	else
		error("Unsupported action '"..action.."'")
	end
end

-- function: follow
-- finds follow set for the whole AST, with key (rule, term)
local function follow (t)
	local followset = {}
	if isgrammar(t) then 
		for pos,val in pairs(t) do
			local rule = val.rulename
			FOLLOW = {} -- reset for each rule
			follow_aux(val.rule) -- apply recursive function
			followset[rule] = FOLLOW
		end
	else
		FOLLOW = {}
		follow_aux(t)
		followset[''] = FOLLOW
	end
	return followset
end

-- functions to add errors
-- find size of table
local function getn (t)
  local size = 0
  for _, _ in pairs(t) do
    size = size+1
  end
  return size
end
-- generate error message by traversing table to the left
local function printexpect(op)
	--peg.print_r(op)
	if isfinal(op) then
		if op["t"] then
			return "'"..op["t"].."'"
		end
		return op["nt"] or op["func"] or op["s"] or op["num"]
	else
		local test = op.op1
		if not test then
			return op.action
		else
			return printexpect(test)
		end
	end
end
local GENERATED_ERRORS = 0
local TERRS = {}
local function generateerror(op, after)

	local desc = "Expected "..printexpect(op)
	
	local err = GENERATED_ERRORS+1
	if err >= 255 then
		error("Error label limit reached(255)")
	end
	local name = "errorgen"..err
	TERRS[name] = desc
	GENERATED_ERRORS = GENERATED_ERRORS+1
	return name
end


local function tryadderror(op, after)

	if FOLLOW then
	
		local rhs = rightleaf(after)
		-- (A / B) C
		-- generate error iff #FOLLOW(A) OR #FOLLOW(B) = 1
		local generate = false
		for k,v in pairs(rhs) do
			if FOLLOW[v] then
				local n = getn(FOLLOW[v])
				generate = generate or n==1
			end
		end
		if generate then
			local lab = generateerror(op, after)
			return {action="^LABEL",op1=op,op2={s=lab}}
		end
	end
	return op
end


-- function: adderrors
-- traverses the AST and adds error labels where possible

local function adderrors_aux(ast,tokenrule)

	if not ast then
		return nil 
	end

	if isaction(ast) then
	
		local act, op1, op2
		act = ast["action"]
		op1 = ast["op1"]
		op2 = ast["op2"]
		
		if act == "and" and not tokenrule then
		
			op2 = tryadderror(op2, op1)
			
		end
		
		ast["op1"] = adderrors_aux(op1,tokenrule)
		ast["op2"] = adderrors_aux(op2,tokenrule)
	end
	return ast
end
local function adderrors(t, followset)
	GENERATED_ERRORS = 0
	TERRS = {}
	if isgrammar(t) then 
		for pos,val in pairs(t) do
			local currentrule = val.rulename
			FOLLOW = followset[currentrule]
			local rule = val.rule
			local istokenrule = val.token == "1"
			adderrors_aux(rule,istokenrule)
		end
	else
		FOLLOW = followset['']
		adderrors_aux(t,false)
	end
	return TERRS
end

return {follow=follow,adderrors=adderrors}
