-- LavaBallPlatformManager.lua
-- Handles spawning, timing, and cleanup of player LavaBall platforms


local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local ActivePlatforms = {} -- [player] = {platforms}

local DEBUG = true  -- Set to false to disable all debug prints easily


local function debugPrint(...)
	if DEBUG then
		print("[LavaBall DEBUG]", ...)
	end
end


-- Helper to determine size based on count
local function determineSize(count)
	if count >= 1001 then
		return Vector3.new(16, 16, 16)
	elseif count >= 101 then
		return Vector3.new(12, 12, 12)
	elseif count >= 10 then
		return Vector3.new(8, 8, 8)
	else
		return Vector3.new(4, 4, 4)
	end
end

-- Helper to safely remove a platform from ActivePlatforms
local function removePlatform(player, platform)
	if ActivePlatforms[player] then
		for i, p in ipairs(ActivePlatforms[player]) do
			if p == platform then
				table.remove(ActivePlatforms[player], i)
				break
			end
		end
	end
end

local function addDestroyPromptToPlatform(platformPart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Destroy"
	prompt.ObjectText = "Lava Platform"
	prompt.KeyboardKeyCode = Enum.KeyCode.V
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 16
	prompt.Parent = platformPart

	prompt.Triggered:Connect(function(player)
		if DEBUG then
			print("[LavaBall DEBUG] Platform destroyed by player:", player.Name)
		end
		if platformPart and platformPart.Parent then
			platformPart:Destroy()
		end
	end)
end


-- Main spawn function
local function spawnLavaPlatform(player, lavaBallCount)
	if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		warn("[LavaBall] Invalid player or missing HumanoidRootPart")
		return
	end

	debugPrint("Player attempting to use LavaBalls:", player.Name, "with count:", lavaBallCount)

	local root = player.Character.HumanoidRootPart
	local platform = Instance.new("Part")
	platform.Anchored = true
	platform.Material = Enum.Material.Rock
	platform.BrickColor = BrickColor.new("Smoky grey")
	platform.Shape = Enum.PartType.Block
	platform.Name = "LavaBallPlatform"
	platform.Size = determineSize(lavaBallCount)
	platform.Position = root.Position - Vector3.new(0, 2, 0) -- 2 studs below player

	debugPrint("Platform placed at:", platform.Position)
	-- Collision setup
	platform.CollisionGroup = "Cuboid"

	-- Track ownership
	local ownerTag = Instance.new("ObjectValue")
	ownerTag.Name = "Owner"
	ownerTag.Value = player
	ownerTag.Parent = platform

	-- Parent into Workspace
	platform.Parent = workspace

	-- Add prompt
	addDestroyPromptToPlatform(platform)

	-- Track platform under player
	ActivePlatforms[player] = ActivePlatforms[player] or {}
	table.insert(ActivePlatforms[player], platform)
	
	-- Setup destruction timer
	local lifespan = lavaBallCount * 5 -- seconds
	task.delay(lifespan, function()
		if platform and platform.Parent then
			platform:Destroy()
		end
		removePlatform(player, platform)
	end)
end

-- Clean up platforms if player leaves
Players.PlayerRemoving:Connect(function(player)
	if ActivePlatforms[player] then
		for _, platform in ipairs(ActivePlatforms[player]) do
			if platform and platform.Parent then
				platform:Destroy()
			end
		end
		ActivePlatforms[player] = nil
	end
end)

return spawnLavaPlatform

-- call it like this i thnk LavaBallPlatformManager(player, lavaBallsToUse)
