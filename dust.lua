Dust = class("Dust", {
	timer = 1,
	alive = true,
	lifespan = 1,
})

function Dust:init(x, y, scale)
	scale = math.min(scale, 2)

	self.x = x
	self.y = y
	self.v = 25 * scale
	self.size = 5 * scale
end

function Dust:draw()
	love.graphics.circle("line", self.x, self.y, self.size)
end

function Dust:update(dt)
	self.timer = self.timer - dt
	if self.timer <= 0 then
		self.alive = false
	else
		self.size = self.size * self.timer / self.lifespan
		self.y = self.y - self.v * dt
	end
end