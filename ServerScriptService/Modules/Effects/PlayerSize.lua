-- /ServerScriptService/Modules/Effects/PlayerSize.lua
-- ModuleScript that provides functions to control player character size using the GrowthScript approach

local PlayerSize = {}

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Size configuration table for different character scales
-- This can be extended in the future with more size options
PlayerSize.SizeOptions = {
	small = {
		Width = 0.25,  -- How wide the shoulders are
		Height = 0.25, -- How tall the player is
		Depth = 0.25,  -- How thick the player is
		Head = nil     -- Head size, auto calculated if nil (R15 only)
	},
	normal = {
		Width = 1.0,
		Height = 1.0,
		Depth = 1.0,
		Head = nil
	}
	-- Additional sizes can be added here in the future
}

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

-- Apply R6 scaling to a character
local function applyR6Scaling(character, sizeVector, isRestore)
	-- Handle joint scaling
	local motors = {}
	table.insert(motors, character.HumanoidRootPart.RootJoint)

	for _, motor in pairs(character.Torso:GetChildren()) do
		if motor:IsA("Motor6D") then
			table.insert(motors, motor)
		end
	end

	for _, motor in pairs(motors) do
		if isRestore then
			-- Restore original C0 and C1 if they were saved
			local originalC0 = motor:GetAttribute("OriginalC0")
			local originalC1 = motor:GetAttribute("OriginalC1")

			if originalC0 and originalC1 then
				motor.C0 = originalC0
				motor.C1 = originalC1
			end
		else
			-- Save original values
			motor:SetAttribute("OriginalC0", motor.C0)
			motor:SetAttribute("OriginalC1", motor.C1)

			-- Apply scaling
			motor.C0 = CFrame.new((motor.C0.Position * sizeVector)) * (motor.C0 - motor.C0.Position)
			motor.C1 = CFrame.new((motor.C1.Position * sizeVector)) * (motor.C1 - motor.C1.Position)
		end
	end

	-- Handle part sizes
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			if isRestore then
				-- Restore original size if it was saved
				local originalSize = part:GetAttribute("OriginalSize")
				if originalSize then
					part.Size = originalSize
				end
			else
				-- Save original size
				part:SetAttribute("OriginalSize", part.Size)

				-- Apply scaling
				part.Size = part.Size * sizeVector
			end
		end
	end

	-- Handle head mesh
	if character.Head:FindFirstChild("Mesh") and character.Head.Mesh.MeshId ~= "" then
		if isRestore then
			-- Restore original mesh scale if it was saved
			local originalMeshScale = character.Head.Mesh:GetAttribute("OriginalScale")
			if originalMeshScale then
				character.Head.Mesh.Scale = originalMeshScale
			end
		else
			-- Save original mesh scale
			character.Head.Mesh:SetAttribute("OriginalScale", character.Head.Mesh.Scale)

			-- Apply scaling
			character.Head.Mesh.Scale = character.Head.Mesh.Scale * sizeVector
		end
	end

	-- Handle accessories
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local weld = accessory.Handle:FindFirstChild("AccessoryWeld")
			local mesh = accessory.Handle:FindFirstChildOfClass("SpecialMesh")

			if weld then
				if isRestore then
					-- Restore original weld C0 and C1 if they were saved
					local originalC0 = weld:GetAttribute("OriginalC0")
					local originalC1 = weld:GetAttribute("OriginalC1")

					if originalC0 and originalC1 then
						weld.C0 = originalC0
						weld.C1 = originalC1
					end
				else
					-- Save original values
					weld:SetAttribute("OriginalC0", weld.C0)
					weld:SetAttribute("OriginalC1", weld.C1)

					-- Apply scaling
					weld.C0 = CFrame.new((weld.C0.Position * sizeVector)) * (weld.C0 - weld.C0.Position)
					weld.C1 = CFrame.new((weld.C1.Position * sizeVector)) * (weld.C1 - weld.C1.Position)
				end
			end

			if mesh then
				if isRestore then
					-- Restore original mesh scale if it was saved
					local originalMeshScale = mesh:GetAttribute("OriginalScale")
					if originalMeshScale then
						mesh.Scale = originalMeshScale
					end
				else
					-- Save original mesh scale
					mesh:SetAttribute("OriginalScale", mesh.Scale)

					-- Apply scaling
					mesh.Scale = mesh.Scale * sizeVector
				end
			end
		end
	end
