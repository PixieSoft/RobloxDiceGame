-- /ServerScriptService/Modules/Effects/PlayerSize.lua
-- ModuleScript that provides functions to control player character size

local PlayerSize = {}

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Constants 
local SHRINK_SCALE = 0.25
local SHRINK_SPEED = 0.50
local SHRINK_JUMP = 0.33

-- Create shrunk players storage if it doesn't exist
local function ensureShrunkPlayersStorage()
	if not ServerStorage:FindFirstChild("ShrunkPlayers") then
		local shrunkPlayers = Instance.new("Folder")
		shrunkPlayers.Name = "ShrunkPlayers"
		shrunkPlayers.Parent = ServerStorage
	end
	return ServerStorage:WaitForChild("ShrunkPlayers")
end

-- Helper function to ensure scale values exist on humanoid
local function ensureScaleExists(humanoid, scaleName)
	local scale = humanoid:FindFirstChild(scaleName)
	if not scale then
		scale = Instance.new(scaleName)
		scale.Name = scaleName
		scale.Value = 1
		scale.Parent = humanoid
	end
	return scale
end

-- Main function to set player size
-- size can be "small", "normal", or "toggle"
function PlayerSize.SetPlayerSize(player, size)
	if type(size) ~= "string" then
		warn("Invalid size parameter for SetPlayerSize. Must be 'small', 'normal', or 'toggle'")
		return false
	end
	size = string.lower(size)

	local character = player.Character
	if not character then 
		warn("Cannot set size: No character found for player", player.Name)
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		warn("Cannot set size: No humanoid found for player", player.Name)
		return false
	end

	local shrunkPlayers = ensureShrunkPlayersStorage()
	local shrunkData = shrunkPlayers:FindFirstChild(tostring(player.UserId))
	local isCurrentlySmall = (shrunkData ~= nil)

	-- Determine action based on requested size
	local shouldShrink = false

	if size == "toggle" then
		shouldShrink = not isCurrentlySmall
	elseif size == "small" then
		shouldShrink = true
	elseif size == "normal" then
		shouldShrink = false
	else
		warn("Invalid size parameter: '" .. size .. "'. Must be 'small', 'normal', or 'toggle'")
		return false
	end

	-- Already in desired state? Return early
	if shouldShrink == isCurrentlySmall then
		return true -- Already in the desired state
	end

	if shouldShrink then
		-- Shrink the player
		local marker = Instance.new("BoolValue")
		marker.Name = tostring(player.UserId)
		-- Store original speed as an attribute
		marker:SetAttribute("OriginalSpeed", humanoid.WalkSpeed)
		marker.Parent = shrunkPlayers

		local scales = {
			ensureScaleExists(humanoid, "HeadScale"),
			ensureScaleExists(humanoid, "BodyHeightScale"),
			ensureScaleExists(humanoid, "BodyWidthScale"),
			ensureScaleExists(humanoid, "BodyDepthScale")
		}

		for _, scale in ipairs(scales) do
			scale.Value = scale.Value * SHRINK_SCALE
		end

		humanoid.WalkSpeed = humanoid.WalkSpeed * SHRINK_SPEED
		humanoid.JumpPower = humanoid.JumpPower * SHRINK_JUMP

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = PhysicalProperties.new(13, 0.3, 0.5)
			end
		end

		return true
	else
		-- Grow back to normal
		local originalSpeed = shrunkData:GetAttribute("OriginalSpeed") or 16
		shrunkData:Destroy()

		local scales = {
			humanoid:WaitForChild("HeadScale"),
			humanoid:WaitForChild("BodyHeightScale"),
			humanoid:WaitForChild("BodyWidthScale"),
			humanoid:WaitForChild("BodyDepthScale")
		}

		for _, scale in ipairs(scales) do
			scale.Value = 1
		end

		humanoid.WalkSpeed = originalSpeed
		humanoid.JumpPower = 50

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = nil
			end
		end

		return true
	end
end

-- For backward compatibility
function PlayerSize.TogglePlayerSize(player)
	return PlayerSize.SetPlayerSize(player, "toggle")
end

-- Check if a player is currently small
function PlayerSize.IsPlayerSmall(player)
	local shrunkPlayers = ServerStorage:FindFirstChild("ShrunkPlayers")
	if not shrunkPlayers then return false end

	return shrunkPlayers:FindFirstChild(tostring(player.UserId)) ~= nil
end

-- Initialize remote event for client-server communication
local function initializeRemoteEvent()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Create RemoteEvent if it doesn't exist
	local remoteEvent = ReplicatedStorage:FindFirstChild("TogglePlayerSize")
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = "TogglePlayerSize"
		remoteEvent.Parent = ReplicatedStorage
	end

	-- Listen for toggle requests
	remoteEvent.OnServerEvent:Connect(function(player)
		PlayerSize.TogglePlayerSize(player)
	end)

	return remoteEvent
end

-- Initialize storage and RemoteEvent
do
	ensureShrunkPlayersStorage()
	initializeRemoteEvent()
	print("PlayerSize module initialized")
end

return PlayerSize
