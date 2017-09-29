# parser-gen

A Lua parser generator that makes it possible to describe grammars in a [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) syntax. The tool will parse a given input using a provided grammar and if the matching is successful produce an AST as an output with the captured values using [Lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/). If the matching fails, labelled errors can be used in the grammar to indicate failure position, and recovery grammars are generated to continue parsing the input using [LpegLabel](https://github.com/sqmedeiros/lpeglabel). The tool can also automatically generate error labels and recovery grammars for LL(1) grammars.

parser-gen is a [GSoC 2017](https://developers.google.com/open-source/gsoc/) project, and was completed with the help of my mentor [@sqmedeiros](https://github.com/sqmedeiros) from [LabLua](http://www.lua.inf.puc-rio.br/). A blog documenting the progress of the project can be found [here](https://parsergen.blogspot.com/2017/08/parser-generator-based-on-lpeglabel.html).

---
# Table of contents

* [Requirements](#requirements)

* [Syntax](#syntax)

* [Grammar Syntax](#grammar-syntax)

* [Example: Tiny Parser](#example-tiny-parser)

# Requirements
```
lua >= 5.1
lpeglabel >= 1.2.0
```
# Syntax

### compile

This function generates a PEG parser from the grammar description.

```lua
local pg = require "parser-gen"
grammar = pg.compile(input,definitions [, errorgen, noast])
```
*Arguments*:

`input` - A string containing a PEG grammar description. For complete PEG syntax see the grammar section of this document.

`definitions` - table of custom functions and definitions used inside the grammar, for example {equals=equals}, where equals is a function.

`errorgen` - **EXPERIMENTAL** optional boolean parameter(default:false), when enabled generates error labels automatically. Works well only on LL(1) grammars. Custom error labels have precedence over automatically generated ones.

`noast` - optional boolean parameter(default:false), when enabled does not generate an AST for the parse.

*Output*:

`grammar` - a compiled grammar on success, throws error on failure.

### setlabels

If custom error labels are used, the function *setlabels* allows setting their description (and custom recovery pattern):
```lua
pg.setlabels(t)
```
Example table of a simple error and one with a custom recovery expression:
```lua
-- grammar rule: " ifexp <- 'if' exp 'then'^missingThen stmt 'end'^missingEnd "
local t = {
	missingEnd = "Missing 'end' in if expression",
	missingThen = {"Missing 'then' in if expression", " (!stmt .)* "} -- a custom recovery pattern
}
pg.setlabels(t)
```
If the recovery pattern is not set, then the one specified by the rule SYNC will be used. It is by default set to:
```lua
SKIP <- %s / %nl -- a space ' ' or newline '\n' character
SYNC <- .? (!SKIP .)*
```
Learn more about special rules in the grammar section.

### parse

This operation attempts to match a grammar to the given input.

```lua
result, errors = pg.parse(input, grammar [, errorfunction])
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

### calcline

Calculates line and column information regarding position i of the subject (exported from the relabel module).

```lua
line, col = pg.calcline(subject, position)
```
*Arguments*:

`subject` - subject string

`position` - position inside the string, for example, the one given by automatic AST generation.

### usenodes

When AST generation is enabled, this function will enable the "node" mode, where only rules tagged with a `node` prefix will generate AST entries. Must be used before compiling the grammar.

```lua
pg.usenodes(value)
```
*Arguments*:

`value` - a boolean value that enables or disables this function

# Grammar Syntax

The grammar used for this tool is described using a PEG-like syntax, that is identical to the one provided by the [re](http://www.inf.puc-rio.br/~roberto/lpeg/re.html) module, with an extension of labelled failures provided by [relabel](https://github.com/sqmedeiros/lpeglabel) module (except numbered labels). That is, all grammars that work with relabel should work with parser-gen as long as numbered error labels are not used, as they are not supported by parser-gen.

Since a parser generated with parser-gen automatically consumes space characters, builds ASTs and generates errors, additional extensions have been added based on the [ANTLR](http://www.antlr.org/) syntax.

### Basic syntax

The syntax of parser-gen grammars is somewhat similar to regex syntax. The next table summarizes the tools syntax. A p represents an arbitrary pattern; num represents a number (`[0-9]+`); name represents an identifier (`[a-zA-Z][a-zA-Z0-9_]*`).`defs` is the definitions table provided when compiling the grammar. Note that error names must be set using `setlabels()` before compiling the grammar. Constructions are listed in order of decreasing precedence.

<table border="1">
<tbody><tr><td><b>Syntax</b></td><td><b>Description</b></td></tr>
<tr><td><code>( p )</code></td> <td>grouping</td></tr>
<tr><td><code>'string'</code></td> <td>literal string</td></tr>
<tr><td><code>"string"</code></td> <td>literal string</td></tr>
<tr><td><code>[class]</code></td> <td>character class</td></tr>
<tr><td><code>.</code></td> <td>any character</td></tr>
<tr><td><code>%name</code></td>
  <td>pattern <code>defs[name]</code> or a pre-defined pattern</td></tr>
<tr><td><code>name</code></td><td>non terminal</td></tr>
<tr><td><code>&lt;name&gt;</code></td><td>non terminal</td></tr>
<tr><td><code>%{name}</code></td> <td>error label</td></tr>
<tr><td><code>{}</code></td> <td>position capture</td></tr>
<tr><td><code>{ p }</code></td> <td>simple capture</td></tr>
<tr><td><code>{: p :}</code></td> <td>anonymous group capture</td></tr>
<tr><td><code>{:name: p :}</code></td> <td>named group capture</td></tr>
<tr><td><code>{~ p ~}</code></td> <td>substitution capture</td></tr>
<tr><td><code>{| p |}</code></td> <td>table capture</td></tr>
<tr><td><code>=name</code></td> <td>back reference
</td></tr>
<tr><td><code>p ?</code></td> <td>optional match</td></tr>
<tr><td><code>p *</code></td> <td>zero or more repetitions</td></tr>
<tr><td><code>p +</code></td> <td>one or more repetitions</td></tr>
<tr><td><code>p^num</code></td> <td>exactly <code>n</code> repetitions</td></tr>
<tr><td><code>p^+num</code></td>
      <td>at least <code>n</code> repetitions</td></tr>
<tr><td><code>p^-num</code></td>
      <td>at most <code>n</code> repetitions</td></tr>
<tr><td><code>p^name</code></td> <td>match p or throw error label name.</td></tr>
<tr><td><code>p -&gt; 'string'</code></td> <td>string capture</td></tr>
<tr><td><code>p -&gt; "string"</code></td> <td>string capture</td></tr>
<tr><td><code>p -&gt; num</code></td> <td>numbered capture</td></tr>
<tr><td><code>p -&gt; name</code></td> <td>function/query/string capture
equivalent to <code>p / defs[name]</code></td></tr>
<tr><td><code>p =&gt; name</code></td> <td>match-time capture
equivalent to <code>lpeg.Cmt(p, defs[name])</code></td></tr>
<tr><td><code>&amp; p</code></td> <td>and predicate</td></tr>
<tr><td><code>! p</code></td> <td>not predicate</td></tr>
<tr><td><code>p1 p2</code></td> <td>concatenation</td></tr>
<tr><td><code>p1 //{name [, name, ...]} p2</code></td> <td>specifies recovery pattern p2 for p1
when one of the labels is thrown</td></tr>	
<tr><td><code>p1 / p2</code></td> <td>ordered choice</td></tr>
<tr><td>(<code>name &lt;- p</code>)<sup>+</sup></td> <td>grammar</td></tr>
</tbody></table>


The grammar below is used to match balanced parenthesis

```lua
balanced <- "(" ([^()] / balanced)* ")" 
```
For more examples check out the [re](http://www.inf.puc-rio.br/~roberto/lpeg/re.html) page, see the Tiny parser below or the [Lua parser](https://github.com/vsbenas/parser-gen/blob/master/parsers/lua-parser.lua) writen with this tool.

### Error labels

Error labels are provided by the relabel function %{errorname} (errorname must follow `[A-Za-z][A-Za-z0-9_]*` format). Usually we use error labels in a syntax like `'a' ('b' / %{errB}) 'c'`, which throws an error label if `'b'` is not matched. This syntax is quite complicated so an additional syntax is allowed `'a' 'b'^errB 'c'`, which allows cleaner description of grammars. Note: all errors must be defined in a table using parser-gen.setlabels() before compiling and parsing the grammar.

### Tokens

Non-terminals with names in all capital letters, i.e. `[A-Z]+`, are considered tokens and are treated as a single object in parsing. That is, the whole string matched by a token is captured in a single AST entry and space characters are not consumed. Consider two examples:
```lua
-- a token non-terminal
grammar = pg.compile [[
	WORD <- [A-Z]+
]]
res, _ = pg.parse("AA A", grammar) -- outputs {rule="WORD", "AA"}
```
```lua
-- a non-token non-terminal
grammar = pg.compile [[
	word <- [A-Z]+
]]
res, _ = pg.parse("AA A", grammar) -- outputs {rule="word", "A", "A", "A"}
```

### Fragments

If a token definition is followed by a `fragment` keyword, then the parser does not build an AST entry for that token. Essentially, these rules are used to simplify grammars without building unnecessarily complicated ASTS. Example of `fragment` usage:
```lua
grammar = pg.compile [[
	WORD <- LETTER+
	fragment LETTER <- [A-Z]
]]
res, _ = pg.parse("AA A", grammar) -- outputs {rule="WORD", "AA"}
```
Without using `fragment`:
```lua
grammar = pg.compile [[
	WORD <- LETTER+
	LETTER <- [A-Z]
]]
res, _ = pg.parse("AA A", grammar) -- outputs {rule="WORD", {rule="LETTER", "A"}, {rule="LETTER", "A"}}

```

### Nodes

When node mode is enabled using `pg.usenodes(true)` only rules prefixed with a `node` keyword will generate AST entries:
```lua
grammar = pg.compile [[
	node WORD <- LETTER+
	LETTER <- [A-Z]
]]
res, _ = pg.parse("AA A", grammar) -- outputs {rule="WORD", "AA"}
```
### Special rules

There are two special rules used by the grammar:

#### SKIP

The `SKIP` rule identifies which characters to skip in a grammar. For example, most programming languages do not take into acount any space or newline characters. By default, SKIP is set to:
```lua
SKIP <- %s / %nl
```
This rule can be extended to contain semicolons `';'`, comments, or any other patterns that the parser can safely ignore.

Character skipping can be disabled by using:
```lua
SKIP <- ''
```

#### SYNC

This rule specifies the general recovery expression both for custom errors and automatically generated ones. By default:
```lua
SYNC <- .? (!SKIP .)*
```
The default SYNC rule consumes any characters until the next character matched by SKIP, usually a space or a newline. That means, if some statement in a program is invalid, the parser will continue parsing after a space or a newline character.

For some programming languages it might be useful to skip to a semicolon or a keyword, since they usually indicate the end of a statement, so SYNC could be something like:
```lua
HELPER <- ';' / 'end' / SKIP -- etc
SYNC <- (!HELPER .)* SKIP* -- we can consume the spaces after syncing with them as well
```

Recovery grammars can be disabled by using:
```lua
SYNC <- ''
```
# Example: Tiny parser

Below is the full code from *parsers/tiny-parser.lua*:
```lua
local pg = require "parser-gen"
local peg = require "peg-parser"
local errs = {errMissingThen = "Missing Then"} -- one custom error
pg.setlabels(errs)

--warning: experimental error generation function is enabled. If the grammar isn't LL(1), set errorgen to false
local errorgen = true

local grammar = pg.compile([[

	program			<- stmtsequence !. 
	stmtsequence		<- statement (';' statement)* 
	statement 		<- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
	ifstmt 			<- 'if' exp 'then'^errMissingThen stmtsequence elsestmt? 'end' 
	elsestmt		<- ('else' stmtsequence)
	repeatstmt		<- 'repeat' stmtsequence 'until' exp 
	assignstmt		<- IDENTIFIER ':=' exp 
	readstmt		<- 'read'  IDENTIFIER 
	writestmt		<- 'write' exp 
	exp 			<- simpleexp (COMPARISONOP simpleexp)*
	COMPARISONOP		<- '<' / '='
	simpleexp		<- term (ADDOP term)* 
	ADDOP			<- [+-]
	term			<- factor (MULOP factor)*
	MULOP			<- [*/]
	factor			<- '(' exp ')' / NUMBER / IDENTIFIER

	NUMBER			<- '-'? [0-9]+
	KEYWORDS		<- 'if' / 'repeat' / 'read' / 'write' / 'then' / 'else' / 'end' / 'until' 
	RESERVED		<- KEYWORDS ![a-zA-Z]
	IDENTIFIER		<- !RESERVED [a-zA-Z]+
	HELPER			<- ';' / %nl / %s / KEYWORDS / !.
	SYNC			<- (!HELPER .)*

]], _, errorgen)

local errors = 0
local function printerror(desc,line,col,sfail,trec)
	errors = errors+1
	print("Error #"..errors..": "..desc.." on line "..line.."(col "..col..")")
end


local function parse(input)
	errors = 0
	result, errors = pg.parse(input,grammar,printerror)
	return result, errors
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	res, errs = parse(arg[1])
	peg.print_t(res)
	peg.print_r(errs)
end
local ret = {parse=parse}
return ret
```
For input: `lua tiny-parser-nocap.lua "if a b:=1"` we get:
```lua
Error #1: Missing Then on line 1(col 6)
Error #2: Expected stmtsequence on line 1(col 9)
Error #3: Expected 'end' on line 1(col 9)
-- ast:
rule='program',
pos=1,
{
         rule='stmtsequence',
         pos=1,
         {
                  rule='statement',
                  pos=1,
                  {
                           rule='ifstmt',
                           pos=1,
                           'if',
                           {
                                    rule='exp',
                                    pos=4,
                                    {
                                             rule='simpleexp',
                                             pos=4,
                                             {
                                                      rule='term',
                                                      pos=4,
                                                      {
                                                               rule='factor',
                                                               pos=4,
                                                               {
                                                                        rule='IDENTIFIER',
                                                                        pos=4,
                                                                        'a',
                                                               },
                                                      },
                                             },
                                    },
                           },
                  },
         },
},
-- error table:
[1] => {
         [msg] => 'Missing Then' -- custom error is used over the automatically generated one
         [line] => '1'
         [col] => '6'
         [label] => 'errMissingThen'
       }
[2] => {
         [msg] => 'Expected stmtsequence' -- automatically generated errors
         [line] => '1'
         [col] => '9'
         [label] => 'errorgen6'
       }
[3] => {
         [msg] => 'Expected 'end''
         [line] => '1'
         [col] => '9'
         [label] => 'errorgen4'
       }
```


