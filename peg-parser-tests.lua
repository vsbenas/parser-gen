local peg = require "peg-parser"
local f = peg.pegToAST

local eq = require "equals"
local equals = eq.equals


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
res = {action="^", op1= {nt="name"}, op2 = {num="3"}}
assert(equals(e,res))

--p^+num	at least n repetitions
e = f("name^+3")
res = {action="^", op1= {nt="name"}, op2 = {num="+3"}}
assert(equals(e,res))

--p^-num	at most n repetitions
e = f("name^-3")
res = {action="^", op1= {nt="name"}, op2 = {num="-3"}}
assert(equals(e,res))

--p^LABEL error label
e = f("name^err")
res = {action = "^LABEL", op1= {nt="name"}, op2 = {s="err"}}
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

res = {action="->", op1= {nt="name"}, op2 = {num="3"}}

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

--peg.setlabels({errName=1})
e = f('%{errName}')

res = {action="label", op1={s="errName"}}

assert(equals(e,res))

-- a //{errName,errName2} b

--peg.setlabels({errName=1, errName2=2})
e = f('a //{errName,errName2} b')

res = {action="or", condition={{s="errName"},{s="errName2"}}, op1={nt="a"}, op2={nt="b"}}


assert(equals(e,res))

print("all tests succesful")