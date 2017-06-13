local lpeg = require "lpeglabel"

lpeg.locale(lpeg)

local P = lpeg.P
local T = lpeg.T -- lpeglabel
local space = lpeg.space

function lpeg.sync (patt)
	return (-patt * P(1))^0 -- skip until we find pattern
end

lpeg.Skip = (space)^0

function lpeg.setSpace(patt)
	Skip = patt^0
end

function lpeg.token (patt)
	return patt * Skip
end


function lpeg.sym (str)
	return token(P(str))
end

function lpeg.kw (str)
	return token(P(str))
end


function lpeg.try (patt, err)
	return patt + T(err)
end

function lpeg.throws (patt,err) -- if pattern is matched throw error
	return patt * T(err)
end

return lpeg