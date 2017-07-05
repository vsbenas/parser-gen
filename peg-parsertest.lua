local peg = require "peg-parser"
local f = peg.pegToAST

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

--assert(f(peg.gram))

-- ( p )	grouping
e = f("('a')")
res = {t="a"}

assert(equals(e,res))

-- 'string'	literal string

e = f("'string'")
res = {t="string"}
assert(equals(e,res))

-- "string"	literal string
e = f('"string"')
res = {t="string"}

assert(equals(e,res))
--[class]	character class
e = f("[^a-zA-Z01]")
res = {
	action = "invert",
	op1 = {
		action = "or",
		op1 = {
			action = "or",
			op1 = {
				action = "or",
				op1 = {
					action = "range",
					op1 = {
						s = "az"
					}
				},
				op2 = {
					action = "range",
					op1 = {
						s = "AZ"
					}
				}
			},
			op2 = {
				t = "0"
			}
		},
		op2 = {
			t = "1"
		}
	}
}	 


assert(equals(e,res))

--.	any character
e = f(".")
res = {action="anychar"}

assert(equals(e,res))
--%name	pattern defs[name] or a pre-defined pattern
e = f("%name")
res = {action="%", op1={s="name"}}

assert(equals(e,res))
--name	non terminal
e = f("name")
res = {nt="name"}

assert(equals(e,res))

--<name>	non terminal
e = f("<name>")
res = {nt="name"}

assert(equals(e,res))

--{}	position capture
e = f("{}")

res = {action="poscap"}

assert(equals(e,res))

--{ p }	simple capture
e = f("{name}")
res = {action="scap", op1= {nt="name"}}

assert(equals(e,res))

--{: p :}	anonymous group capture
e = f("{:name:}")
res = {action="gcap", op1= {nt="name"}}

assert(equals(e,res))

--{:name: p :}	named group capture
e = f("{:g: name:}")
res = {action="gcap", op1= {nt="name"} , op2={s="g"}}

assert(equals(e,res))
--{~ p ~}	substitution capture
e = f("{~ name ~}")

res = {action="subcap", op1= {nt="name"}}

assert(equals(e,res))

--{| p |}	table capture
e = f("{| name |}")
res = {action="tcap", op1= {nt="name"}}
assert(equals(e,res))

--=name	back reference
e = f("=name")
res = {action="bref", op1= {s="name"}}
assert(equals(e,res))

--p ?	optional match
e = f("name?")
res = {action="?", op1= {nt="name"}}
assert(equals(e,res))

--p *	zero or more repetitions
e = f("name*")
res = {action="*", op1= {nt="name"}}
assert(equals(e,res))

--p +	one or more repetitions
e = f("name+")
res = {action="+", op1= {nt="name"}}
assert(equals(e,res))

--p^num	exactly n repetitions
e = f("name^3")
res = {action="^", op1= {nt="name"}, op2 = "3"}
assert(equals(e,res))

--p^+num	at least n repetitions
e = f("name^+3")
res = {action="^", op1= {nt="name"}, op2 = "+3"}
assert(equals(e,res))

--p^-num	at most n repetitions
e = f("name^-3")
res = {action="^", op1= {nt="name"}, op2 = "-3"}
assert(equals(e,res))

--p -> 'string'	string capture
e = f("name -> 'a'")
res = {action="->", op1= {nt="name"}, op2 = {s="a"}}
assert(equals(e,res))

--p -> "string"	string capture
e = f('name -> "a"')
res = {action="->", op1= {nt="name"}, op2 = {s="a"}}
assert(equals(e,res))

--p -> num	numbered capture

e = f('name -> 3')

res = {action="->", op1= {nt="name"}, op2 = "3"}

assert(equals(e,res))

--p -> name	function/query/string capture equivalent to p / defs[name]

e = f('name -> func')
res = {action="->", op1= {nt="name"}, op2 = {func="func"}}

assert(equals(e,res))



--p => name	match-time capture equivalent to lpeg.Cmt(p, defs[name])

e = f('name => func')
res = {action="=>", op1= {nt="name"}, op2 = {func="func"}}

assert(equals(e,res))


--& p	and predicate

e = f('&name')
res = {action="&", op1= {nt="name"}}

assert(equals(e,res))


--! p	not predicate


e = f('!name')
res = {action="!", op1= {nt="name"}}

assert(equals(e,res))


--p1 p2 p3	concatenation with left association

e = f('name name2 name3')
res = {action="and", op1= {action = "and", op1={nt="name"}, op2={nt="name2"}}, op2={nt="name3"}}

assert(equals(e,res))

--p1 / p2 / p3	ordered choice with left association

e = f('name / name2 / name3')
res = {action="or", op1= {action = "or", op1={nt="name"}, op2={nt="name2"}}, op2={nt="name3"}}

assert(equals(e,res))


--(name <- p)+	grammar

e = f('a <- b b <- c')
res = {
	{rulename = "a", rule = {nt="b"}},
	{rulename = "b", rule = {nt="c"}}
}

assert(equals(e,res))

-- error labels
-- %{errName}

peg.setlabels({errName=1})
e = f('%{errName}')

res = {action="label", op1={s="1"}}

assert(equals(e,res))

-- a //{errName,errName2} b

peg.setlabels({errName=1, errName2=2})
e = f('a //{errName,errName2} b')

res = {action="or", condition={{s="1"},{s="2"}}, op1={nt="a"}, op2={nt="b"}}


assert(equals(e,res))

print("all tests succesful")