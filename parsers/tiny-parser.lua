pg = require "parser-gen"
grammar = [[
program <- stmt-sequence EOF;
stmt-sequence <- statement (';' statement)*;
statement <- if-stmt / repeat-stmt / assign-stmt / read-stmt / write-stmt;
if-stmt <- 'if' exp 'then'^{errMissingThen} stmt-sequence ('else' stmt-sequence)? 'end';
repeat-stmt <- 'repeat' stmt-sequence 'until' exp;
assign-stmt <- identifier ':=' exp;
read-stmt <- 'read' identifier;
write-stmt <- 'write' exp;
exp <- simple-exp (COMPARISON-OP simple-exp)*;
COMPARISON-OP <- '<' / '=';
simple-exp <- term (ADD-OP term)*;
ADD-OP <- '+' / '-';
term <- factor (MUL-OP factor)*;
MUL-OP <- '*' / '/';
factor <- '(' exp ')' / NUMBER / IDENTIFIER;

NUMBER <- '-'? [09]+;
IDENTIFIER <- ([az] / [AZ])+;

SYNC <- ';' / '\n' / '\r';

]]

function printerror(label,error,line,col)
  print("Error #"..label..": "..error.." on line "..line.."(col "..col..")")
end
input = "a:=1; if b=3 then c else d end"
result = pg.parse(input,grammar,printerror)
