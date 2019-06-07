local animations = {
	idle = {
		loop = true,
		duration = 0.1,
		frames = {
			love.graphics.newImage("idle1.png"),
			love.graphics.newImage("idle2.png"),
			love.graphics.newImage("idle3.png"),
			love.graphics.newImage("idle4.png"),
		}
	},
	running = {
		loop = true,
		duration = 0.1,
		frames = { 
			love.graphics.newImage("r1.png"),
			love.graphics.newImage("r2.png"),
			love.graphics.newImage("r3.png"),
			love.graphics.newImage("r4.png"),
			love.graphics.newImage("r5.png"),
			love.graphics.newImage("r6.png"),
			love.graphics.newImage("r7.png"),
			love.graphics.newImage("r8.png"),
		}
	},
	wallhugging = {
		loop = true,
		duration = 0.1,
		frames = { love.graphics.newImage("wallhug.png") },
	},
	simpleJumping = {
		loop = false,
		duration = 0.05,
		frames = { 
			love.graphics.newImage("jump1.png"),
			love.graphics.newImage("jump1.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump4.png"),
		},
	},
	doubleJumping = {
		loop = false,
		duration = 0.05,
		frames = {
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump2.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump3.png"),
			love.graphics.newImage("jump4.png"),
		},
	},
}

local continueJumpingT = 0.2
local wallhuggingT = 0.12
local coyoteT = 0.12
local splashT = 0.07

Pj = class("Pj")

function Pj:init(x, y, scale)
	self.x = x
	self.y = y
	self.scale = scale
    self.w = 16 * scale
	self.h = 28 * scale
    self.v = { x = 0, y = 0 }
    self.a = { x = 600 * scale, y = 140 * scale }
	self.airCoeficient = { x = 0.6 }
    self.maxV = { x = 125 * scale, wallhugging = 32 * scale }
	self.stopVXthreshold = 5 * scale
	self.dieVY = 750 * scale
    self.jumpState = "doubleJump"
	self.coyoteTimer = 0
	self.wallhuggingTimer = 0
	self.wallhuggingDirection = 0
	self.continueJumpingTimer = 0
	self.splashTimer = 0
	self.animationTimer = 0
	self.currentAnimation = "idle"
	self.currentAnimationFrame = 0
	self.lookDirection = 1
	self.dustParticles = {}
	
	self.g = 375 * scale
	self.friction = 340 * scale
	
	self:setCheckpoint()
end


function Pj:setScale(scale)

	local newW, newH = 16*scale, 28*scale
	local newX = self.x + self.w/2 - newW/2
	local newY = self.y + self.h - newH - scale
	
	-- don't change the scale if the new sized collider intersects the stage
	if scale > self.scale then
		for k, collider in ipairs(world.colliders) do
			if collider:intersects(newX, newY, newW, newH) then return end
		end
	end
	
	self.x = newX
	self.y = newY
	self.w = newW
	self.h = newH
	
	self.scale = scale
    self.a = { x = 600 * scale, y = 140 * scale }
    self.maxV = { x = 125 * scale, wallhugging = 32 * scale }
	self.stopVXthreshold = 5 * scale
	self.dieVY = 750 * scale
	
	self.g = 375 * scale
	self.friction = 340 * scale
end


function Pj:draw()
	for k, v in ipairs(self.dustParticles) do v:draw() end

	-- debug next size
	--[[
	local scale = self.scale+1
	local newW, newH = 16*scale, 28*scale
	local newX = self.x + self.w/2 - newW/2
	local newY = self.y + self.h - newH - scale
	love.graphics.rectangle("line", newX, newY, newW, newH)
	]]
	
	--love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	local originX = animations.idle.frames[1]:getWidth()/2
	local splash = self.splashTimer * 5
	love.graphics.draw(animations[self.currentAnimation].frames[self.currentAnimationFrame], self.x+originX*self.scale, self.y+splash*self.h, 0, self.lookDirection*self.scale*(1+splash), self.scale*(1-splash), originX, 0)
end


function Pj:update(dt)
	
	self:applyAreaModifiers()
	self:movementCollision(dt)
	
	if self.coyoteTimer > 0 then
		self.coyoteTimer = self.coyoteTimer - dt
		if self.coyoteTimer <= 0 then
			self.coyoteTimer = 0
			self.jumpState = "simpleJump"
		end
	end
	
	if self.wallhuggingTimer > 0 then
		self.wallhuggingTimer = self.wallhuggingTimer - dt
		if self.wallhuggingTimer <= 0 then
			self.wallhuggingTimer = 0
			self.wallhuggingDirection = 0
			self.jumpState = "simpleJump"
		end
	end
	
	if self.continueJumpingTimer > 0 then
		self.continueJumpingTimer = self.continueJumpingTimer - dt
		if self.continueJumpingTimer <= 0 then
			self.continueJumpingTimer = 0
		end
	end
	
	if self.splashTimer > 0 then
		self.splashTimer = self.splashTimer - dt
		if self.splashTimer <= 0 then
			self.splashTimer = 0
		end
	end

	if self.wallhuggingTimer > 0 then self:setCurrentAnimation("wallhugging")
	elseif self.jumpState ~= "ground" then 
		if self.jumpState == "simpleJump" then 
			self:setCurrentAnimation("simpleJumping")
		elseif self.jumpState == "doubleJump" then
			self:setCurrentAnimation("doubleJumping")
		end
	elseif (self.v.x ~= 0 and (love.keyboard.isDown("a") or love.keyboard.isDown("d"))) then 
		self:setCurrentAnimation("running")
	else self:setCurrentAnimation("idle") end

	
	self.animationTimer = self.animationTimer - dt
	if self.animationTimer <= 0 then
		self.animationTimer = self.animationTimer + animations[self.currentAnimation].duration
		self.currentAnimationFrame = self.currentAnimationFrame + 1
		if self.currentAnimationFrame > #animations[self.currentAnimation].frames then
			if animations[self.currentAnimation].loop then
				self.currentAnimationFrame = 1
			else
				self.currentAnimationFrame = self.currentAnimationFrame-1
			end
		end
	end
	
	for k, v in ipairs(self.dustParticles) do
		v:update(dt)
		if not v.alive then table.remove(self.dustParticles, k) end
	end
