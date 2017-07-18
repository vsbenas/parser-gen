local lua = require "lua-parser"
print("\n\n [[ PARSING LUA TEST FILES ]] \n\n")
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
		print("Error: "..err)
	end
	f:close()
end
assert(errs == 0)

print("\n\n All files compiled successfully")


print("\n\n [[ TESTING ERROR LABELS ]] ")
-- test errors
local s,res, err
local ErrExtra="unexpected character(s), expected EOF"
s = [[ return; ! ]]
res, err = lua.parse(s)
assert(err == ErrExtra)

local ErrInvalidStat="unexpected token, invalid start of statement"
s = [[ ! ]]
res, err = lua.parse(s)
assert(err == ErrInvalidStat)


local ErrEndIf="expected 'end' to close the if statement"

s = [[ if c then b=1 ]]
res, err = lua.parse(s)
assert(err == ErrEndIf)

local ErrExprIf="expected a condition after 'if'"

s = [[ if then b=1 end]]
res, err = lua.parse(s)
assert(err == ErrExprIf)

local ErrThenIf="expected 'then' after the condition"

s = [[ if c b=1 end ]]
res, err = lua.parse(s)
assert(err == ErrThenIf)

local ErrExprEIf="expected a condition after 'elseif'"

s = [[ if a then b=1 elseif then d=1 end ]]
res, err = lua.parse(s)
assert(err == ErrExprEIf)

local ErrThenEIf="expected 'then' after the condition"

s = [[ if a b=1 end]]
res, err = lua.parse(s)
assert(err == ErrThenEIf)

local ErrEndDo="expected 'end' to close the do block"

s = [[ do x=1 ]]
res, err = lua.parse(s)
assert(err == ErrEndDo)

local ErrExprWhile="expected a condition after 'while'"

s = [[ while do c=1 end]]
res, err = lua.parse(s)
assert(err == ErrExprWhile)

local ErrDoWhile="expected 'do' after the condition"

s = [[ while a c=1 end ]]
res, err = lua.parse(s)
assert(err == ErrDoWhile)

local ErrEndWhile="expected 'end' to close the while loop"

s = [[ while a do b=1]]
res, err = lua.parse(s)
assert(err == ErrEndWhile)

local ErrUntilRep="expected 'until' at the end of the repeat loop"

s = [[ repeat c=1 ]]
res, err = lua.parse(s)
assert(err == ErrUntilRep)

local ErrExprRep="expected a conditions after 'until'"

s = [[ repeat c=1 until ]]
res, err = lua.parse(s)
assert(err == ErrExprRep)

local ErrForRange="expected a numeric or generic range after 'for'"

s = [[ for 3,4 do x=1 end]]
res, err = lua.parse(s)
assert(err == ErrForRange)

local ErrEndFor="expected 'end' to close the for loop"

s = [[ for c=1,3 do a=1 ]]
res, err = lua.parse(s)
assert(err == ErrEndFor)

local ErrExprFor1="expected a starting expression for the numeric range"

s = [[ for a=,4 do a=1 end]]
res, err = lua.parse(s)
assert(err == ErrExprFor1)

local ErrCommaFor="expected ',' to split the start and end of the range"

s = [[ for a=4 5 do a=1 end]]
res, err = lua.parse(s)
assert(err == ErrCommaFor)

local ErrExprFor2="expected an ending expression for the numeric range"

s = [[ for a=4, do a=1 end]]
res, err = lua.parse(s)
assert(err == ErrExprFor2)

local ErrExprFor3="expected a step expression for the numeric range after ','"

