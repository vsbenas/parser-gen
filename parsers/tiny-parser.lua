package.path = package.path .. ";../?.lua"
local pg = require "parser-gen"
local errs = {errMissingThen = 1}
pg.setlabels(errs)

local errNames = {"Missing then"}

local grammar = pg.compile [[

  program <- stmtsequence !.
  stmtsequence <- statement (';' statement)*
  statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
  ifstmt <- 'if' exp ('then' / %{errMissingThen}) stmtsequence ('else' stmtsequence)? 'end'
  repeatstmt <- 'repeat' stmtsequence 'until' exp
  assignstmt <- IDENTIFIER ':=' exp
  readstmt <- 'read' IDENTIFIER
  writestmt <- 'write' exp
  exp <- simpleexp (COMPARISONOP simpleexp)*
  COMPARISONOP <- '<' / '='
  simpleexp <- term (ADDOP term)*
  ADDOP <- '+' / '-'
  term <- factor (MULOP factor)*
  MULOP <- '*' / '/'
  factor <- '(' exp ')' / NUMBER / IDENTIFIER

  NUMBER <- '-'? [0-9]+
  IDENTIFIER <- [a-zA-Z]+
  SYNC <- ';' / '\n' / '\r'

]]

local function printerror(label,line,col)
	print("Error #"..label..": "..errNames[label].." on line "..line.."(col "..col..")")
end


local function parse(input)
	result, errors = pg.parse(input,grammar,_,printerror)
	return result, errors
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	print(parse(arg[1]))
end
local ret = {parse=parse}
return ret
