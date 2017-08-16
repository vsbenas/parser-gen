package.path = package.path .. ";../?.lua"
local pg = require "parser-gen"
local peg = require "peg-parser"
local errs = {errMissingThen = "Missing Then"}
pg.setlabels(errs)


local grammar = pg.compile([[

  program <- stmtsequence !.
  stmtsequence <- statement (';' statement)* 
  statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
  ifstmt <- 'if' exp 'then'^errMissingThen stmtsequence elsestmt? 'end' 
  elsestmt <- ('else' stmtsequence)
  repeatstmt <-  'repeat' stmtsequence 'until' exp 
  assignstmt <- IDENTIFIER ':=' exp 
  readstmt <-  'read'  IDENTIFIER 
  writestmt <-  'write' exp 
  exp <-  simpleexp (COMPARISONOP simpleexp)*
  COMPARISONOP <- '<' / '='
  simpleexp <-  term (ADDOP term)* 
  ADDOP <- [+-]
  term <-  factor (MULOP factor)*
  MULOP <- [*/]
  factor <- '(' exp ')' / NUMBER / IDENTIFIER

  NUMBER <- '-'? [0-9]+
  KEYWORDS <- 'if' / 'repeat' / 'read' / 'write' / 'then' / 'else' / 'end' / 'until' 
  RESERVED <- KEYWORDS ![a-zA-Z]
  IDENTIFIER <- !RESERVED [a-zA-Z]+
  HELPER <- ';' / %nl / %s / KEYWORDS / !.
  SYNC <- (!HELPER .)*

]], _, true)

local function printerror(label,line,col)
	local err
	if label == 0 then
		err = "Syntax error"
	else
		err = errNames[label]
	end
	print("Error #"..label..": "..err.." on line "..line.."(col "..col..")")
end


local function parse(input)
	result, errors = pg.parse(input,grammar,_,printerror)
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
