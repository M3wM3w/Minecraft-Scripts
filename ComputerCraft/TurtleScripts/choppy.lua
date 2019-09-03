--Tree Farm Turtle
--1. Place your turtle on top of a container. Farm will be 9 x 9 size, centered around the chest. Trees that grow straight work best.
--2. Place saplings into your turtle.
--3. Place fuel into your turtle.
--4. Launch the programm.

local relative_position = {x = 0, y = 0, z = 0}
local work_status = 1
local radius = 4
local sapling_y = 0
local status_translation = {
	[1] = "Planting and harvesting.",
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

local function is_wood(str)
	if string.find(str, "log") then return true end
	return false
end

local function is_leaves(str)
	if string.find(str, "leaves") then return true end
	return false
end

local function is_sapling(str)
	if string.find(str, "sapling") then return true end
	return false
end

local function is_spawn()
	if relative_position.x == 0 and relative_position.y == 0 and relative_position.z == 0 then return true end
	return false
end

local function set_slot_to_sapling()
	local data = turtle.getItemDetail(turtle.getSelectedSlot())
	if data then
		if is_sapling(data.name) then
			return true
		end
	end			
	for slot = 1, 16, 1 do
		local data = turtle.getItemDetail(slot)
		if data then
			if is_sapling(data.name) then
				turtle.select(slot)
				return true
			end
		end	
	end
	return false
end

local function turnRight()
	if turtle.turnRight() then
		current_turtle_direction = current_turtle_direction + 1
		if current_turtle_direction > 4 then current_turtle_direction = 1 end
		return true
	else
		print("Could not turn right :(")
		return false
	end
end

local function forward()
	if turtle.forward() then
		relative_position.x = relative_position.x + turtle_directions[current_turtle_direction].x
		relative_position.z = relative_position.z + turtle_directions[current_turtle_direction].z
		return true
	else
		print("Could not move forward :(")
		return false
	end
end

local function up()
	if turtle.up() then relative_position.y = relative_position.y + 1 end
end

local function down()
	if turtle.down() then relative_position.y = relative_position.y - 1 end
end

local function refuel()
	if turtle.getFuelLevel() > 128 then return true end
	for slot = 1, 16, 1 do
		turtle.select(slot)
		turtle.refuel(64)
	end
	turtle.select(1)
	if turtle.getFuelLevel() > 0 then return true end
	return false
end

local function is_inventory_full()
	for slot = 2, 16, 1 do
		if turtle.getItemCount(slot) == 0 then return false end
	end
	return true
end

local function return_to_container()	
	if relative_position.x ~= 0 then
		if math.abs(relative_position.x + turtle_directions[current_turtle_direction].x) < math.abs(relative_position.x) then
			turtle.dig()
			forward()
			return true
		else	
			turnRight()
			return true
		end
	end
	
	if relative_position.z ~= 0 then
		if math.abs(relative_position.z + turtle_directions[current_turtle_direction].z) < math.abs(relative_position.z) then
			turtle.dig()
			forward()
			return true
		else
			turnRight()
			return true
		end
	end
	
	if relative_position.y > 0 then
		turtle.digDown()
		down()
		return true
	end
	if relative_position.y < 0 then
		turtle.digUp()
		up()
		return true
	end
	
	if is_spawn() then
		work_status = 3
		return true
	end
end

local function harvest_and_plant()
	if math.abs(relative_position.x) > radius then work_status = 2 return true end
	if math.abs(relative_position.z) > radius then work_status = 2 return true end
	
	if set_slot_to_sapling() then		
		if turtle.place() then
			sapling_y = relative_position.y
		end
		if turtle.placeDown() then
			sapling_y = relative_position.y - 1
		end
	end
	
	if not is_spawn() then
		turtle.suckDown(64)
	end
	
	if turtle.detectDown() then	
		local success, data = turtle.inspectDown()
		if success then
			if is_wood(data.name) or is_leaves(data.name) then
				turtle.digDown()
				return true
			end
		end	
	end
	
	if turtle.detectUp() then
		local success, data = turtle.inspectUp()
		if success then
			if is_wood(data.name) then
				turtle.digUp()
				up()
				return true
			end
		end
	end	
	
	if relative_position.y > sapling_y + 1 then
		down()
		return true
	end
	
	if turtle.detect() then
		local success, data = turtle.inspect()
		if success then
			if is_sapling(data.name) then
				if turtle.detectUp() then
					turtle.digUp()
				end
				up()
				return true
			end			
			turtle.dig()
			forward()
			return true 
		end
	end	
	
	local r = math.random(1,100)
	if r < 35 then
		turnRight()
		return true
	end
	if r <= 100 then
		forward()
		return true
	end
	
	return true
end

local function dump_inventory()
	print("Dumping inventory.")
	local dump_saplings = false
	local dump_logs = false
	
	for slot = 1, 16, 1 do
		local dump_slot = true		
		local data = turtle.getItemDetail(slot)
		if data then
			if not dump_saplings then
				if is_sapling(data.name) then
					dump_saplings = true
					dump_slot = false
				end
			end
			if not dump_logs then
				if is_wood(data.name) then
					dump_logs = true
					dump_slot = false
				end
			end
		end		
		if dump_slot then
			turtle.select(slot)
			turtle.dropDown()
		end
	end
	
	if not is_inventory_full() then
		print("Proceeding to harvest.")
		work_status = 1
	end
	
	return true
end

local function heartbeat()
	if not refuel() then print("I ran out of fuel :(") return false end
	if is_inventory_full() and current_status == 1 then
		print("Inventory full, returning to storage chest.")
		current_status = 2 
		return true 
	end
	if work_status == 1 then 
		if harvest_and_plant() then return true end
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