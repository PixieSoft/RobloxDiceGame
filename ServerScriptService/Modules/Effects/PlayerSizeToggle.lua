-- ServerScriptService/Modules/Effects/PlayerSizeToggle.lua
local PlayerSizeToggle = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants 
local SHRINK_SCALE = 0.25
local SHRINK_SPEED = 0.50
local SHRINK_JUMP = 0.33

-- Create RemoteEvent immediately when module is required
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "TogglePlayerSize"
remoteEvent.Parent = ReplicatedStorage

-- Helper function
local function EnsureScaleExists(humanoid, scaleName)
	local scale = humanoid:FindFirstChild(scaleName)
	if not scale then
		scale = Instance.new(scaleName)
		scale.Name = scaleName
		scale.Value = 1
		scale.Parent = humanoid
	end
	return scale
end

function PlayerSizeToggle.TogglePlayerSize(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local shrunkPlayers = ServerStorage:WaitForChild("ShrunkPlayers")
	local shrunkData = shrunkPlayers:FindFirstChild(tostring(player.UserId))

	if shrunkData then
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
	else
		-- Shrink
		local marker = Instance.new("BoolValue")
		marker.Name = tostring(player.UserId)
		-- Store original speed as an attribute
		marker:SetAttribute("OriginalSpeed", humanoid.WalkSpeed)
		marker.Parent = shrunkPlayers

		local scales = {
			EnsureScaleExists(humanoid, "HeadScale"),
			EnsureScaleExists(humanoid, "BodyHeightScale"),
			EnsureScaleExists(humanoid, "BodyWidthScale"),
			EnsureScaleExists(humanoid, "BodyDepthScale")
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
	end
end

-- Initialize storage and RemoteEvent
do
	-- Initialize storage
	if not ServerStorage:FindFirstChild("ShrunkPlayers") then
		local shrunkPlayers = Instance.new("Folder")
		shrunkPlayers.Name = "ShrunkPlayers"
		shrunkPlayers.Parent = ServerStorage
	end

	-- Listen for toggle requests
	remoteEvent.OnServerEvent:Connect(function(player)
		PlayerSizeToggle.TogglePlayerSize(player)
	end)
end

return PlayerSizeToggle
