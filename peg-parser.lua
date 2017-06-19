local lpeg = require "lpeg-funcs"
local re = require "relabel"

local peg = {}


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
					/ {'->'} S (string / {| '{}' {:action:''->'poscap':} |} / funcname / {num})
					/ {'=>'} S funcname) S )




	primary         <- '(' exp ')' / string / class / defined
					/ {| '%{' S {:action:''->'label':} {:op1: label:} S '}' |}
					/ {| ('{:' {:action:''->'gcap':} {:op2: name:} ':' {:op1:exp:} ':}') / ( '{:' {:action:''->'gcap':} {:op1:exp:} ':}')  |}
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
	funcname		<- {| {:func: [A-Za-z][A-Za-z0-9_]* :} |}

	namenocap		<- [A-Za-z][A-Za-z0-9_]*
	arrow           <- '<-'
	num             <- [0-9]+
	string          <- {| '"' {:t: [^"]* :} '"' / "'" {:t: [^']* :} "'" |}
	defined         <- {| {:action: '%':} {:op1: name :} |}

]=]
peg.gram = gram

local labels = {err=3, ok=2}
function tlabels(name)
	if not labels[name] then
		error("Error name '"..name.."' undefined!")
	end
	return tostring(labels[name])
end
local p = re.compile ( gram, {foldtable=foldtable, tlabels=tlabels})




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
%

Terminal actions:
t
nt
r
func


]]--
function peg.pegToAST(input, defs)
	return p:match(input, defs)
end
function peg.setLabels(input)
	labels=input
end
function lpeg.print_r ( t )  -- for debugging
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => '"..tostring(val).."'")
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"")
end
if arg[1] then	
	-- argument must be in quotes if it contains spaces
	lpeg.print_r(peg.pegToAST(arg[1]))
end

return peg