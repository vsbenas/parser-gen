local lua = require "lua-parser"
local peg = require "peg-parser"

local eq = require "equals"
local equals = eq.equals
print("\n\n [[ PARSING LUA TEST SUITE FILES ]] \n\n")
local filenames = {
'all.lua',
'main.lua',
'gc.lua',
'db.lua',
'calls.lua',
'strings.lua',
'literals.lua',
'tpack.lua',
'attrib.lua',
'locals.lua',
'constructs.lua',
'code.lua',
'big.lua',
'nextvar.lua',
'pm.lua',
'utf8.lua',
'api.lua',
'events.lua',
'vararg.lua',
'closure.lua',
'coroutine.lua',
'goto.lua',
'errors.lua',
'math.lua',
'sort.lua',
'bitwise.lua',
'verybig.lua', 
'files.lua',
}
local errs = 0
for k,v in ipairs(filenames) do
	local filename = "lua-5.3.4-tests/"..v
	local f = assert(io.open(filename, "r"))

	local t = f:read("*all")

	local res, err = lua.parse(t)
	local s = "OK"
	if not res then s = "FAIL" end -- only check if succesful since grammar ensures whole file is read
	print("Testing file '"..v.."': ["..s.."]")
	if not res then
		errs = errs + 1
		print("Error: "..err[1]["msg"])
	end
	f:close()
end
assert(errs == 0)

print("\n\n Test suite files compiled successfully")


