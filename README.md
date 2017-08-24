# parser-gen

A Lua parser generator that makes it possible to describe grammars in a [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) syntax. The tool will parse a given input using a provided grammar and if the matching is successful produce an AST as an output with the captured values using [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/). If the matching fails, labelled errors can be used in the grammar to indicate failure position, and recovery grammars are generated to continue parsing the input using [LpegLabel](https://github.com/sqmedeiros/lpeglabel). The tool can also automatically generate error labels and recovery grammars for LL(1) grammars.

parser-gen is a [GSoC 2017](https://developers.google.com/open-source/gsoc/) project, and was completed together with [LabLua](http://www.lua.inf.puc-rio.br/). A blog documenting the progress of the project can be found [here]().

---
# Requirements
```
lua >= 5.1
lpeglabel >= 1.2.0
```
# Syntax

### compile

All grammars have to be compiled using *compile*:

```lua
grammar = parser-gen.compile(input,definitions [, errorgen, noast])
```
*Arguments*:

`input` - input string, for example " 'a'* ". For complete syntax see grammar section.

`definitions` - table of custom functions and definitions used inside the grammar, for example {equals=equals}, where equals is a function.

`errorgen` - **EXPERIMENTAL** optional boolean parameter(default:false), when enabled generates error labels automatically. Works well only on LL(1) grammars.

`noast` - optional boolean parameter(default:false), when enabled does not generate an AST for the parse.

*Output*:

`grammar` - a compiled grammar on success, throws error on failure.

### setlabels

If custom error labels are used, the function *setlabels* allows setting their description (and custom recovery pattern):
```lua
parser-gen.setlabels(t)
```
Example table of a simple error and one with a custom recovery expression:
```lua
-- grammar rule: " ifexp <- 'if' exp 'then'^missingThen stmt 'end'^missingEnd "
local t = {
  missingEnd = "Missing 'end' in if expression",
  missingThen = {"Missing 'then' in if expression", " (!stmt .)* "} -- a custom recovery pattern
}
parser-gen.setlabels(t)
```
If the recovery pattern is not set, then the one specified by the rule SYNC will be used. It is by default set to:
```lua
SPACES <- %s / %nl -- a space ' ' or newline '\n' character
SYNC <- .? (!SPACES .)*
```
Learn more about special rules in the grammar section.

### parse

The main operation of the tool is *parse*:

```lua
result, errors = parser-gen.parse(input, grammar [, errorfunction])
```
*Arguments*:

`input` - an input string that the tool will attempt to parse.

`grammar` - a compiled grammar.

`errorfunction` - an optional function that will be called if an error is encountered, with the arguments `desc` for the error description set using `setlabels()`; location indicators `line` and `col`; the remaining string before failure `sfail` and a custom recovery expression `trec` if available.
Example:
```lua
local errs = 0
local function printerror(desc,line,col,sfail,trec)
	errs = errs+1
	print("Error #"..errs..": "..desc.." before '"..sfail.."' on line "..line.."(col "..col..")")
end

result, errors = pg.parse(input,grammar,printerror)
```
*Output*:

If the parse is succesful, the function returns an abstract syntax tree containing the captures `result` and a table of any encountered `errors`. If the parse was unsuccessful, `result` is going to be **nil**.
Also, if the `noast` option is enabled when compiling the grammar, the function will then produce the longest match length or any custom captures used.


Example of all functions: a parser for the Tiny language.

### Grammar
The grammar used for this tool is described using PEG-like syntax, that is identical to [relabel](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)

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
8. Error label: %{errorName}. Note that errors are generated automatically, but can be added to the grammar and will have precedence over the automatically generated ones.

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




