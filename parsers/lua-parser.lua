--[==[ 
Parser for Lua 5.3
Based on https://github.com/antlr/grammars-v4/blob/master/lua/Lua.g4 and https://github.com/andremm/lua-parser/blob/master/lua-parser/parser.lua
]==]
package.path = package.path .. ";../?.lua"
local pg = require "parser-gen"
function equals(s,i,a,b) return #a == #b end
function fixexp (...)
  local exp = {...}
  local len = #exp
  if len > 1 then
    exp.rule = "exp"
    exp[len].rule = "exp"
    return exp
  elseif exp[1] then
    if exp[1].rule == "expTokens" then
      return exp[1]
    else
      return exp[1][1]
    end
  end
end
function fold (...)
  local exp = {...}
  local len = #exp
  if len > 1 then
    local folded = { rule = "exp", fixexp(exp[1]) }
    for i = 2, len, 2 do
      folded = { rule = "exp", folded, exp[i], fixexp(exp[i+1]) }
    end
    return folded
  elseif exp[1] then
    return exp[1][1]
  end
end
-- from  https://github.com/andremm/lua-parser/blob/master/lua-parser/parser.lua
local labels = {
	ErrExtra="unexpected character(s), expected EOF",
	ErrInvalidStat={"unexpected token, invalid start of statement",[[ (!%nl .)* ]]},

	ErrEndIf="expected 'end' to close the if statement",
	ErrExprIf="expected a condition after 'if'",
	ErrThenIf="expected 'then' after the condition",
	ErrExprEIf="expected a condition after 'elseif'",
	ErrThenEIf="expected 'then' after the condition",

	ErrEndDo="expected 'end' to close the do block",
	ErrExprWhile="expected a condition after 'while'",
	ErrDoWhile="expected 'do' after the condition",
	ErrEndWhile="expected 'end' to close the while loop",
	ErrUntilRep="expected 'until' at the end of the repeat loop",
	ErrExprRep="expected a conditions after 'until'",

	ErrForRange="expected a numeric or generic range after 'for'",
	ErrEndFor="expected 'end' to close the for loop",
	ErrExprFor1="expected a starting expression for the numeric range",
	ErrCommaFor="expected ',' to split the start and end of the range",
	ErrExprFor2="expected an ending expression for the numeric range",
	ErrExprFor3={"expected a step expression for the numeric range after ','",[[ (!'do' !%nl .)* ]]},
	ErrInFor="expected '=' or 'in' after the variable(s)",
	ErrEListFor="expected one or more expressions after 'in'",
	ErrDoFor="expected 'do' after the range of the for loop",

	ErrDefLocal="expected a function definition or assignment after local",
	ErrNameLFunc="expected a function name after 'function'",
	ErrEListLAssign="expected one or more expressions after '='",
	ErrEListAssign="expected one or more expressions after '='",

	ErrFuncName="expected a function name after 'function'",
	ErrNameFunc1="expected a function name after '.'",
	ErrNameFunc2="expected a method name after ':'",
	ErrOParenPList="expected '(' for the parameter list",
	ErrCParenPList="expected ')' to close the parameter list",
	ErrEndFunc="expected 'end' to close the function body",
	ErrParList="expected a variable name or '...' after ','",

	ErrLabel="expected a label name after '::'",
	ErrCloseLabel="expected '::' after the label",
	ErrGoto="expected a label after 'goto'",

	ErrVarList={"expected a variable name after ','",[[ (!'=' !%nl .)* ]]},
	ErrExprList="expected an expression after ','",

	ErrOrExpr="expected an expression after 'or'",
	ErrAndExpr="expected an expression after 'and'",
	ErrRelExpr="expected an expression after the relational operator",

	ErrBitwiseExpr="expected an expression after bitwise operator",

	ErrConcatExpr="expected an expression after '..'",
	ErrAddExpr="expected an expression after the additive operator",
	ErrMulExpr="expected an expression after the multiplicative operator",
	ErrUnaryExpr="expected an expression after the unary operator",
	ErrPowExpr="expected an expression after '^'",

	ErrExprParen="expected an expression after '('",
	ErrCParenExpr="expected ')' to close the expression",
	ErrNameIndex="expected a field name after '.'",
	ErrExprIndex="expected an expression after '['",
	ErrCBracketIndex="expected ']' to close the indexing expression",
	ErrNameMeth="expected a method name after ':'",
	ErrMethArgs="expected some arguments for the method call (or '()')",


	ErrCParenArgs="expected ')' to close the argument list",

	ErrCBraceTable="expected '}' to close the table constructor",
	ErrEqField="expected '=' after the table key",
	ErrExprField="expected an expression after '='",
	ErrExprFKey={"expected an expression after '[' for the table key",[[ (!']' !%nl .)* ]] },
	ErrCBracketFKey={"expected ']' to close the table key",[[ (!'=' !%nl .)* ]]},

	ErrDigitHex="expected one or more hexadecimal digits after '0x'",
	ErrDigitDeci="expected one or more digits after the decimal point",
	ErrDigitExpo="expected one or more digits for the exponent",

	ErrQuote="unclosed string",
	ErrHexEsc={"expected exactly two hexadecimal digits after '\\x'",[[ (!('"' / "'" / %nl) .)* ]]},
	ErrOBraceUEsc="expected '{' after '\\u'",
	ErrDigitUEsc={"expected one or more hexadecimal digits for the UTF-8 code point",[[ (!'}' !%nl .)* ]]},
	ErrCBraceUEsc={"expected '}' after the code point",[[ (!('"' / "'") .)* ]]},
	ErrEscSeq={"invalid escape sequence",[[ (!('"' / "'" / %nl) .)* ]]},
	ErrCloseLStr="unclosed long string",
	ErrEqAssign="expected '=' after variable list in assign statement"
}
pg.setlabels(labels)
local grammar = pg.compile([==[
	chunk		<-	block (!.)^ErrExtra
	block		<-	stat* retstat?
	stat		<-	';' /
					functioncall /
					varlist '='^ErrEqAssign explist^ErrEListAssign /
					'break' /
					'goto' NAME^ErrGoto /
					'do' block 'end'^ErrEndDo  /
					'while' exp^ErrExprWhile 'do'^ErrDoWhile block 'end'^ErrEndWhile /
					'repeat' block 'until'^ErrUntilRep exp^ErrExprRep /
					'if' exp^ErrExprIf 'then'^ErrThenIf block ('elseif' exp^ErrExprEIf 'then'^ErrThenEIf  block)* ('else' block)? 'end'^ErrEndIf /
					'for' (forNum / forIn)^ErrForRange 'do'^ErrDoFor  block 'end'^ErrEndFor /
					
					'function' funcname^ErrFuncName funcbody / 
					'local' (localAssign / localFunc)^ErrDefLocal /
					label /
					!blockEnd %{ErrInvalidStat}
	blockEnd	<-	'return' / 'end' / 'elseif' / 'else' / 'until' / !.
	retstat		<-	'return' explist? ';'?
	forNum		<-	NAME '=' exp^ErrExprFor1 ','^ErrCommaFor exp^ErrExprFor2 (',' exp^ErrExprFor3)?
	forIn		<- 	namelist 'in'^ErrInFor explist^ErrEListFor 
	localFunc	<-	'function' NAME^ErrNameLFunc funcbody 
	localAssign	<-	namelist ('=' explist^ErrEListLAssign)?
	label		<-	'::' NAME^ErrLabel '::'^ErrCloseLabel
	funcname	<-	NAME ('.' NAME^ErrNameFunc1)* (':' NAME^ErrNameFunc2)?
	varlist		<-	var (',' var^ErrVarList)*
	namelist	<-	NAME (',' NAME)*
	explist		<-	exp (',' exp^ErrExprList )*
	
	exp		<-	expOR -> fixexp
	expOR		<-	(expAND (operatorOr expAND^ErrOrExpr)*) -> fold
	expAND		<- 	(expREL (operatorAnd expREL^ErrAndExpr)*) -> fold
	expREL		<-	(expBIT (operatorComparison expBIT^ErrRelExpr)*) -> fold
	expBIT		<- 	(expCAT (operatorBitwise expCAT^ErrBitwiseExpr)*) -> fold
	expCAT		<- 	(expADD (operatorStrcat expCAT^ErrConcatExpr)?) -> fixexp
	expADD		<- 	(expMUL (operatorAddSub expMUL^ErrAddExpr)*) -> fold
	expMUL		<-	(expUNA (operatorMulDivMod expUNA^ErrMulExpr)*) -> fold
	expUNA		<-	((operatorUnary expUNA^ErrUnaryExpr) / expPOW) -> fixexp
	expPOW		<- 	(expTokens (operatorPower expUNA^ErrPowExpr)?) -> fixexp
	
	expTokens	<-	'nil' / 'false' / 'true' /
					number /
					string /
					'...' /
					'function' funcbody /
					tableconstructor  /
					prefixexp 

	prefixexp	<-	varOrExp nameAndArgs*
	functioncall	<-	varOrExp nameAndArgs+
	varOrExp	<-	var / brackexp
	brackexp	<-	'(' exp^ErrExprParen ')'^ErrCParenExpr
	var		<-	(NAME / brackexp varSuffix) varSuffix*
	varSuffix	<-	nameAndArgs* ('[' exp^ErrExprIndex ']'^ErrCBracketIndex  / '.' !'.' NAME^ErrNameIndex)
	nameAndArgs	<-	(':' !':' NAME^ErrNameMeth args^ErrMethArgs) /
					args
	args		<-	'(' explist? ')'^ErrCParenArgs / tableconstructor / string
	funcbody	<-	'('^ErrOParenPList parlist? ')'^ErrCParenPList block 'end'^ErrEndFunc
	parlist		<-	namelist (',' '...'^ErrParList)? / '...'
	tableconstructor<-	'{' fieldlist? '}'^ErrCBraceTable
	fieldlist	<-	field (fieldsep field)* fieldsep?
	field		<-	!OPEN '[' exp^ErrExprFKey ']'^ErrCBracketFKey '='^ErrEqField exp^ErrExprField /
						NAME '=' exp  /
						exp 
	fieldsep	<-	',' / ';'
	operatorOr	<-	'or'
	operatorAnd	<-	'and'
	operatorComparison<-	'<=' / '>=' / '~=' / '==' / '<' !'<' / '>' !'>'
	operatorStrcat	<-	!'...' '..'
	operatorAddSub	<-	'+' / '-'
	operatorMulDivMod<-	'*' / '%' / '//' / '/' 
	operatorBitwise	<-	'&' / '|' / !'~=' '~' / '<<' / '>>'
	operatorUnary	<-	'not' / '#' / '-' / !'~=' '~'
	operatorPower	<-	'^'
	number		<-	FLOAT / HEX_FLOAT / HEX / INT
	string		<-	NORMALSTRING / CHARSTRING / LONGSTRING    
	-- lexer
	fragment
	RESERVED	<-	KEYWORDS !IDREST
	fragment
	IDREST		<- 	[a-zA-Z_0-9]
	fragment
	KEYWORDS	<-	'and' / 'break' / 'do' / 'elseif' / 'else' / 'end' /
					'false' / 'for' / 'function' / 'goto' / 'if' / 'in' /
					'local' / 'nil' / 'not' / 'or' / 'repeat' / 'return' /
					'then' / 'true' / 'until' / 'while'
	NAME		<-	!RESERVED [a-zA-Z_] [a-zA-Z_0-9]*
	fragment
	NORMALSTRING	<-	'"' {( ESC / [^"\] )*} '"'^ErrQuote
	fragment
	CHARSTRING	<-	"'" {( ESC / [^\'] )*} "'"^ErrQuote
	fragment
	LONGSTRING	<-	(OPEN {(!CLOSEEQ .)*} CLOSE^ErrCloseLStr) -> 1 -- capture only the string

	fragment 
	OPEN 		<-	'[' {:openEq: EQUALS :}  '[' %nl?
	fragment 
	CLOSE 		<-	']' {EQUALS} ']'
	fragment 
	EQUALS 		<-	'='*
	fragment 
	CLOSEEQ 	<-	(CLOSE =openEq) => equals

	INT		<-	DIGIT+
	HEX		<-	'0' [xX] HEXDIGIT+^ErrDigitHex
	FLOAT		<-	DIGIT+ '.' DIGIT* ExponentPart? /
					'.' !'.' DIGIT+^ErrDigitDeci ExponentPart? /
					DIGIT+ ExponentPart
	HEX_FLOAT	<-	'0' [xX] HEXDIGIT+ '.' HEXDIGIT* HexExponentPart? /
					'0' [xX] '.' HEXDIGIT+ HexExponentPart? /
					'0' [xX] HEXDIGIT+^ErrDigitHex HexExponentPart
	fragment
	ExponentPart	<-	[eE] [+-]? DIGIT+^ErrDigitExpo
	fragment
	HexExponentPart	<-	[pP] [+-]? DIGIT+^ErrDigitExpo 
	fragment
	ESC		<-	'\' [abfnrtvz"'\] /
					'\' %nl /
					DECESC /
					HEXESC/
					UTFESC/
					'\' %{ErrEscSeq} 
	fragment
	DECESC		<-	'\' ( DIGIT DIGIT? / [0-2] DIGIT DIGIT)
	fragment
	HEXESC		<-	'\' 'x' (HEXDIGIT HEXDIGIT)^ErrHexEsc
	fragment
	UTFESC		<-	'\' 'u' '{'^ErrOBraceUEsc HEXDIGIT+^ErrDigitUEsc '}'^ErrCBraceUEsc
	fragment
	DIGIT		<-	[0-9]
	fragment
	HEXDIGIT	<-	[0-9a-fA-F]
	
	
	fragment
	COMMENT		<-	'--' LONGSTRING -> 0 -- skip this
	fragment
	LINE_COMMENT	<-	'--' COM_TYPES ( %nl / !.)
	fragment
	COM_TYPES	<-	'[' '='* [^[=%nl] [^%nl]* /
					'[' '='* /
					[^[%nl] [^%nl]* /
					''
	fragment
	SHEBANG		<-	'#' '!' [^%nl]*
	
	
	SKIP		<-	%nl / %s / COMMENT / LINE_COMMENT / SHEBANG	 
	fragment
	HELPER		<-	RESERVED / '(' / ')'  -- for sync expression
	SYNC		<-	((!HELPER !SKIP .)+ / .?) SKIP* -- either sync to reserved keyword or skip characters and consume them
			
]==],{ equals = equals, fixexp = fixexp, fold = fold })
local errnr = 1
local function err (desc, line, col, sfail, recexp)
	print("Syntax error #"..errnr..": "..desc.." at line "..line.."(col "..col..")")
	errnr = errnr+1
end
local function parse (input)
	errnr = 1
	local ast, errs = pg.parse(input,grammar,err)
	return ast, errs
end
return {parse=parse}