s = [[ for a=1,2, do a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrExprFor3)

local ErrInFor="expected '=' or 'in' after the variable(s)"

s = [[ for a of 1 do a=1 end]]
res, err = lua.parse(s)
assert(err == ErrInFor)

local ErrEListFor="expected one or more expressions after 'in'"

s = [[ for a in do a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrEListFor)

local ErrDoFor="expected 'do' after the range of the for loop"

s = [[ for a=1,2 a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrDoFor)

local ErrDefLocal="expected a function definition or assignment after local"

s = [[ local return c]]
res, err = lua.parse(s)
assert(err == ErrDefLocal)


local ErrNameLFunc="expected a function name after 'function'"

s = [[ 
local function()
	c=1
end
]]
res, err = lua.parse(s)
assert(err == ErrNameLFunc)

local ErrEListLAssign="expected one or more expressions after '='"

s = [[ 
local a = 
return b
]]
res, err = lua.parse(s)
assert(err == ErrEListLAssign)

local ErrEListAssign="expected one or more expressions after '='"

s = [[
a =
return b
 ]]
res, err = lua.parse(s)
assert(err == ErrEListAssign)


local ErrFuncName="expected a function name after 'function'"

s = [[ function () a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrFuncName)

local ErrNameFunc1="expected a function name after '.'"

s = [[ function a.() a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrNameFunc1)

local ErrNameFunc2="expected a method name after ':'"

s = [[ function a:() a=1 end ]]
res, err = lua.parse(s)
assert(err == ErrNameFunc2)

local ErrOParenPList="expected '(' for the parameter list"

s = [[ function a b=1 end]]
res, err = lua.parse(s)
assert(err == ErrOParenPList)

local ErrCParenPList="expected ')' to close the parameter list"

s = [[ function a( b=1 end]]
res, err = lua.parse(s)
assert(err == ErrCParenPList)

local ErrEndFunc="expected 'end' to close the function body"

s = [[ function a() b=1 ]]
res, err = lua.parse(s)
assert(err == ErrEndFunc)

local ErrParList="expected a variable name or '...' after ','"

s = [[ function a(b,) b=1 end ]]
res, err = lua.parse(s)
assert(err == ErrParList)


local ErrLabel="expected a label name after '::'"

s = [[ :: return b ]]
res, err = lua.parse(s)
assert(err == ErrLabel)

local ErrCloseLabel="expected '::' after the label"

s = [[ :: abc return a]]
res, err = lua.parse(s)
assert(err == ErrCloseLabel)

local ErrGoto="expected a label after 'goto'"

s = [[ goto return c]]
res, err = lua.parse(s)
assert(err == ErrGoto)



local ErrVarList="expected a variable name after ','"

s = [[ a, = 3]]
res, err = lua.parse(s)
assert(err == ErrVarList)

local ErrExprList="expected an expression after ','"

s = [[ return a,;]]
res, err = lua.parse(s)
assert(err == ErrExprList)


local ErrOrExpr="expected an expression after 'or'"

s = [[ return a or; ]]
res, err = lua.parse(s)
assert(err == ErrOrExpr)

local ErrAndExpr="expected an expression after 'and'"

s = [[ return a and;]]
res, err = lua.parse(s)
assert(err == ErrAndExpr)

local ErrRelExpr="expected an expression after the relational operator"

s = [[ return a >;]]
res, err = lua.parse(s)
assert(err == ErrRelExpr)


local ErrBitwiseExpr="expected an expression after bitwise operator"

s = [[ return b & ; ]]
res, err = lua.parse(s)
assert(err == ErrBitwiseExpr)

local ErrConcatExpr="expected an expression after '..'"

s = [[ print(a..) ]]
res, err = lua.parse(s)
assert(err == ErrConcatExpr)

local ErrAddExpr="expected an expression after the additive operator"

s = [[ return a -  ]]
res, err = lua.parse(s)
assert(err == ErrAddExpr)

local ErrMulExpr="expected an expression after the multiplicative operator"

s = [[ return a/ ]]
res, err = lua.parse(s)
assert(err == ErrMulExpr)

local ErrUnaryExpr="expected an expression after the unary operator"

s = [[ return # ]]
res, err = lua.parse(s)
assert(err == ErrUnaryExpr)

local ErrPowExpr="expected an expression after '^'"

s = [[ return a^ ]]
res, err = lua.parse(s)
assert(err == ErrPowExpr)


local ErrExprParen="expected an expression after '('"

s = [[ return a + () ]]
res, err = lua.parse(s)
assert(err == ErrExprParen)

local ErrCParenExpr="expected ')' to close the expression"

s = [[ return a + (a ]]
res, err = lua.parse(s)
assert(err == ErrCParenExpr)

local ErrNameIndex="expected a field name after '.'"

s = [[ return a. ]]
res, err = lua.parse(s)
assert(err == ErrNameIndex)

local ErrExprIndex="expected an expression after '['"

s = [[ return a [ ]]
res, err = lua.parse(s)
assert(err == ErrExprIndex)

local ErrCBracketIndex="expected ']' to close the indexing expression"

s = [[ return a[1 ]]
res, err = lua.parse(s)
assert(err == ErrCBracketIndex)

local ErrNameMeth="expected a method name after ':'"

s = [[ return a: ]]
res, err = lua.parse(s)
assert(err == ErrNameMeth)

local ErrMethArgs="expected some arguments for the method call (or '()')"
s = [[ a:b ]]
res, err = lua.parse(s)
assert(err == ErrMethArgs)



local ErrCParenArgs="expected ')' to close the argument list"

s = [[ return a(c ]]
res, err = lua.parse(s)
assert(err == ErrCParenArgs)


local ErrCBraceTable="expected '}' to close the table constructor"

s = [[ return { ]]
res, err = lua.parse(s)
assert(err == ErrCBraceTable)

local ErrEqField="expected '=' after the table key"

s = [[ a = {[b] b} ]]
res, err = lua.parse(s)
assert(err == ErrEqField)

local ErrExprField="expected an expression after '='"

s = [[ a = {[a] = } ]]
res, err = lua.parse(s)
assert(err == ErrExprField)

local ErrExprFKey="expected an expression after '[' for the table key"

s = [[ a = {[ = b} ]]
res, err = lua.parse(s)
assert(err == ErrExprFKey)

local ErrCBracketFKey="expected ']' to close the table key"

s = [[ a = {[a = b} ]]
res, err = lua.parse(s)
assert(err == ErrCBracketFKey)


local ErrDigitHex="expected one or more hexadecimal digits after '0x'"

s = [[ a = 0x ]]
res, err = lua.parse(s)
assert(err == ErrDigitHex)

local ErrDigitDeci="expected one or more digits after the decimal point"

s = [[ a = . ]]
res, err = lua.parse(s)
assert(err == ErrDigitDeci)

local ErrDigitExpo="expected one or more digits for the exponent"


s = [[ a = 1.0e ]]
res, err = lua.parse(s)
assert(err == ErrDigitExpo)

local ErrQuote="unclosed string"

s = [[ a = ";]]
res, err = lua.parse(s)
assert(err == ErrQuote)

local ErrHexEsc="expected exactly two hexadecimal digits after '\\x'"

s = [[ a = "a\x1" ]]
res, err = lua.parse(s)
assert(err == ErrHexEsc)

local ErrOBraceUEsc="expected '{' after '\\u'"

s = [[ a = "a\u" ]]
res, err = lua.parse(s)
assert(err == ErrOBraceUEsc)

local ErrDigitUEsc="expected one or more hexadecimal digits for the UTF-8 code point"

s = [[ a = "\u{}"]]
res, err = lua.parse(s)
assert(err == ErrDigitUEsc)

local ErrCBraceUEsc="expected '}' after the code point"

s = [[ a = "\u{12" ]]
res, err = lua.parse(s)
assert(err == ErrCBraceUEsc)

local ErrEscSeq="invalid escape sequence"

s = [[ a = "\;" ]]
res, err = lua.parse(s)
assert(err == ErrEscSeq)

local ErrCloseLStr="unclosed long string"


s = [==[ a = [[ abc return; ]==]
res, err = lua.parse(s)
assert(err == ErrCloseLStr)

print("\n\n All error labels generated successfully")

print("\n\n [[ TESTING AST GENERATION ]] ")

-- TODO: AST

print("\n\n All AST's generated successfully")

print("\n\nAll tests passed!")