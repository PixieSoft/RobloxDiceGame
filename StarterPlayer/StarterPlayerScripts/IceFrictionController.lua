-- /StarterPlayer/StarterPlayerScripts/IceFrictionController.lua
-- LocalScript that applies custom ice friction based on player scale and walk speed

-- Reference to player and services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the ScaleCharacter module for character scaling
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)

-- Define default physical properties
local DefaultPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)

-- Keep track of the last part we modified
local lastModifiedPart = nil

-- Ice friction data table from CSV file
-- Format: {Scale threshold, Speed threshold, Friction value}
-- The script will use the first row where player scale >= row's scale AND player speed >= row's speed
local ICE_FRICTION_TABLE = {
	{0.25,   16, 0.020},
	{0.25,   32, 0.025},
	{0.25,   64, 0.065},
	{0.25,  128, 0.075},
	{0.50,   16, 0.003},
	{0.50,   32, 0.004},
	{0.50,   64, 0.007},
	{0.50,  128, 0.020},
	{0.75,   16, 0.001},
	{0.75,   32, 0.002},
	{0.75,   64, 0.012},
	{0.75,  128, 0.028},
	{1.00,   16, 0.000},
	{1.00,   32, 0.010},
	{1.00,   64, 0.020},
	{1.00,  128, 0.030},
	{2.00,   16, 0.000}, -- Test and add values here on
	{2.00,   32, 0.000},
	{2.00,   64, 0.000},
	{2.00,  128, 0.000},
	{3.00,   16, 0.000},
	{3.00,   32, 0.000},
	{3.00,   64, 0.000},
	{3.00,  128, 0.000},
	{4.00,   16, 0.000},
	{4.00,   32, 0.000},
	{4.00,   64, 0.000},
	{4.00,  128, 0.000},
}

-- Function to get the appropriate friction for the player's scale and speed
local function getFrictionForScaleAndSpeed(scale, speed)
	-- Default friction if no matching condition is found
	local friction = 0.010
	local frictionWeight = 100

	-- Loop through the table from bottom to top (to find the largest scale and speed that match)
	for i = #ICE_FRICTION_TABLE, 1, -1 do
		local entry = ICE_FRICTION_TABLE[i]
		local scaleThreshold = entry[1]
		local speedThreshold = entry[2]
		local frictionValue = entry[3]

		-- If player meets both thresholds and a friction value is specified
		if scale >= scaleThreshold and speed >= speedThreshold and frictionValue ~= nil then
			friction = frictionValue
			-- For diagnostic purposes
			print("Using friction", friction, "for scale", scale, "and speed", speed)
			return PhysicalProperties.new(0.7, friction, 0.5, frictionWeight, 1)
		end
	end

	-- Create and return the physical properties with the default friction
	return PhysicalProperties.new(0.7, friction, 0.5, frictionWeight, 1)
end

-- Function to check the part below player and apply properties
local function checkPartBelowPlayer()
	local player = Players.LocalPlayer
	local character = player.Character

	-- Ensure character and humanoid root part exist
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Get the current character scale using ScaleCharacter module
	local characterScale = ScaleCharacter.GetScale(player)
	local walkSpeed = humanoid.WalkSpeed

	local rootPart = character.HumanoidRootPart
	local startPosition = rootPart.Position
	local endPosition = startPosition + Vector3.new(0, -5, 0)

	-- Create raycast parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character} -- Ignore the character
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Perform the raycast
	local raycastResult = Workspace:Raycast(startPosition, endPosition - startPosition, raycastParams)

	-- If we modified a part before, restore its default properties
	if lastModifiedPart and lastModifiedPart.Parent then
		lastModifiedPart.CustomPhysicalProperties = DefaultPhysicalProperties
		lastModifiedPart = nil
	end

	-- Check if raycast hit something
	if raycastResult then
		local hitPart = raycastResult.Instance
		local hitMaterial = raycastResult.Material

		-- Apply custom friction properties if the part's material is ice
		if hitMaterial == Enum.Material.Ice then
			-- Get the appropriate properties based on character scale and speed
			local iceProperties = getFrictionForScaleAndSpeed(characterScale, walkSpeed)

			-- Apply the properties to the hit part
			hitPart.CustomPhysicalProperties = iceProperties
			lastModifiedPart = hitPart

			print("Applied custom ice properties to", hitPart.Name, 
				"for character (Scale:", characterScale, ", Speed:", walkSpeed, ")",
				"- Friction:", iceProperties.Friction)
		end
	end
end

-- Use RunService instead of a while loop with wait
RunService.Heartbeat:Connect(function()
	-- Using a timer to check at a reasonable interval
	if not _G.lastCheckTime or (tick() - _G.lastCheckTime) >= 0.5 then
		_G.lastCheckTime = tick()
		checkPartBelowPlayer()
	end
end)

print("Ice friction controller initialized with ScaleCharacter module")
-- /StarterPlayer/StarterPlayerScripts/IceFrictionController.lua