end

-- Apply R15 scaling to a character
local function applyR15Scaling(humanoid, sizeOptions, isRestore)
	local description = humanoid:GetAppliedDescription()

	if isRestore then
		-- Restore original scales if they were saved
		local originalDepthScale = humanoid:GetAttribute("OriginalDepthScale")
		local originalHeadScale = humanoid:GetAttribute("OriginalHeadScale")
		local originalHeightScale = humanoid:GetAttribute("OriginalHeightScale")
		local originalWidthScale = humanoid:GetAttribute("OriginalWidthScale")

		if originalDepthScale and originalHeadScale and originalHeightScale and originalWidthScale then
			description.DepthScale = originalDepthScale
			description.HeadScale = originalHeadScale
			description.HeightScale = originalHeightScale
			description.WidthScale = originalWidthScale
		end
	else
		-- Save original scales
		humanoid:SetAttribute("OriginalDepthScale", description.DepthScale)
		humanoid:SetAttribute("OriginalHeadScale", description.HeadScale)
		humanoid:SetAttribute("OriginalHeightScale", description.HeightScale)
		humanoid:SetAttribute("OriginalWidthScale", description.WidthScale)

		-- Apply scaling
		description.DepthScale = description.DepthScale * sizeOptions.Depth
		description.HeadScale = description.HeadScale * (sizeOptions.Head or math.max(sizeOptions.Width, sizeOptions.Depth))
		description.HeightScale = description.HeightScale * sizeOptions.Height
		description.WidthScale = description.WidthScale * sizeOptions.Width
	end

	-- Apply the description
	humanoid:ApplyDescription(description)
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
	local targetSize = "normal"

	if size == "toggle" then
		shouldShrink = not isCurrentlySmall
		targetSize = shouldShrink and "small" or "normal"
	elseif size == "small" then
		shouldShrink = true
		targetSize = "small"
	elseif size == "normal" then
		shouldShrink = false
		targetSize = "normal"
	else
		warn("Invalid size parameter: '" .. size .. "'. Must be 'small', 'normal', or 'toggle'")
		return false
	end

	-- Already in desired state? Return early
	if shouldShrink == isCurrentlySmall then
		return true -- Already in the desired state
	end

	-- Get size options from the table
	local sizeOptions = PlayerSize.SizeOptions[targetSize]
	if not sizeOptions then
		warn("Size options not found for: " .. targetSize)
		return false
	end

	-- Create size vector
	local sizeVector = Vector3.new(sizeOptions.Width, sizeOptions.Height, sizeOptions.Depth)

	if shouldShrink then
		-- Create marker in ShrunkPlayers folder
		local marker = Instance.new("BoolValue")
		marker.Name = tostring(player.UserId)
		-- Store original speed as an attribute
		marker:SetAttribute("OriginalSpeed", humanoid.WalkSpeed)
		marker.Parent = shrunkPlayers

		-- Apply size change based on rig type
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			applyR6Scaling(character, sizeVector, false)
		elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
			applyR15Scaling(humanoid, sizeOptions, false)
		end

		return true
	else
		-- Remove marker from ShrunkPlayers folder
		if shrunkData then
			local originalSpeed = shrunkData:GetAttribute("OriginalSpeed") or 16
			shrunkData:Destroy()

			-- Restore character size based on rig type
			if humanoid.RigType == Enum.HumanoidRigType.R6 then
				applyR6Scaling(character, sizeVector, true)
			elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
				applyR15Scaling(humanoid, sizeOptions, true)
			end

			-- Restore walk speed (we'll keep this from the original implementation)
			humanoid.WalkSpeed = originalSpeed

			return true
		else
			warn("Cannot restore size: No shrunk data found for player", player.Name)
			return false
		end
	end
end

-- For backward compatibility - still allows using the toggle parameter
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
	remoteEvent.OnServerEvent:Connect(function(player, action)
		if action == "toggle" or action == nil then
			PlayerSize.SetPlayerSize(player, "toggle")
		elseif action == "small" then
			PlayerSize.SetPlayerSize(player, "small")
		elseif action == "normal" then
			PlayerSize.SetPlayerSize(player, "normal")
		end
	end)

	return remoteEvent
end

-- Initialize storage and RemoteEvent
do
	ensureShrunkPlayersStorage()
	initializeRemoteEvent()
	print("PlayerSize module initialized with enhanced scaling features")
end

return PlayerSize
