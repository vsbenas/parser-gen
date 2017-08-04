local re = require "relabel"

local peg = {}

function concat(a,b)
	return a..b
end
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

	pattern		<- exp !.
	exp		<- S (grammar / alternative)

	labels		<- {| '{' {: label :} (',' {: label :})* '}' |}


	alternative	<- ( {:''->'or':} {| {: seq :} ('/' (('/' {| {: labels :} S {: seq :} |}) / (S {: seq :} ) ) )* |} ) -> foldtable


	seq		<- ( {:''->'and':} {| {: prefix :}+ |} ) -> foldtable


	prefix		<- {| {:action: '&' :} S {:op1: prefix :} |} 
			/ {| {:action: '!' :} S {:op1: prefix :} |}
			/ suffix

	suffix		<- ( {:''->'suf':} {| primary S {| suffixaction|}* |} ) -> foldtable


	suffixaction	<- (
				({[+*?]}
				/ {'^'} {| {:s: [+-]? NUM:} |}
				/ '^' ''->'^LABEL' label
				/ {'->'} S (string / {| '{}' {:action:''->'poscap':} |} / funcname / {|{:sn: NUM :} |})
				/ {'=>'} S funcname) 
			   S )




	primary		<- '(' exp ')' / term / class / defined
				/ {| '%{' S {:action:''->'label':} {:op1: label:} S '}' |}
				/ {| ('{:' {:action:''->'gcap':} {:op2: defname:} ':' {:op1:exp:} ':}') / ( '{:' {:action:''->'gcap':} {:op1:exp:} ':}')  |}
				/ {| '=' {:action:''->'bref':} {:op1: defname:} |}
				/ {| '{}' {:action:''->'poscap':} |}
				/ {| '{~' {:action:''->'subcap':} {:op1: exp:} '~}' |}
				/ {| '{|' {:action:''->'tcap':} {:op1: exp:} '|}' |}
				/ {| '{' {:action:''->'scap':} {:op1: exp:} '}' |}
				/ {| '.' {:action:''->'anychar':} |}
				/ !frag name S !ARROW
				/ '<' name '>'          -- old-style non terminals

	grammar		<- {| definition+ |}
	definition	<- {| frag? (token / nontoken) S ARROW {:rule: exp :} |}

	label		<- {| {:s: ERRORNAME :} |}
	frag		<- {:fragment: 'fragment'->'1' :} ![0-9_a-z] S !ARROW
	
	token		<- {:rulename: [A-Z_]+ ![0-9_a-z] :} {:token:''->'1':}
	nontoken	<- {:rulename: [A-Za-z][A-Za-z0-9_]* :} 

	class		<- '[' ( ('^' {| {:action:''->'invert':} {:op1: classset :} |} ) / classset ) ']' 
	classset	<- ( {:''->'or':} {| {: item :} (!']' {: item :})* |} ) -> foldtable
	item		<- defined / range / {| {:t: . :} |}
	range		<- {| {:action:''->'range':} {:op1: {| {:s: ({: . :} ('-') {: [^]] :} ) -> concat :} |} :} |}

	S		<- (%s / '--' [^%nl]*)*   -- spaces and comments
	name		<- {| {:nt: TOKENNAME :} {:token:''->'1':} / {:nt: NAMESTRING :} |}
	ERRORNAME	<- NAMESTRING
	funcname	<- {| {:func: NAMESTRING :} |}

	NAMESTRING	<- [A-Za-z][A-Za-z0-9_]*
	TOKENNAME	<- [A-Z_]+ ![0-9a-z]
	defname		<- {| {:s: NAMESTRING :} |}
	ARROW		<- '<-'
	NUM		<- [0-9]+
	term		<- {| '"' {:t: [^"]* :} '"' / "'" {:t: [^']* :} "'" |}
	string		<- {| '"' {:s: [^"]* :} '"' / "'" {:s: [^']* :} "'" |}
	defined		<- {| {:action: '%':} {:op1: defname :} |}
	AST		<- '' -- for self description test
]=]

local defs = {foldtable=foldtable, concat=concat}
peg.gram = gram
peg.defs = defs
local p = re.compile ( gram, defs)




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
^label (label is an error label set with setlabels)
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
range

Final token actions:
t - terminal
nt - non terminal
func - function definition
s - literal string
sn - literal number
]]--
function peg.pegToAST(input, defs)
	return p:match(input, defs)
end

--[[
function peg.setlabels(t)
	for key,value in pairs(t) do
		if (type(key) ~= "string") then
			error("Invalid error label key '"..value.."'. Keys must be strings.")
		end
		if (type(value) ~= "number") or value < 1 or value > 255 then
			error("Invalid error label value '"..value.."'. Error label keys must be integers from 1 to 255")
		end
	end
	labels = t
end
]]--
function peg.print_r ( t )  -- for debugging
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
function peg.print_t ( t )  -- for debugging
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."{")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)-1).."},")
                    else
						if tonumber(pos) then
							print(indent.."'"..tostring(val).."',")
						else
							print(indent..pos.."='"..tostring(val).."',")
						end
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"")
end

return peg