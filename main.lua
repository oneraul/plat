love.graphics.setDefaultFilter("nearest", "nearest", 1)

require '30log-global'
require 'aabb'
require 'maparea'
require 'pj'
require 'dust'

local pj = Pj(50, 200, 1)

local cameraX, cameraY = 0, 0

local oldColor = { math.random()*255, math.random()*255, math.random()*255 }
local newColor = { math.random()*255, math.random()*255, math.random()*255 }
local colorTimer = 0
local colorT = 0.05

world = { 
	colliders = require 'map',
	areas = require 'map_areas',
}

function love.update(dt)
	dt = math.min(0.1, dt)
	pj:update(dt)
	
	colorTimer = colorTimer + dt
	if colorTimer >= colorT then
		colorTimer = colorTimer - colorT
		oldColor[1], oldColor[2], oldColor[3] = newColor[1], newColor[2], newColor[3] 
		newColor[1], newColor[2], newColor[3] = math.random()*255, math.random()*255, math.random()*255
	end
	
	if tmpGuiMessageTimer then
		tmpGuiMessageTimer = tmpGuiMessageTimer - dt
		if tmpGuiMessageTimer <= 0 then
			tmpGuiMessageTimer = nil
			guiMessage = nil
		end
	end
end


function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		pressSpaceEvent = true
		
	elseif key == "r" then
		local newScale = (pj.scale+1 <= 4) and pj.scale+1 or 1
		pj:setScale(newScale)
	
	elseif key == "g" then
		if love.keyboard.isDown("lctrl", "rctrl") then
			exportMap()
			printTempGuiMessage("Map saved")
		end
	
	elseif key == "f1" then
		guiMessage = "Select collider: 0"
		selectedColliderIndex = 0
		
	elseif key == "f2" then
		selectedColliderIndex = #world.colliders
		selectedCollider = world.colliders[selectedColliderIndex]
		guiMessage = "selectedCollider: " .. selectedColliderIndex
		
	elseif key == "escape" then
		guiMessage = nil
		tmpGuiMessageTimer = nil
		selectedCollider = nil
		selectedColliderIndex = nil
	
	elseif tonumber(key) ~= nil then
		if selectedColliderIndex then
			selectedColliderIndex = selectedColliderIndex * 10 + tonumber(key)
			if world.colliders[selectedColliderIndex] then 
				selectedCollider = world.colliders[selectedColliderIndex]
				guiMessage = "Select collider: " .. selectedColliderIndex
			else 
				selectedColliderIndex = nil
				selectedCollider = nil
				printTempGuiMessage("Error: the collider doesn't exist")
			end
		end
		
	elseif key == "backspace" then
		if selectedCollider then
			table.remove(world.colliders, selectedColliderIndex)
			selectedCollider = nil
			selectedColliderIndex = nil
			printTempGuiMessage("Collider deleted")
		end
		
	elseif key == "p" then
		if selectedCollider then
			table.insert(world.colliders, Spikes(selectedCollider.x, selectedCollider.y, selectedCollider.w, selectedCollider.h))
			table.remove(world.colliders, selectedColliderIndex)
			selectedCollider = nil
			selectedColliderIndex = nil
			printTempGuiMessage("Spikes added")
		end
	
	elseif key == "left" or key == "right" or key == "up" or key == "down" then
		if not manualCamera then
			manualCamera = {x = cameraX, y = cameraY}
		end
		
		if key == "up"    then manualCamera.y = manualCamera.y + 100 end
		if key == "left"  then manualCamera.x = manualCamera.x + 100 end
		if key == "down"  then manualCamera.y = manualCamera.y - 100 end
		if key == "right" then manualCamera.x = manualCamera.x - 100 end
	
	end
end


function printTempGuiMessage(str)
	guiMessage = str
	tmpGuiMessageTimer = 1
end


function love.draw()
	--[[
	local color = {}
	local a = colorTimer / colorT
	for i = 1, 3 do color[i] = a * newColor[i] + (1-a) * oldColor[i] end
	love.graphics.setColor(color)
	]]
	
	love.graphics.clear(112, 150, 115)
	love.graphics.setColor(230, 244, 198)
	
	moveCamera()
	
	love.graphics.setColor(0, 100, 100)
	for k, area in ipairs(world.areas) do
		area:draw()
	end
	
	love.graphics.setColor(230, 244, 198)
	
    for k, aabb in ipairs(world.colliders) do
		aabb:draw()
    end
    
    pj:draw()
	
	-------------------------------------
	
	love.graphics.setColor(255, 0, 0)
	for k, aabb in ipairs(world.colliders) do
		love.graphics.print(k, aabb.x-20, aabb.y)
	end
	
	if NewCollider then
		love.graphics.rectangle("line", NewCollider.x, NewCollider.y, NewCollider.w, NewCollider.h)
	end
	
	if guiMessage then
		love.graphics.print(guiMessage, 10-cameraX, 10-cameraY)
	end
	
	if selectedCollider then
		love.graphics.setColor(0, 255, 0)
		love.graphics.rectangle("line", selectedCollider.x-3, selectedCollider.y-3, selectedCollider.w+6, selectedCollider.h+6)
	end
end


function moveCamera()
	if not manualCamera then

		love.graphics.origin()
		cameraX = -(pj.x + pj.w/2) + 400
		love.graphics.translate(cameraX, cameraY)
		
		
		local topThingy = -cameraY + 200
		local bottomThingy = -cameraY + 400
		if pj.y < topThingy then cameraY = -pj.y+200 end
		if pj.y + pj.h > bottomThingy then cameraY = -(pj.y + pj.h)+400 end

		--love.graphics.line(-1000, topThingy, 1000, topThingy)
		--love.graphics.line(-1000, bottomThingy, 1000, bottomThingy)
	else
		love.graphics.origin()
		love.graphics.translate(manualCamera.x, manualCamera.y)
		
		if pj.v.x ~= 0 then manualCamera = nil end
	end
end


function love.mousepressed(x, y, button, istouch)
	if not manualCamera then
		NewCollider = { x = x-cameraX, y = y-cameraY, w = 0, h = 0 }
	else
		NewCollider = { x = x-manualCamera.x, y = y-manualCamera.y, w = 0, h = 0 }
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	if not NewCollider then return end
	NewCollider.w = NewCollider.w + dx
	NewCollider.h = NewCollider.h + dy
end

function love.mousereleased(x, y, button, istouch)
	if NewCollider.w == 0 or NewCollider.h == 0 then NewCollider = nil return end
	if NewCollider.w < 0 then
		NewCollider.w = -NewCollider.w
		NewCollider.x = NewCollider.x - NewCollider.w
	end
	if NewCollider.h < 0 then
		NewCollider.h = -NewCollider.h
		NewCollider.y = NewCollider.y - NewCollider.h
	end
	
	NewCollider.x = math.floor(NewCollider.x)
	NewCollider.y = math.floor(NewCollider.y)

	table.insert(world.colliders, AABB(NewCollider.x, NewCollider.y, NewCollider.w, NewCollider.h))
	NewCollider = nil
end


function exportMap()
	local str = "return {\n"
	for k, v in ipairs(world.colliders) do
		str = str .. v:serialize()
	end
	str = str .. "}"

	local newFile = io.open("C:\\Users\\oneraul\\Desktop\\plat\\map.lua", "w+")
	newFile:write(str)
	newFile:close()
end