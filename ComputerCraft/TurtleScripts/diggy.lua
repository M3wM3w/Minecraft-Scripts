--Mining Turtle
--1. Place your turtle on top of a container.
--2. Place fuel into your turtle.
--3. Launch the programm.

local relative_position = {x = 0, y = 0, z = 0}
local work_status = 1
local radius = 48
local status_translation = {
	[1] = "Mining.",
	[2] = "Returning to storage container.",
	[3] = "Storing items into container.",
}

local current_turtle_direction = 1
local turtle_directions = {
	[1] = {x = -1, z = 0},
	[2] = {x = 0, z = -1},
	[3] = {x = 1, z = 0},
	[4] = {x = 0, z = 1},
}

local valid_blocks = {
	["actuallyadditions:block_misc"] = true, --black quartz
	["basalt"] = true,
	["basalt2"] = true,
	["clay"] = true,
	["dirt"] = true,
	["gravel"] = true,
	["marble"] = true,
	["marble2"] = true,
	["minecraft:cobblestone"] = true,
	["minecraft:obsidian"] = true,
	["minecraft:stone"] = true,
	["ore"] = true,
	["ore_cinnabar"] = true,
	["ore_amber"] = true,
	["oreblock"] = true,
	["stone"] = true,
}

local function is_valid_for_mining(str)
	if not str then return false end
	if valid_blocks[str] then return true end
	--if string.find(str, "ore") then return true end
	if string.sub(str, string.len(str) - 2, string.len(str)) == "ore" then return true end
	local a, b = string.find(str, ":")
	if not a then return false end
	local str = string.sub(str, a + 1, string.len(str))
	if valid_blocks[str] then return true end
	print("I can not mine this! " .. str .. " is not whitelisted!")
	return false
end

local function is_spawn()
	if relative_position.x == 0 and relative_position.y == 0 and relative_position.z == 0 then return true end
	return false
end

local function turnRight()
	if turtle.turnRight() then
		current_turtle_direction = current_turtle_direction + 1
		if current_turtle_direction > 4 then current_turtle_direction = 1 end
		return true
	else
		return false
	end
end

local function forward()
	if turtle.forward() then
		relative_position.x = relative_position.x + turtle_directions[current_turtle_direction].x
		relative_position.z = relative_position.z + turtle_directions[current_turtle_direction].z
		return true
	else
		return false
	end
end

local function up()
	if turtle.up() then
		relative_position.y = relative_position.y + 1
		return true
	end
	return false
end

local function down()
	if turtle.down() then
		relative_position.y = relative_position.y - 1
		return true
	end
	return false
end

local moves = {forward, up, turnRight, down}

local function refuel()
	if turtle.getFuelLevel() > 128 then return true end
	for slot = 1, 16, 1 do
		turtle.select(slot)
		turtle.refuel(64)
	end
	if turtle.getFuelLevel() > 0 then return true end
	return false
end

local function is_inventory_full()
	for slot = 1, 16, 1 do
		if turtle.getItemCount(slot) == 0 then return false end
	end
	return true
end

local function mining_diamonds()
	if math.abs(relative_position.x) > radius then work_status = 2 return true end
	if math.abs(relative_position.z) > radius then work_status = 2 return true end
	if math.abs(relative_position.y) > radius then work_status = 2 return true end
	
	if not is_spawn() then
		turtle.suckDown(64)
	end
	
	local digged_down = false
	if turtle.detectDown() then	
		local success, data = turtle.inspectDown()
		if success then
			if is_valid_for_mining(data.name) then
				turtle.digDown()
				digged_down = true
			end
		end	
	end
	
	local digged_up = false
	if turtle.detectUp() then
		local success, data = turtle.inspectUp()
		if success then
			if is_valid_for_mining(data.name) then
				turtle.digUp()
				digged_up = true
			end
		end
	end	
	
	local digged_forward = false
	if turtle.detect() then
		local success, data = turtle.inspect()
		if success then
			if is_valid_for_mining(data.name) then
				turtle.dig()
				digged_forward = true
			end			
		end
	end	
	
	if digged_forward then forward() return true end
	if digged_up then up() return true end
	if digged_down and relative_position.y > 0 then
		down() return true 
	end
	
	local r = math.random(1,100)
	if r < 25 then
		turnRight()
		return true
	end
	if r < 60 then
		forward()
		return true
	end
	if r < 85 then
		up()
		return true
	end
	if r <= 100 then
		if relative_position.y > 0 then 
			down()
		end
		return true
	end
end

local function evade()
	print("Evading obstacle.")
	for a = 1, 10, 1 do
		mining_diamonds()
	end
end

local function return_to_container()
	if math.random(1,2) == 1 then
		if relative_position.x ~= 0 then
			if math.abs(relative_position.x + turtle_directions[current_turtle_direction].x) < math.abs(relative_position.x) then
				if turtle.detect() then	
					local success, data = turtle.inspect()
					if success then
						if is_valid_for_mining(data.name) then
							turtle.dig()
						end
					end	
				end	
				if not forward() then evade() end
			else	
				turnRight()
			end
		end
	else
		if relative_position.z ~= 0 then
			if math.abs(relative_position.z + turtle_directions[current_turtle_direction].z) < math.abs(relative_position.z) then
				if turtle.detect() then	
					local success, data = turtle.inspect()
					if success then
						if is_valid_for_mining(data.name) then
							turtle.dig()
						end
					end	
				end
				if not forward() then evade() end
			else
				turnRight()
			end
		end
	end
	
	if relative_position.y > 0 then	
		if turtle.detectDown() then	
			local success, data = turtle.inspectDown()
			if success then
				if is_valid_for_mining(data.name) then
					turtle.digDown()
				end
			end	
		end
		if not down() then evade() end
	end
	if relative_position.y < 0 then
		if turtle.detectUp() then	
			local success, data = turtle.inspectUp()
			if success then
				if is_valid_for_mining(data.name) then
					turtle.digUp()
				end
			end	
		end
		if not up() then evade() end
	end
	
	if is_spawn() then
		work_status = 3
	end
	
	return true
end

local function dump_inventory()
	print("Dumping inventory.")
	local dump_coal = false
	
	for slot = 1, 16, 1 do
		local dump_slot = true	
		--local trash_slot = false
		local data = turtle.getItemDetail(slot)
		if data then
			if not dump_coal then
				if data.name == "minecraft:coal" then
					dump_coal = true
					dump_slot = false
				end
			end
			--if data.name == "minecraft:cobblestone" then
			--	trash_slot = true
			--end
		end		
		if dump_slot then
			turtle.select(slot)
			--if trash_slot then
			--	turtle.drop()
			--	turtle.dropUp()
			--else	
				turtle.dropDown()
			--end	
		end
	end
	
	if not is_inventory_full() then
		work_status = 1
		print(status_translation[work_status])
	end
	
	return true
end

local function heartbeat()
	if not refuel() then print("I ran out of fuel :(") return false end
	if is_inventory_full() and work_status == 1 then
		work_status = 2 
		print(status_translation[work_status])
		return true 
	end
	if work_status == 1 then 
		if mining_diamonds() then return true end
	end
	if work_status == 2 then
		if return_to_container() then return true end
	end
	if work_status == 3 then
		if dump_inventory() then return true end
	end
	return false
end

while true do
	if not heartbeat() then break end
end