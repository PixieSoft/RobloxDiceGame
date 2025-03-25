local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent
local spawnCartEvent = Instance.new("RemoteEvent")
spawnCartEvent.Name = "SpawnCartEvent"
spawnCartEvent.Parent = ReplicatedStorage

-- Function to get position from a rail
local function getRailPosition(rail)
	if rail:IsA("Model") then
		if rail.PrimaryPart then
			return rail.PrimaryPart.Position
		else
			for _, part in ipairs(rail:GetDescendants()) do
				if part:IsA("BasePart") then
					return part.Position
				end
			end
		end
	elseif rail:IsA("BasePart") then
		return rail.Position
	end
	return nil
end

-- Function to find all wheels and their nearest rails
local function findWheelsAndRails(cart)
	local wheels = {}
	-- Find all wheels in the cart
	for _, part in ipairs(cart:GetDescendants()) do
		if part.Name == "Wheel" then
			table.insert(wheels, part)
		end
	end

	-- Find all rails in the workspace
	local rails = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Rail" then
			table.insert(rails, obj)
		end
	end

	-- Sort wheels by X position (assuming cart is roughly aligned with X axis)
	table.sort(wheels, function(a, b)
		return a.Position.X < b.Position.X
	end)

	-- Group wheels into left and right sides
	local leftWheels = {}
	local rightWheels = {}
	local midpoint = #wheels / 2

	for i, wheel in ipairs(wheels) do
		if i <= midpoint then
			table.insert(leftWheels, wheel)
		else
			table.insert(rightWheels, wheel)
		end
	end

	-- Find nearest rail for each wheel
	local function findNearestRail(wheel)
		local nearestRail = nil
		local shortestDistance = math.huge

		for _, rail in ipairs(rails) do
			local railPos = getRailPosition(rail)
			if railPos then
				local distance = (railPos - wheel.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					nearestRail = rail
				end
			end
		end

		return nearestRail
	end

	-- Get rail positions for all wheels
	local wheelRailPairs = {}
	for _, wheel in ipairs(wheels) do
		local nearestRail = findNearestRail(wheel)
		if nearestRail then
			table.insert(wheelRailPairs, {
				wheel = wheel,
				rail = nearestRail,
				railPos = getRailPosition(nearestRail)
			})
		end
	end

	return wheelRailPairs
end

-- Function to anchor/unanchor all parts in the cart
local function setCartAnchored(cart, anchored)
	for _, part in ipairs(cart:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
		end
	end
end

-- Function to check and correct cart orientation
local function orientCartAwayFromPlayer(cart, playerPos, railDirection)
	local onPart = cart:FindFirstChild("On", true)
	if not onPart then return end

	local cartCFrame = cart:GetPivot()
	local cartPos = cartCFrame.Position

	-- Create two possible orientations aligned with the rail
	local orientation1 = CFrame.new(cartPos) * CFrame.fromMatrix(Vector3.new(), railDirection, Vector3.new(0, 1, 0))
	local orientation2 = CFrame.new(cartPos) * CFrame.fromMatrix(Vector3.new(), -railDirection, Vector3.new(0, 1, 0))

	local function getOnPartDistance(orientation)
		cart:PivotTo(orientation)
		return (onPart.Position - playerPos).Magnitude
	end

	local dist1 = getOnPartDistance(orientation1)
	local dist2 = getOnPartDistance(orientation2)

	if dist1 > dist2 then
		cart:PivotTo(orientation1)
	else
		cart:PivotTo(orientation2)
	end
end

-- Handle spawn requests
spawnCartEvent.OnServerEvent:Connect(function(player, characterCFrame)
	-- Clean up existing carts
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Cart" then
			obj:Destroy()
		end
	end

	-- Get cart template
	local cartTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Cart"):WaitForChild("CartTemplate")

	-- Clone the cart
	local newCart = cartTemplate:Clone()
	newCart.Name = "Cart"

	-- Calculate initial spawn position
	local spawnOffset = characterCFrame.LookVector * math.max(5, 4)
	local spawnPos = characterCFrame.Position + spawnOffset
	local playerPos = characterCFrame.Position

	-- Initial spawn
	local spawnCFrame = CFrame.new(spawnPos) * characterCFrame.Rotation * CFrame.new(0, 2, 0)
	newCart:PivotTo(spawnCFrame)

	-- Create required values
	if not newCart:FindFirstChild("CarOn") then
		local carOn = Instance.new("BoolValue")
		carOn.Name = "CarOn"
		carOn.Value = false
		carOn.Parent = newCart
	end

	-- Create or set Speed value to 30
	local speed = newCart:FindFirstChild("Speed")
	if speed then
		speed.Value = 30
	else
		speed = Instance.new("NumberValue")
		speed.Name = "Speed"
		speed.Value = 30
		speed.Parent = newCart
	end

	newCart.Parent = workspace
	setCartAnchored(newCart, true)

	-- Add delay for physics
	task.wait(0.1)

	-- Find all wheels and their corresponding rails
	local wheelRailPairs = findWheelsAndRails(newCart)

	if #wheelRailPairs >= 6 then
		-- Calculate average rail position and direction
		local avgPos = Vector3.new(0, 0, 0)
		local railDirection = nil

		-- Get first and last rail positions to determine direction
		local firstRailPos = wheelRailPairs[1].railPos
		local lastRailPos = wheelRailPairs[#wheelRailPairs].railPos
		railDirection = (lastRailPos - firstRailPos).Unit

		-- Calculate average position for cart placement
		for _, pair in ipairs(wheelRailPairs) do
			avgPos = avgPos + pair.railPos
		end
		avgPos = avgPos / #wheelRailPairs

		-- Position cart at average position
		local middlePosition = CFrame.new(
			avgPos.X,
			newCart:GetPivot().Y,
			avgPos.Z
		)

		-- Position and orient cart
		newCart:PivotTo(middlePosition)
		orientCartAwayFromPlayer(newCart, playerPos, railDirection)

		-- Fine-tune height to align wheels with rails
		local avgRailHeight = 0
		for _, pair in ipairs(wheelRailPairs) do
			avgRailHeight = avgRailHeight + pair.railPos.Y
		end
		avgRailHeight = avgRailHeight / #wheelRailPairs

		local currentPos = newCart:GetPivot().Position
		newCart:PivotTo(CFrame.new(currentPos.X, avgRailHeight + 2, currentPos.Z) * newCart:GetPivot().Rotation)
	else
		warn("Could not find all 6 wheels or their corresponding rails")
	end

	-- Unanchor to let physics take over
	setCartAnchored(newCart, false)
end)
