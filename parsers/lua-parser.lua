

--[==[ 
Parser for Lua 5.3 [] [==]] ==[[]=-- -- ][]][---[]
Based on https://github.com/antlr/grammars-v4/blob/master/lua/Lua.g4 and https://github.com/andremm/lua-parser/blob/master/lua-parser/parser.lua
]==]
function equals(s,i,a,b) return #a == #b end
package.path = package.path .. ";../?.lua"
function tryprint(s,i,...) print(i) print(...) return true end
local pg = require "parser-gen"
local grammar = pg.compile([==[
	chunk	<-	block 
	block	<-	stat* retstat?
	stat	<-	';' /
				varlist '=' explist /
				functioncall /
				label /
				'break' /
				'goto' NAME /
				'do' block 'end' /
				'while' exp 'do' block 'end' /
				'repeat' block 'until' exp /
				'if' exp 'then' block ('elseif' exp 'then' block)* ('else' block)? 'end' /
				'for' NAME '=' exp ',' exp (',' exp)? 'do' block 'end' /
				'for' namelist 'in' explist 'do' block 'end' / 
				'function' funcname funcbody / 
				'local' 'function' NAME funcbody /
				'local' namelist ('=' explist)?
	retstat	<-	'return' explist? ';'?
	label	<-	'::' NAME '::'
	funcname	<-	NAME ('.' NAME)* (':' NAME)?
	varlist	<-	var (',' var)*
	namelist	<-	NAME (',' NAME)*
	explist	<- exp (',' exp)*
	exp	<-	expTokens expOps?
	expTokens	<-	'nil' / 'false' / 'true' /
					operatorUnary exp /
					number /
					string /
					'...' /
					functiondef /
					prefixexp /
					tableconstructor 
	expOps	<-	operatorPower exp / -- assoc= right
				operatorMulDivMod exp / -- left
				operatorAddSub exp /
				operatorStrcat exp / -- right
				operatorComparison exp /
				operatorAnd exp /
				operatorOr exp /
				operatorBitwise exp 
	prefixexp	<- varOrExp nameAndArgs*
	functioncall	<- varOrExp nameAndArgs+
	varOrExp	<- var / '(' exp ')'
	var	<- (NAME / '(' exp ')' varSuffix) varSuffix* 
	varSuffix	<- nameAndArgs* ('[' exp ']' / '.' NAME)
	nameAndArgs	<- (':' NAME)? args
	args	<- '(' explist? ')' / tableconstructor / string
	functiondef	<- 'function' funcbody
	funcbody	<- '(' parlist? ')' block 'end'
	parlist	<- namelist (',' '...')? / '...'
	tableconstructor	<- '{' fieldlist? '}'
	fieldlist	<- field (fieldsep field)* fieldsep?
	field	<- '[' exp ']' '=' exp / NAME '=' exp / exp
	fieldsep	<- ',' / ';'
	operatorOr	<- 'or'
	operatorAnd	<- 'and'
	operatorComparison	<- '<' / '>' / '<=' / '>=' / '~=' / '=='
	operatorStrcat	<- '..'
	operatorAddSub	<- '+' / '-'
	operatorMulDivMod	<- '*' / '/' / '%' / '//'
	operatorBitwise	<- '&' / '|' / '~' / '<<' / '>>'
	operatorUnary	<- 'not' / '#' / '-' / '~'
	operatorPower	<- '^'
	number	<- INT / HEX / FLOAT / HEX_FLOAT    
	string	<- NORMALSTRING / CHARSTRING / LONGSTRING    
	-- lexer
	NAME	<- [a-zA-Z_][a-zA-Z_0-9]*
	NORMALSTRING	<-	'"' ( ESC / [^"\] )* '"' 
	CHARSTRING	<- "'" ( ESC / [^\'] )* "'"
	LONGSTRING	<- OPEN (!CLOSEEQ .)* CLOSE
	OPEN <- '[' {:openEq: EQUALS :} '[' %nl?
	CLOSE <- ']' {:closeEq: EQUALS :} ']'
	EQUALS <- '='*
	CLOSEEQ <- CLOSE ((=openEq =closeEq) => equals)

	INT	<- DIGIT+
	HEX	<- '0' [xX] HEXDIGIT+
	FLOAT	<- DIGIT+ '.' DIGIT* ExponentPart? /
				'.' DIGIT+ ExponentPart? /
				DIGIT+ ExponentPart
	HEX_FLOAT	<-	'0' [xX] HEXDIGIT+ '.' HEXDIGIT* HexExponentPart? /
					'0' [xX] '.' HEXDIGIT+ HexExponentPart? /
					'0' [xX] HEXDIGIT+ HexExponentPart
	
	ExponentPart	<- [eE] [+-]? DIGIT+ -- fragment
	HexExponentPart	<-	[pP] [+-]? DIGIT+ -- fragment
	ESC	<-	'\' [abfnrtvz"'\]	/ -- fragment
			'\' %nl /
			DECESC /
			HEXESC/
			UTFESC 
	DECESC	<- '\' ( DIGIT DIGIT? / [0-2] DIGIT DIGIT) -- fragment
	HEXESC	<- '\' 'x' HEXDIGIT HEXDIGIT -- fragment
	UTFESC	<- '\' 'u{' HEXDIGIT+ '}' -- fragment
	DIGIT	<-	[0-9] -- fragment
	HEXDIGIT	<-	[0-9a-fA-F] -- fragment
	COMMENT	<- '--' LONGSTRING -- skip this
	LINE_COMMENT	<-	'--' COMMENT_TYPES ( %nl / !.)
	COMMENT_TYPES	<-	'[' '='* [^[=%nl] [^%nl]* /
						'[' '='* /
						[^[%nl] [^%nl]* /
						''

	SHEBANG	<- '#' '!' [^%nl]*
	SPACES	<- %nl / %s / COMMENT / LINE_COMMENT / SHEBANG	 				 
			
]==],{ equals = equals,tryprint = tryprint})

local filename = "../parser-gen.lua"
local f = assert(io.open(filename, "r"))
local t = f:read("*all")
local res = pg.parse(t,grammar)
print(res)
print(t:sub(1,res-1))
f:close()
--[[
	
--]]