-- FROBOTS TEMPLATE
-- 
-- scan (degree,resolution)
-- cannon (degree,range)
-- drive (degree,speed)
-- damage()
-- speed() // blocking
-- loc_x() / loc_y() / blocking

-- the main state variable is what the Virtual machine (your CPU) passes your Frobotbrain code. It contains all the information that you need persisted between execution loops.  Feel free to store anything there, it is a simple Lua table.

--- Some available state internals that you can use
--- state._status (this is displayed on the UX as what your frobot is doing, like a STDOUT)
--- state._debug (this is displayed in the debug UX, think of this as a STDERR)
--- state._type (this is the type of your frobot... which prototype class it was started from)
---
return function(state, ...)
    return state
end