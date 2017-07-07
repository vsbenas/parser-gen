local pg = require "parser-gen"
local peg = require "peg-parser"
local re = require "relabel"

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

local pr = peg.print_r


-- terminals
-- space allowed
rule = pg.compile [[
rule <-  'a'
]]
str = "a   a aa "
res = pg.parse(str,rule)
assert(res)

-- space not allowed
rule = pg.compile [[
RULE <- 'a' 'b'
]]
str = "a     b"
res = pg.parse(str,rule)
assert(not res)

-- space not allowed 2
rule = pg.compile [[
rule <- 'a' 'b'
SPACES <- ''
]]
str = "a     b"
res = pg.parse(str,rule)
assert(not res)

-- custom space
rule = pg.compile [[
rule <- 'a' 'b'
SPACES <- DOT
DOT <- '.'
]]
str = "a...b"
res = pg.parse(str,rule)
assert(res)

-- non terminals
-- space allowed
rule = pg.compile [[
rule <- A B
A	<- 'a'
B	<- 'b'
]]
str = "a     b"
res = pg.parse(str,rule)
assert(res)
-- no spaces allowed
rule = pg.compile [[
RULE <- A B
A	<- 'a'
B	<- 'b'
]]
str = "a     b"
res = pg.parse(str,rule)
assert(not res)

-- space in the beginning and end of string
rule = pg.compile [[
rule <- A B
A	<- 'a'
B	<- 'b'
]]
str = "  a     b  "
res = pg.parse(str,rule)
assert(res)



-- TESTING CAPTURES

r = pg.compile [[ rule <- {| {:'a' 'b':}* |} ]]
res = pg.parse("ababab", r)

assert(equals(res,{"ab","ab","ab"}))
-- space in capture

rule = pg.compile [[ rule <- {| {: 'a' :}* |} ]]
str = " a a a "
res = pg.parse(str,rule)

assert(equals(res,{"a","a","a"})) -- fails

-- TESTING ERROR LABELS
local labs = {errName = "Error number 1",errName2 = "Error number 2"}
pg.setlabels(labs)
rule = pg.compile [[ rule <- 'a'* %{errName} ]]
local errorcalled = false
local function err(label, desc, line, col)
	errorcalled = true
	assert(desc == "Error number 1")
end
res = pg.parse("aaa",rule,_,err)
assert(errorcalled)

-- TESTING ERROR RECOVERY

local labs = {errName = "Error number 1",errName2 = "Error number 2"}
pg.setlabels(labs)

rule = pg.compile [[ 
rule <- As //{errName,errName2} Bs
As <- 'a'* / %{errName2}
Bs <- 'b'*
]]
res1 = pg.parse(" a a a",rule)
res2 = pg.parse("b b b ",rule)
assert(res1 and res2)

-- TESTING ERROR GENERATION


-- TESTING RECOVERY GENERATION


-- SELF-DESCRIPTION
gram = pg.compile(peg.gram, peg.defs)
res1 = pg.parse(peg.gram,gram)
assert(res1) -- parse succesful


r = re.compile(peg.gram,peg.defs)
res2 = r:match(peg.gram)

--peg.print_r(res2)

assert(equals(res1, res2))


print("all tests succesful")