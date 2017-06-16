local lpeg = require "lpeg-funcs"
local re = require "relabel"

local peg = {}


-- imported from relabel.lua :


local errinfo = {
  {"NoPatt", "no pattern found"},
  {"ExtraChars", "unexpected characters after the pattern"},

  {"ExpPatt1", "expected a pattern after '/' or the label(s)"},

  {"ExpPatt2", "expected a pattern after '&'"},
  {"ExpPatt3", "expected a pattern after '!'"},

  {"ExpPatt4", "expected a pattern after '('"},
  {"ExpPatt5", "expected a pattern after ':'"},
  {"ExpPatt6", "expected a pattern after '{~'"},
  {"ExpPatt7", "expected a pattern after '{|'"},

  {"ExpPatt8", "expected a pattern after '<-'"},

  {"ExpPattOrClose", "expected a pattern or closing '}' after '{'"},

  {"ExpNum", "expected a number after '^', '+' or '-' (no space)"},
  {"ExpCap", "expected a string, number, '{}' or name after '->'"},

  {"ExpName1", "expected the name of a rule after '=>'"},
  {"ExpName2", "expected the name of a rule after '=' (no space)"},
  {"ExpName3", "expected the name of a rule after '<' (no space)"},

  {"ExpLab1", "expected at least one label after '{'"},
  {"ExpLab2", "expected a label after the comma"},

  {"ExpNameOrLab", "expected a name or label after '%' (no space)"},

  {"ExpItem", "expected at least one item after '[' or '^'"},

  {"MisClose1", "missing closing ')'"},
  {"MisClose2", "missing closing ':}'"},
  {"MisClose3", "missing closing '~}'"},
  {"MisClose4", "missing closing '|}'"},
  {"MisClose5", "missing closing '}'"},  -- for the captures

  {"MisClose6", "missing closing '>'"},
  {"MisClose7", "missing closing '}'"},  -- for the labels

  {"MisClose8", "missing closing ']'"},

  {"MisTerm1", "missing terminating single quote"},
  {"MisTerm2", "missing terminating double quote"},
}



local errmsgs = {}
local labels = {}

for i, err in ipairs(errinfo) do
  errmsgs[i] = err[2]
  labels[err[1]] = i
end

-- end


function foldtable(action,t)
	local re
	local first = true
	for key,value in pairs(t) do
		if first then
			re = value
			first = false
		else
			local temp = re
			if action == "suf" then -- suffix actions
				local act = value[1]
				if act == "*" or act == "?" or act == "+" then
					re = {action=act, op1=temp}
				else
					re = {action=act, op1=temp, op2=value[2]}
				end
			elseif action == "or" and #value == 2 then -- recovery expression
				local labels = value[1]
				local op2 = value[2]
				re = {action=action, op1=temp, op2=op2, condition=labels}
			else
				re = {action=action, op1=temp, op2=value}
			end
		end
	end
	return re
end