print("\n\n [[ TESTING ERROR LABELS ]] ")
local pr = peg.print_r
-- test errors
local s,res, err
local ErrExtra="unexpected character(s), expected EOF"
s = [[ return; ! ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExtra)

local ErrInvalidStat="unexpected token, invalid start of statement"
s = [[ ! ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrInvalidStat)


local ErrEndIf="expected 'end' to close the if statement"

s = [[ if c then b=1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEndIf)

local ErrExprIf="expected a condition after 'if'"

s = [[ if then b=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprIf)

local ErrThenIf="expected 'then' after the condition"

s = [[ if c b=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrThenIf)

local ErrExprEIf="expected a condition after 'elseif'"

s = [[ if a then b=1 elseif then d=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprEIf)

local ErrThenEIf="expected 'then' after the condition"

s = [[ if a b=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrThenEIf)

local ErrEndDo="expected 'end' to close the do block"

s = [[ do x=1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEndDo)

local ErrExprWhile="expected a condition after 'while'"

s = [[ while do c=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprWhile)

local ErrDoWhile="expected 'do' after the condition"

s = [[ while a c=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDoWhile)

local ErrEndWhile="expected 'end' to close the while loop"

s = [[ while a do b=1]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEndWhile)

local ErrUntilRep="expected 'until' at the end of the repeat loop"

s = [[ repeat c=1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrUntilRep)

local ErrExprRep="expected a conditions after 'until'"

s = [[ repeat c=1 until ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprRep)

local ErrForRange="expected a numeric or generic range after 'for'"

s = [[ for 3,4 do x=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrForRange)

local ErrEndFor="expected 'end' to close the for loop"

s = [[ for c=1,3 do a=1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEndFor)

local ErrExprFor1="expected a starting expression for the numeric range"

s = [[ for a=,4 do a=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprFor1)

local ErrCommaFor="expected ',' to split the start and end of the range"

s = [[ for a=4 5 do a=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCommaFor)

local ErrExprFor2="expected an ending expression for the numeric range"

s = [[ for a=4, do a=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprFor2)

local ErrExprFor3="expected a step expression for the numeric range after ','"

s = [[ for a=1,2, do a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprFor3)

local ErrInFor="expected '=' or 'in' after the variable(s)"

s = [[ for a of 1 do a=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrInFor)

local ErrEListFor="expected one or more expressions after 'in'"

s = [[ for a in do a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEListFor)

local ErrDoFor="expected 'do' after the range of the for loop"

s = [[ for a=1,2 a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDoFor)

local ErrDefLocal="expected a function definition or assignment after local"

s = [[ local return c ]]

print("Parsing '"..s.."'")
res, err = lua.parse(s)

assert(err[1]["msg"] == ErrDefLocal)


local ErrNameLFunc="expected a function name after 'function'"

s = [[ local function() c=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrNameLFunc)


local ErrEListLAssign="expected one or more expressions after '='"

s = [[ local a = return b ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEListLAssign)

local ErrEListAssign="expected one or more expressions after '='"

s = [[ a = return b ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEListAssign)


local ErrFuncName="expected a function name after 'function'"

s = [[ function () a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrFuncName)

local ErrNameFunc1="expected a function name after '.'"

s = [[ function a.() a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrNameFunc1)

local ErrNameFunc2="expected a method name after ':'"

s = [[ function a:() a=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrNameFunc2)

local ErrOParenPList="expected '(' for the parameter list"

s = [[ function a b=1 end]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrOParenPList)

local ErrCParenPList="expected ')' to close the parameter list"

s = [[ 
function a( 
	b=1

end
]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCParenPList)

local ErrEndFunc="expected 'end' to close the function body"

s = [[ function a() b=1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEndFunc)

local ErrParList="expected a variable name or '...' after ','"

s = [[ function a(b, ) b=1 end ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrParList)


local ErrLabel="expected a label name after '::'"

s = [[ :: return b ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrLabel)

local ErrCloseLabel="expected '::' after the label"

s = [[ :: abc return a]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCloseLabel)

local ErrGoto="expected a label after 'goto'"

s = [[ goto return c]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrGoto)



local ErrVarList="expected a variable name after ','"

s = [[ abc,  
		= 3]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)

assert(err[1]["msg"] == ErrVarList)

local ErrExprList="expected an expression after ','"

s = [[ return a,;]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprList)


local ErrOrExpr="expected an expression after 'or'"

s = [[ return a or; ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrOrExpr)

local ErrAndExpr="expected an expression after 'and'"

s = [[ return a and;]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrAndExpr)

local ErrRelExpr="expected an expression after the relational operator"

s = [[ return a >;]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrRelExpr)


local ErrBitwiseExpr="expected an expression after bitwise operator"

s = [[ return b & ; ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrBitwiseExpr)

local ErrConcatExpr="expected an expression after '..'"

s = [[ print(a..) ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrConcatExpr)

local ErrAddExpr="expected an expression after the additive operator"

s = [[ return a -  ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrAddExpr)

local ErrMulExpr="expected an expression after the multiplicative operator"

s = [[ return a/ ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrMulExpr)

local ErrUnaryExpr="expected an expression after the unary operator"

s = [[ return # ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrUnaryExpr)

local ErrPowExpr="expected an expression after '^'"

s = [[ return a^ ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrPowExpr)


local ErrExprParen="expected an expression after '('"

s = [[ return a + () ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprParen)

local ErrCParenExpr="expected ')' to close the expression"

s = [[ return a + (a ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCParenExpr)

local ErrNameIndex="expected a field name after '.'"

s = [[ return a. ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrNameIndex)

local ErrExprIndex="expected an expression after '['"

s = [[ return a [ ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprIndex)

local ErrCBracketIndex="expected ']' to close the indexing expression"

s = [[ return a[1 ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCBracketIndex)

local ErrNameMeth="expected a method name after ':'"

s = [[ return a: ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrNameMeth)

local ErrMethArgs="expected some arguments for the method call (or '()')"
s = [[ a:b ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrMethArgs)



local ErrCParenArgs="expected ')' to close the argument list"

s = [[ return a(c ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCParenArgs)


local ErrCBraceTable="expected '}' to close the table constructor"

s = [[ return { ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCBraceTable)

local ErrEqField="expected '=' after the table key"

s = [[ a = {[b] b} ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEqField)

local ErrExprField="expected an expression after '='"

s = [[ a = {[a] = } ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprField)

local ErrExprFKey="expected an expression after '[' for the table key"

s = [[ a = {[ = b} ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrExprFKey)

local ErrCBracketFKey="expected ']' to close the table key"

s = [[ a = {[a = b} ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCBracketFKey)


local ErrDigitHex="expected one or more hexadecimal digits after '0x'"

s = [[ a = 0x ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDigitHex)

local ErrDigitDeci="expected one or more digits after the decimal point"

s = [[ a = . ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDigitDeci)

local ErrDigitExpo="expected one or more digits for the exponent"


s = [[ a = 1.0e ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDigitExpo)

local ErrQuote="unclosed string"

s = [[ a = ";]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrQuote)

local ErrHexEsc="expected exactly two hexadecimal digits after '\\x'"

s = [[ a = "a\x1" ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrHexEsc)

local ErrOBraceUEsc="expected '{' after '\\u'"

s = [[ a = "a\u" ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrOBraceUEsc)

local ErrDigitUEsc="expected one or more hexadecimal digits for the UTF-8 code point"

s = [[ a = "\u{}"]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrDigitUEsc)

local ErrCBraceUEsc="expected '}' after the code point"

s = [[ a = "\u{12" ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCBraceUEsc)

local ErrEscSeq="invalid escape sequence"

s = [[ a = "\;" ]]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrEscSeq)

local ErrCloseLStr="unclosed long string"


s = [==[ a = [[ abc return; ]==]
print("Parsing '"..s.."'")
res, err = lua.parse(s)
assert(err[1]["msg"] == ErrCloseLStr)

print("\n\n All error labels generated successfully")

print("\n\n [[ TESTING AST GENERATION ]]\n\n ")

-- TODO: AST

s = [[ 
if abc > 123 then 
	abc=123 
end]]
rez = {
	rule='chunk',
	pos=3,
	{
			 rule='block',
			 pos=3,
			 {
					  rule='stat',
					  pos=3,
					  'if',
					  {
							   rule='exp',
							   pos=6,
							   {
										rule='exp',
										{
												 rule='exp',
												 {
														  rule='expTokens',
														  pos=6,
														  {
																   rule='prefixexp',
																   pos=6,
																   {
																			rule='varOrExp',
																			pos=6,
																			{
																					 rule='var',
																					 pos=6,
																					 {
																							  rule='NAME',
																							  pos=6,
																							  'abc',
																					 },
																			},
																   },
														  },
												 },
										},
										{
												 rule='operatorComparison',
												 pos=10,
												 '>',
										},
										{
												 rule='expTokens',
												 pos=12,
												 {
														  rule='number',
														  pos=12,
														  {
																   rule='INT',
																   pos=12,
																   '123',
														  },
												 },
										},
							   },
					  },
					  'then',
					  {
							   rule='block',
							   pos=23,
							   {
										rule='stat',
										pos=23,
										{
												 rule='varlist',
												 pos=23,
												 {
														  rule='var',
														  pos=23,
														  {
																   rule='NAME',
																   pos=23,
																   'abc',
														  },
												 },
										},
										'=',
										{
												 rule='explist',
												 pos=27,
												 {
														  rule='exp',
														  pos=27,
														  {
																   rule='expTokens',
																   pos=27,
																   {
																			rule='number',
																			pos=27,
																			{
																					 rule='INT',
																					 pos=27,
																					 '123',
																			},
																   },
														  },
												 },
										},
							   },
					  },
					  'end',
			 },
	},


}


print("Parsing '"..s.."'")
res, err = lua.parse(s)
peg.print_t(res)
assert(equals(res,rez))

s = [[ 
local a = [=[ long string ]=]

-- aaa
return a
--[==[ hi 

]==]
]]
rez = {

	rule='chunk',
	pos=3,
	{
			 rule='block',
			 pos=3,
			 {
					  rule='stat',
					  pos=3,
					  'local',
					  {
							   rule='localAssign',
							   pos=9,
							   {
										rule='namelist',
										pos=9,
										{
												 rule='NAME',
												 pos=9,
												 'a',
										},
							   },
							   '=',
							   {
										rule='explist',
										pos=13,
										{
												 rule='exp',
												 pos=13,
												 {
														  rule='expTokens',
														  pos=13,
														  {
																   rule='string',
																   pos=13,
																   ' long string ',
														  },
												 },
										},
							   },
					  },
			 },
			 {
					  rule='retstat',
					  pos=41,
					  'return',
					  {
							   rule='explist',
							   pos=48,
							   {
										rule='exp',
										pos=48,
										{
												 rule='expTokens',
												 pos=48,
												 {
														  rule='prefixexp',
														  pos=48,
														  {
																   rule='varOrExp',
																   pos=48,
																   {
																			rule='var',
																			pos=48,
																			{
																					 rule='NAME',
																					 pos=48,
																					 'a',
																			},
																   },
														  },
												 },
										},
							   },
					  },
			 },
	},



}
print("Parsing '"..s.."'")
res, err = lua.parse(s)
peg.print_t(res)
assert(equals(res,rez))

print("\n\n All AST's generated successfully")

print("\n\nAll tests passed!")