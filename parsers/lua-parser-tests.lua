local lua = require "lua-parser"
local filenames = {
--'all.lua',
'main.lua',
'gc.lua',
'db.lua',
'calls.lua',
'strings.lua',
'literals.lua',
'tpack.lua',
'attrib.lua',
'locals.lua',
'constructs.lua',
'code.lua',
'big.lua',
'nextvar.lua',
'pm.lua',
'utf8.lua',
'api.lua',
'events.lua',
'vararg.lua',
'closure.lua',
'coroutine.lua',
'goto.lua',
'errors.lua',
'math.lua',
'sort.lua',
'bitwise.lua',
'verybig.lua', 
'files.lua',
}
for k,v in ipairs(filenames) do
	local filename = "lua-5.3.4-tests/"..v
	local f = assert(io.open(filename, "r"))
	local t = f:read("*all")


	local res = lua.parse(t)
	local s = "OK"
	if not res then s = "FAIL" end
	print("Testing file '"..v.."': ["..s.."]")
	f:close()
end
