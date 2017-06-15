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
	lpeg.Skip = patt^0
end

function lpeg.token (patt)
	return patt * lpeg.Skip
end


function lpeg.sym (str)
	return token(P(str))
end

function lpeg.kw (str)
	return lpeg.token(P(str))
end


function lpeg.try (patt, err)
	return patt + T(err)
end

function lpeg.throws (patt,err) -- if pattern is matched throw error
	return patt * T(err)
end


function lpeg.print_r ( t )  -- for debugging
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"")
end

return lpeg