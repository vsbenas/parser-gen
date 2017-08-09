package.path = package.path .. ";../?.lua"
local pg = require "parser-gen"
local peg = require "peg-parser"
local errs = {errMissingThen = "Missing Then"}
pg.setlabels(errs)


local grammar = pg.compile [[

  program <- stmtsequence !.
  stmtsequence <- {| statement (';' statement)* |}
  statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
  ifstmt <- {| {:stmt: 'if' :} {:exp: exp:} 'then'^errMissingThen {:action: stmtsequence:} ('else' {:else: stmtsequence:})? 'end' |}
  repeatstmt <- {| {:stmt:'repeat':} {:action: stmtsequence:} 'until' {:until: exp :} |}
  assignstmt <- {| {:stmt:''->'assign' :} {:id: IDENTIFIER :} ':=' {:exp: exp :} |}
  readstmt <- {| {:stmt:'read':} {:id: IDENTIFIER :} |}
  writestmt <- {| {:stmt:'write':} {:exp: exp :} |}
  exp <- {| simpleexp ({COMPARISONOP} simpleexp)+ |} / simpleexp
  COMPARISONOP <- '<' / '='
  simpleexp <- {| term ({ADDOP} term)+ |} / term
  ADDOP <- [+-]
  term <- {| factor ({MULOP} factor)+ |} / factor
  MULOP <- [*/]
  factor <- '(' exp ')' / {NUMBER} / {IDENTIFIER}

  NUMBER <- '-'? [0-9]+
  KEYWORDS <- 'if' / 'repeat' / 'read' / 'write' / 'then' / 'else' / 'end' / 'until' 
  RESERVED <- KEYWORDS ![a-zA-Z]
  IDENTIFIER <- !RESERVED [a-zA-Z]+
  HELPER <- ';' / '\n' / '\r'
  SYNC <- (!HELPER .)*

]]
local errs = 0
local function printerror(desc,line,col,sfail,trec)
	errs = errs+1
	print("Error #"..errs..": "..desc.." before '"..sfail.."' on line "..line.."(col "..col..")")
end


local function parse(input)
	result, errors = pg.parse(input,grammar,printerror)
	return result, errors
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	res, errs = parse(arg[1])
	peg.print_r(res)
	peg.print_r(errs)
end
local ret = {parse=parse}
return ret
