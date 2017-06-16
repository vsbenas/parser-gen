local peg = require "peg-parser"
local lpeg = require "lpeg-funcs"
local f = peg.pegToAST
local pr = lpeg.print_r


function equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end


-- self-description of peg-parser:

assert(f(peg.gram))

-- ( p )	grouping
e = f("('a')")
res = {t="a"}

assert(equals(e,res))

-- 'string'	literal string
-- "string"	literal string
--[class]	character class
--.	any character
--%name	pattern defs[name] or a pre-defined pattern
--name	non terminal
--<name>	non terminal
--{}	position capture
--{ p }	simple capture
--{: p :}	anonymous group capture
--{:name: p :}	named group capture
--{~ p ~}	substitution capture
--{| p |}	table capture
--=name	back reference
--p ?	optional match
--p *	zero or more repetitions
--p +	one or more repetitions
--p^num	exactly n repetitions
--p^+num	at least n repetitions
--p^-num	at most n repetitions
--p -> 'string'	string capture
--p -> "string"	string capture
--p -> num	numbered capture
--p -> name	function/query/string capture equivalent to p / defs[name]
--p => name	match-time capture equivalent to lpeg.Cmt(p, defs[name])
--& p	and predicate
--! p	not predicate
--p1 p2	concatenation
--p1 / p2	ordered choice
--(name <- p)+	grammar


print("all tests succesful")