end


function Pj:applyAreaModifiers()
	local area_ed = false
	for k, mapArea in ipairs(world.areas) do
		if mapArea:intersects(self.x, self.y, self.w, self.h) then
			area_ed = true
			self.g = mapArea.g * self.scale
			self.friction = mapArea.friction * self.scale
		end
	end
	if not area_ed then
		self.g = MapArea.base_g * self.scale
		self.friction = MapArea.base_friction * self.scale
	end
end


function Pj:movementCollision(dt)
	-- set input direction
	local inputDirection = 0
	if love.keyboard.isDown("a") then inputDirection = inputDirection - 1 end
	if love.keyboard.isDown("d") then inputDirection = inputDirection + 1 end
	
	if inputDirection ~= 0 then
		-- apply acceleration
		local airCoeficient = (self.jumpState == "simpleJump" or self.jumpState == "doubleJump") and self.airCoeficient.x or 1
		self.v.x = self.v.x + self.a.x * inputDirection * airCoeficient * dt
		
		-- set direction of the sprite
		self.lookDirection = inputDirection
	else
		-- apply friction
		local movementDirection = 0
		if self.v.x > 0 then movementDirection =  1 end
		if self.v.x < 0 then movementDirection = -1 end
		self.v.x = self.v.x - self.friction * movementDirection * dt
	end
	
	-- clamp to maxV
	if math.abs(self.v.x) > self.maxV.x then self.v.x = self.v.x/math.abs(self.v.x) * self.maxV.x end
	
	-- stop if under threshold
	if math.abs(self.v.x) < self.stopVXthreshold then self.v.x = 0 end
	
	-- update x
	self.x = self.x + self.v.x * dt
	
	-- collision on the x-axis
	for k, collider in ipairs(world.colliders) do
		if collider:intersects(self.x, self.y, self.w, self.h) then
		
			if collider:instanceOf(Spikes) then 
				self:die()
		
			else
				self.x = collider.x + ((self.v.x > 0) and -self.w or collider.w)
				self.v.x = 0
				
				-- wallhugging
				if self.v.y ~= 0 then
					self.wallhuggingTimer = wallhuggingT
					self.wallhuggingDirection = inputDirection
				end
			end
			
			break
		end
	end

	--------------------------------------------------------------
	
	if pressSpaceEvent then 
		pressSpaceEvent = false
		if self.jumpState == "ground" or self.jumpState == "simpleJump" or self.wallhuggingTimer > 0 then
			self.continueJumpingTimer = continueJumpingT
			self.v.y = -self.a.y
			self:dust()
			
			if self.wallhuggingTimer > 0 then
				self.wallhuggingTimer = 0
				self.v.x = -self.wallhuggingDirection * self.a.y
				self.wallhuggingDirection = 0
				self.jumpState = "simpleJump"
			elseif self.jumpState == "ground" then
				self.jumpState = "simpleJump"
				self:setCheckpoint()
			else self.jumpState = "doubleJump" end
		end
	end
	
	if self.continueJumpingTimer > 0 then
		if not love.keyboard.isDown("space") then self.continueJumpingTimer = 0 end
	else 
		-- apply gravity
		self.v.y = self.v.y + self.g * dt 
	end
	
	-- die if you fall long enough
	if self.v.y > self.dieVY then
		self:die()
	end
	
	-- clamp v if wallhugging
	if self.wallhuggingTimer > 0 and self.v.y > self.maxV.wallhugging then 
		self.v.y = self.maxV.wallhugging 
	end

	-- update y
	self.y = self.y + self.v.y * dt

	-- collision on the y-axis
	for k, collider in ipairs(world.colliders) do
		if collider:intersects(self.x, self.y, self.w, self.h) then
		
			if collider:instanceOf(Spikes) then 
				self:die()
		
			else
				self.y = collider.y + ((self.v.y > 0) and -self.h or collider.h)
				if self.v.y > 0 then 
					if self.jumpState ~= "ground" then 
						self.splashTimer = splashT
						self:dust()
						self:setCheckpoint()
					end
					self.jumpState = "ground"
				end
				self.v.y = 0
			end
			
			return
		end
	end
	
	if self.jumpState == "ground" and self.coyoteTimer == 0 then
		self.coyoteTimer = coyoteT 
	end
end


function Pj:die()
	if self.lastPlatform.scale ~= self.scale then
		self:setScale(self.lastPlatform.scale)
	end
	self.v.x, self.v.y = 0, 0
	self.x = self.lastPlatform.x
	self.y = self.lastPlatform.y
end


function Pj:setCurrentAnimation(animation)
	if self.currentAnimation ~= animation then
		self.currentAnimation = animation
		self.currentAnimationFrame = 1
		self.animationTimer = animations[self.currentAnimation].duration
	end
end


function Pj:dust()
	table.insert(self.dustParticles, Dust(self.x+self.w/2, self.y+self.h, self.scale))
end

function Pj:setCheckpoint()
	self.lastPlatform = { x = self.x, y = self.y, scale = self.scale }
end