MapArea = AABB:extend("MapArea")

MapArea.base_g = 375
MapArea.base_friction = 340

function MapArea:init(g, friction, x, y, w, h)
	self.g = g * MapArea.base_g
	self.friction = friction * MapArea.base_friction
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

function MapArea:draw()
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end