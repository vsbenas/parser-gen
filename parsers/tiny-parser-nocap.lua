package.path = package.path .. ";../?.lua"
local pg = require "parser-gen"
local peg = require "peg-parser"
local errs = {errMissingThen = "Missing Then"}
pg.setlabels(errs)


local grammar = pg.compile [[

  program <- stmtsequence !.
  stmtsequence <- statement (';' statement)* 
  statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
  ifstmt <- 'if' exp ('then' / %{errMissingThen}) stmtsequence ('else' stmtsequence)? 'end' 
  repeatstmt <-  'repeat' stmtsequence 'until' exp 
  assignstmt <- IDENTIFIER ':=' exp 
  readstmt <-  'read'  IDENTIFIER 
  writestmt <-  'write' exp 
  exp <-  simpleexp (COMPARISONOP simpleexp)+  / simpleexp
  COMPARISONOP <- '<' / '='
  simpleexp <-  term (ADDOP term)+  / term
  ADDOP <- [+-]
  term <-  factor (MULOP factor)+  / factor
  MULOP <- [*/]
  factor <- '(' exp ')' / NUMBER / IDENTIFIER

  NUMBER <- '-'? [0-9]+
  IDENTIFIER <- [a-zA-Z]+
  SYNC <- ';' / '\n' / '\r'

]]

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
	return result
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	peg.print_r(parse(arg[1]))
end
local ret = {parse=parse}
return ret
