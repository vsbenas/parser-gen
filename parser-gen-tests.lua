local pg = require "parser-gen"
local peg = require "peg-parser"
local re = require "relabel"

local eq = require "equals"

local equals = eq.equals


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
SKIP <- ''
SYNC <- ''
]]
str = "a     b"
res = pg.parse(str,rule)
assert(not res)

-- custom space
rule = pg.compile [[
rule <- 'a' 'b'
SKIP <- DOT
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
res, err = pg.parse(str,rule)
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

r = pg.compile([[ rule <- {| {:'a' 'b':}* |} 

				]],_,_,true)
res = pg.parse("ababab", r)

assert(equals(res,{"ab","ab","ab"}))
-- space in capture

rule = pg.compile([[ rule <- {| {: 'a' :}* |} 
]],_,_,true)
str = " a a a "
res = pg.parse(str,rule)

assert(equals(res,{"a","a","a"})) -- fails

-- TESTING ERROR LABELS
local labs = {errName = "Error number 1",errName2 = "Error number 2"}
pg.setlabels(labs)
rule = pg.compile [[ rule <- 'a' / %{errName}
					SYNC <- '' 
					]]
local errorcalled = false
local function err(desc, line, col, sfail, recexp)
	errorcalled = true
	assert(desc == "Error number 1")
end
res = pg.parse("b",rule,err)
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

pg.setlabels({})
rule = pg.compile([[
rule <- A B C 
A <- 'a'
B <- 'b'
C <- 'c'

]],_,true)
res1, errs = pg.parse("ab",rule)
assert(errs[1]["msg"] == "Expected C")

-- TESTING RECOVERY GENERATION


-- SELF-DESCRIPTION
pg.setlabels(peg.labels)
gram = pg.compile(peg.gram, peg.defs,_,true)
res1, errs = pg.parse(peg.gram,gram)
assert(res1) -- parse succesful

--[[ this test is invalid since tool added ^LABEL syntax
r = re.compile(peg.gram,peg.defs)
res2 = r:match(peg.gram)

--peg.print_r(res2)

assert(equals(res1, res2))
]]--



print("all tests succesful")