local gram = [=[

pattern         <- exp !.
exp             <- S (grammar / alternative)

labels			<- {| '{' {: label :} (',' {: label :})* '}' |}


alternative		<- ( {:''->'or':} {| {: seq :} ('/' ('/' {| {: labels :} S {: seq :} |} / S {: seq :} ) )* |} ) -> foldtable


seq		        <- ( {:''->'and':} {| {: prefix :}+ |} ) -> foldtable


prefix          <- {| {:action: '&' :} S {:op1: prefix :} |} 
				/ {| {:action: '!' :} S {:op1: prefix :} |}
				/ suffix

suffix			<- ( {:''->'suf':} {| primary S {| suffixaction|}* |} ) -> foldtable


suffixaction	<- 	((		{[+*?]}
				/ {'^'} {[+-]? num}
				/ {'->'} S (string / {| '{}' {:action:''->'poscap':} |} / name)
				/ {'=>'} S name) S )




primary         <- '(' exp ')' / string / class / defined
				/ {| '%{' S {:action:''->'label':} {:op1: label:} S '}' |}
				/ {| '{:' {:action:''->'gcap':} ({:op2: name:} ':')? {:op1:exp:} ':}' |}
				/ {| '=' {:action:''->'bref':} {:op1: name:} |}
				/ {| '{}' {:action:''->'poscap':} |}
				/ {| '{~' {:action:''->'subcap':} {:op1: exp:} '~}' |}
				/ {| '{|' {:action:''->'tcap':} {:op1: exp:} '|}' |}
				/ {| '{' {:action:''->'scap':} {:op1: exp:} '}' |}
				/ {| '.' {:action:''->'anychar':} |}
				/ name S !arrow
				/ '<' name '>'          -- old-style non terminals

grammar         <- {| definition+ |}
definition      <- {| (token  S arrow {:rule: exp :}) 
				/ (nontoken  S arrow {:rule: exp :}) |}

label			<- num / errorname -> tlabels

token 			<- {:rulename: [A-Z]+ :} {:token:''->'1':}
nontoken		<- {:rulename: [A-Za-z][A-Za-z0-9_]* :} 

class           <- {| {:r: '[' '^'? item (!']' item)* ']':} |}
item            <- defined / range / .
range           <- . '-' [^]]

S               <- (%s / '--' [^%nl]*)*   -- spaces and comments
name            <- {| {:nt: [A-Z]+:} {:token:''->'1':} / {:nt: [A-Za-z][A-Za-z0-9_]* :} |}
errorname		<- [A-Za-z][A-Za-z0-9_]*

namenocap		<- [A-Za-z][A-Za-z0-9_]*
arrow           <- '<-'
num             <- [0-9]+
string          <- {| '"' {:t: [^"]* :} '"' / "'" {:t: [^']* :} "'" |}
defined         <- {| {:action: '%':} {:op1: name :} |}

]=]


local labels = {err=3, ok=2}
function tlabels(name)
	if not labels[name] then
		error("Error name '"..name.."' undefined!")
	end
	return labels[name]
end
local p = re.compile ( gram, {foldtable=foldtable, tlabels=tlabels})
--[[

a+ -> hello

{action = "->", op1={action ="+", op1={nt="a"}, op2 = {nt="hello"}}

							
					
]]--

--[[
Function: pegToAST(input)

Input: a grammar in PEG format, described in https://github.com/vsbenas/parser-gen

Output: if parsing successful - a table of grammar rules, else - runtime error

Example input: 	"

	Program <- stmt* / SPACE
	stmt <- ('a' / 'b')+
	SPACE <- ''
		
"

Example output: {
	{rulename = "Program",	rule = {action = "or", op1 = {action = "*", op1 = {nt = "stmt"}}, op2 = {nt = "SPACE", token="1"}}},
	{rulename = "stmt", 	rule = {action = "+", op1 = {action="or", op1 = {t = "a"}, op2 = {t = "b"}}}},
	{rulename = "SPACE",	rule = {t=""}, token=1},
}

The rules are further processed and turned into lpeg compatible format in parser-gen.lua

Action names:
or (has parameter condition for recovery expresions)
and
&
!
+
*
?
^num (num is a number with an optional plus or minus sign)
->
=>
tcap
gcap (op2= name, anonymous otherwise)
bref
poscap
subcap
scap
anychar
label
rec
%

]]--
function peg.pegToAST(input)
	return p:match(input)
end
local testgram = [[
	program <- stmtsequence
	stmtsequence <- statement (';' statement)*
	statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
	ifstmt <- 'if' exp 'then' stmtsequence ('else' stmtsequence)? 'end'
	repeatstmt <- 'repeat' stmtsequence 'until' exp
	assignstmt <- IDENTIFIER ':=' exp
	readstmt <- 'read' IDENTIFIER
	writestmt <- 'write' exp
	exp <- simpleexp (COMPARISONOP simpleexp)*
	COMPARISONOP <- '<' / '='
	simpleexp <- term (ADDOP term)*
	ADDOP <- '+' / '-'
	term <- factor (MULOP factor)*
	MULOP <- '*' / '/'
	factor <- '(' exp ')' / NUMBER / IDENTIFIER

	NUMBER <- '-'? [0-9]+
	IDENTIFIER <- [a-zA-Z]+
	
]]
if arg[1] then	
	-- argument must be in quotes if it contains spaces
	lpeg.print_r(peg.pegToAST(arg[1]))
end

return peg