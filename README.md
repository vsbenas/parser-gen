# parser-gen
A Lua parser generator that makes it possible to describe grammars in a [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) syntax. The tool will parse a given input and if the matching is successful produce an AST as an output with the captured values using [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/). If the matching fails, the tool can also generate automatic errors for common idioms and generate recovery patterns using [LpegLabel](https://github.com/sqmedeiros/lpeglabel).

---
### Syntax
The main operation of the tool is *parse*:
```lua
parser-gen.parse(input, grammar [, errorfunction])
```
Arguments:

*input* - the string to be parsed

*grammar* - a PEG grammar, explained below

*errorfunction* - optional, a function that will be called if an error is encountered, with the arguments *label* for the error label and *error* a short description of the error, *line* for the line in which the error was encountered and *col* for the column.

Output:
If the parse is succesful, the function returns an abstract syntax tree containing the captures. Otherwise, the function returns **nil**. If the grammar is invalid, the function throws a run-time error.

Example: a parser for Tiny
```lua
pg = require "parser-gen"
grammar = [[
program <- stmt-sequence;
stmt-sequence <- statement (';' statement)*;
statement <- if-stmt / repeat-stmt / assign-stmt / read-stmt / write-stmt;
if-stmt <- 'if' exp 'then' stmt-sequence ('else' stmt-sequence)? 'end';
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

]]

function printerror(label,error,line,col)
  print("Error #"..label..": "..error.." on line "..line.."(col "..col..")")
end
input = "a:=1; if b=3 then c else d end"
result = pg.parse(input,grammar,printerror)
```

### Grammar
The grammar used for this tool is described using PEG-like syntax with some additional restrictions, explained below.

**Atomic parsing expressions**

1. Terminal symbols are represented using single quotes. ``'abc'`` matches the string "abc", ``'\''`` matches the literal single quote "'". It is also possible to define ranges of symbols using square brackets: ``[az]`` is going to match any lower-case letter.
2. Non-terminal symbols are represented using alphanumeric strings, with tokens named in all capital letters(A-Z).
3. The empty string is represented using two single quotation marks. ``''``
4. End of file is described by the acronym ``EOF``.

Atomic parsing expressions **e<sub>1</sub>** and **e<sub>2</sub>** can be combined:

1. Sequence: **e<sub>1</sub>** **e<sub>2</sub>**
2. Ordered choice: **e<sub>1</sub>** / **e<sub>2</sub>**. Note that if **e<sub>1</sub>** is matched, **e<sub>2</sub>** is not considered.
3. Zero-or-more: **e<sub>1</sub>***
4. One-or-more: **e<sub>1</sub>**+
5. Optional: **e<sub>1</sub>**?
6. And-predicate: &**e<sub>1</sub>**. Consumes no input.
7. Not-predicate: !**e<sub>1</sub>**. Consumes no input.
8. Error label: **e<sub>1</sub>**^{errorName}. Note that errors are generated automatically, but can be added to the grammar and will have precedence over the automatically generated ones.

More detailed descriptions (including prioritization) of these can be found [here](https://en.wikipedia.org/wiki/Parsing_expression_grammar).




All grammar rules follow this syntax:
``
RuleName <- Expression;
``
RuleName is an identifier of the rule. If the name of the rule is capitalized then it is considered a token.
The example bellow will match any number of lower-case words seperated by spaces.
```lua
grammar = [[
Rule <- WORD*;
WORD <- ('a' / [bz])+; -- a lowercase word
]]
```

The first rule in the grammar will be considered the initial rule.

Comments in the grammar can be written using the same way as in [Lua](https://www.lua.org/pil/1.3.html).

**Special rules**

*SPACES* defines the different symbols that the parser skips around tokens (and terminals in non-token rules). It is by default defined as:
```lua
SPACES <- ' ' / '\n' / '\r' / '\t'
```
The rule can be overwritten by adding it to the grammar, the example below will NOT consume spaces around tokens:
```lua
SPACES <- ''
```

*SYNC* defines the symbols that the parser will skip to if an error is encountered. By default it skips to the end of the line:
```lua
SYNC <- '\n' / '\r'
```
For some programming languages it might be useful to skip to a semicolon, by adding the following rule in the grammar:
```lua
SYNC <- ';' / '\n' / '\r'
```




