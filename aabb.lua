AABB = class("AABB", {
    x = 0, y = 0, w = 0, h = 0
})

AABB.color = { 255, 255, 255 }
local pixel = love.graphics.newImage("pixel.png")

function AABB:init(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end


function AABB:draw()
	love.graphics.draw(pixel, self.x, self.y, 0, self.w, self.h)
end


function AABB:contains(x, y)
    if x <= self.x or x >= self.x + self.w
    or y <= self.y or y >= self.y + self.h then
        return false
    else
        return true
    end
end


function AABB:intersects(x, y, w, h)
	if x + w <= self.x or x >= self.x + self.w
	or y + h <= self.y or y >= self.y + self.h then
		return false
	else
		return true
	end
end

function AABB:serialize()
	return "    AABB(" .. self.x .. ", " .. self.y .. ", " .. self.w .. ", " .. self.h .. "),\n"
end


--------------------------


Spikes = AABB:extend("Spikes")


function Spikes:draw()
	local r, g, b = love.graphics.getColor()
	love.graphics.setColor(211, 10, 0)
	love.graphics.draw(pixel, self.x, self.y, 0, self.w, self.h)
	love.graphics.setColor(r, g, b)
end


function Spikes:serialize()
	return "    Spikes(" .. self.x .. ", " .. self.y .. ", " .. self.w .. ", " .. self.h .. "),\n"
end

