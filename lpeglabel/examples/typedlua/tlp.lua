local tlparser = require "tlparser"

local function getcontents(filename)
  file = assert(io.open(filename, "r"))
  contents = file:read("*a")
  file:close()
  return contents
end

if #arg ~= 1 then
  print ("Usage: lua tlp.lua <file>")
  os.exit(1)
end

local filename = arg[1]
local subject = getcontents(filename)
local r, msg = tlparser.parse(subject, filename, false, true)
if not r then print(msg) end

os.exit(0)
