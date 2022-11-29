--[[
This is a dumb target, just sits there
]]--
return function(state, ...)
    state = state or {}
    -- do nothing
    state.type = "target"
    return state
end