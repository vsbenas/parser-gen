local re = require "relabel"

local peg = {}

-- from relabel.lua

local errinfo = {
  {"NoPatt", "no pattern found"},
  {"ExtraChars", "unexpected characters after the pattern"},

  {"ExpPatt1", "expected a pattern after '/' or '//{...}'"},

  {"ExpPatt2", "expected a pattern after '&'"},
  {"ExpPatt3", "expected a pattern after '!'"},

  {"ExpPatt4", "expected a pattern after '('"},
  {"ExpPatt5", "expected a pattern after ':'"},
  {"ExpPatt6", "expected a pattern after '{~'"},
  {"ExpPatt7", "expected a pattern after '{|'"},

  {"ExpPatt8", "expected a pattern after '<-'"},

  {"ExpPattOrClose", "expected a pattern or closing '}' after '{'"},

  {"ExpNum", "expected a number after '^', '+' or '-' (no space)"},
  {"ExpNumOrLab", "expected a number or a label after ^"},
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

re.setlabels(labels)

local function concat(a,b)
	return a..b
end
local function foldtable(action,t)
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

	pattern		<- (exp / %{NoPatt}) (!. / %{ExtraChars})
	exp		<- S (grammar / alternative)

	labels		<- {| '{' {: (label / %{ExpLab1}) :} (',' {: (label / %{ExpLab2}) :})* ('}' / %{MisClose7}) |}


	alternative	<- ( {:''->'or':} {| {: seq :} ('/' (('/' {| {: labels :} S {: (seq / %{ExpPatt1}) :} |}) / (S {: (seq / %{ExpPatt1}) :} ) ) )* |} ) -> foldtable


	seq		<- ( {:''->'and':} {| {: prefix :}+ |} ) -> foldtable


	prefix		<- {| {:action: '&' :} S {:op1: (prefix / %{ExpPatt2}) :} |} 
			/ {| {:action: '!' :} S {:op1: (prefix / %{ExpPatt3}) :} |} 
			/ suffix

	suffix		<- ( {:''->'suf':} {| primary S {| suffixaction S |}* |} ) -> foldtable


	suffixaction	<- {[+*?]}
			/ {'^'} {| {:num: [+-]? NUM:} |}
			/ '^'->'^LABEL' (label / %{ExpNumOrLab}) 
			/ {'->'} S ((string / {| {:action:'{}'->'poscap':} |} / funcname / {|{:num: NUM :} |}) / %{ExpCap}) 
			/ {'=>'} S (funcname / %{ExpName1}) 




	primary		<- '(' (exp / %{ExpPatt4}) (')' / %{MisClose1}) 
			/ term
			/ class
			/ defined
			/ {| {:action: '%'->'label':} ('{' / %{ExpNameOrLab})  S ({:op1: label:} / %{ExpLab1})  S ('}' / %{MisClose7})  |}
			/ {| {:action: '{:'->'gcap':} {:op2: defname:} ':' !'}' ({:op1:exp:} / %{ExpPatt5}) (':}' / %{MisClose2}) |}
			/ {| {:action: '{:'->'gcap':} ({:op1:exp:} / %{ExpPatt5}) (':}' / %{MisClose2})  |}
			/ {| {:action: '='->'bref':} ({:op1: defname:} / %{ExpName2}) |}
			/ {| {:action: '{}'->'poscap':} |}
			/ {| {:action: '{~'->'subcap':} ({:op1: exp:} / %{ExpPatt6}) ('~}' / %{MisClose3}) |}
			/ {| {:action: '{|'->'tcap':} ({:op1: exp:} / %{ExpPatt7}) ('|}' / %{MisClose4}) |}
			/ {| {:action: '{'->'scap':} ({:op1: exp:} / %{ExpPattOrClose}) ('}' / %{MisClose5}) |}
			/ {| {:action: '.'->'anychar':} |}
			/ !frag !nodee name S !ARROW
			/ '<' (name / %{ExpName3}) ('>' / %{MisClose6})        -- old-style non terminals

	grammar		<- {| definition+ |}
	definition	<- {| (frag / nodee)? (token / nontoken) S ARROW ({:rule: exp :} / %{ExpPatt8}) |}

	label		<- {| {:s: ERRORNAME :} |}
	
	frag		<- {:fragment: 'fragment'->'1' :} ![0-9_a-z] S !ARROW
	nodee		<- {:node: 'node'->'1' :} ![0-9_a-z] S !ARROW
	token		<- {:rulename: TOKENNAME :} {:token:''->'1':}
	nontoken	<- {:rulename: NAMESTRING :} 

	class		<- '[' ( ('^' {| {:action:''->'invert':} {:op1: classset :} |} ) / classset ) (']' / %{MisClose8})
	classset	<- ( {:''->'or':} {| {: (item / %{ExpItem}) :} (!']' {: (item / %{ExpItem}) :})* |} ) -> foldtable
	item		<- defined / range / {| {:t: . :} |}
	range		<- {| {:action:''->'range':} {:op1: {| {:s: ({: . :} ('-') {: [^]] :} ) -> concat :} |} :} |}

	S		<- (%s / '--' [^%nl]*)*   -- spaces and comments
	name		<- {| {:nt: TOKENNAME :} {:token:''->'1':} / {:nt: NAMESTRING :} |}
	
	funcname	<- {| {:func: NAMESTRING :} |}
	ERRORNAME	<- NAMESTRING
	NAMESTRING	<- [A-Za-z][A-Za-z0-9_]*
	TOKENNAME	<- [A-Z_]+ ![0-9a-z]
	defname		<- {| {:s: NAMESTRING :} |}
	ARROW		<- '<-'
	NUM		<- [0-9]+
	term		<- {| '"' {:t: [^"]* :} ('"' / %{MisTerm2}) / "'" {:t: [^']* :} ("'" / %{MisTerm1})  |}
	string		<- {| '"' {:s: [^"]* :} ('"' / %{MisTerm2})  / "'" {:s: [^']* :} ("'" / %{MisTerm1}) |}
	defined		<- {| {:action: '%':} {:op1: defname :} |}
]=]

local defs = {foldtable=foldtable, concat=concat}
peg.gram = gram
peg.defs = defs
peg.labels = labels
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
num - literal number
]]--
local function splitlines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end
function peg.pegToAST(input, defs)
	local r, e, sfail = p:match(input, defs)
	if not r then
		local lab
		if e == 0 then
			lab = "Syntax error"
		else
			lab = errmsgs[e]
		end
		local lines = splitlines(input)
		local line, col = re.calcline(input, #input - #sfail + 1)
		local err = {}
		table.insert(err, "L" .. line .. ":C" .. col .. ": " .. lab)
		table.insert(err, lines[line])
		table.insert(err, string.rep(" ", col-1) .. "^")
		error("syntax error(s) in pattern\n" .. table.concat(err, "\n"), 3)
	end
	return r
end


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
    local function sub_print_r (t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
				local function subprint (pos,val,indent)
					if (type(val)=="table") then
                        print(indent.."{")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)-1).."},")
                    else
						if type(val) ~= "number" then
							val = "'"..tostring(val).."'"
						end
							
						if tonumber(pos) then
							print(indent..val..",")
						else
							print(indent..pos.."="..val..",")
						end
                    end
				end
				if t["rule"] then 
					subprint("rule",t["rule"],indent)
				end
				if t["pos"] then
					subprint("pos",t["pos"],indent)
				end
                for pos,val in pairs(t) do
					if pos ~= "rule" and pos ~= "pos" then
						subprint(pos,val,indent)
					end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"")
end

function peg.calcline(subject, pos)
	return re.calcline(subject,pos)
end
return peg