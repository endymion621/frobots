--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by digitsu.
--- DateTime: 2021/12/01 11:28
---

--- random
--- random runs around the field randomly shooting everywhere

return function(state, ...)
    state = state or {}
    assert(
            type(state) == 'table',
            'Invalid state. Must receive a table'
    )
    math.randomseed( os.time() )
    math.random(); math.random(); math.random()
    state._type = "random"

    local function distance(x1,y1,x2,y2)
        local x = x1 -x2
        local y = y1 -y2
        local d = math.sqrt((x*x) + (y*y))
        return d
    end

    local function plot_course(xx,yy)
        local d
        local curx = loc_x()
        local cury = loc_y()
        local x = xx - curx
        local y = yy - cury

        if x == 0 then
            if yy > cury then
                d = 90.0
            else
                d = 270.0
            end
        else
            d = math.atan(y, x) * 180/math.pi
        end
        return d
    end

    state.damage = damage()
    state.locx = loc_x()
    state.locy = loc_y()
    state.speed = speed()

    if state.damage == nil then
        state.damage = damage()
    end
    if state.speed == nil or state.speed ~= speed() then
        state.speed = speed()
    end

    if state.dest == nil or state.dest == false then
        state.dest = {math.random(1000), math.random(1000)} --- go somewhere in the grid
        state.course = plot_course(state.dest[1], state.dest[2])
    end

    if distance(loc_x(), loc_y(), state.dest[1], state.dest[2]) < 50 then
        -- stop
        drive(state.course, 0)
        state.course = 0
        state.dest = false
    end
    if state.damage ~= damage() then
        drive(state.course, 0) -- stop!
        state.dest = false
    end

    drive(state.course, math.random(100))
    cannon(math.random(359), math.random(700))
    return state
end