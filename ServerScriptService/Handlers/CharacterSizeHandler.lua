-- /ServerScriptService/Handlers/CharacterSizeHandler.lua
-- Script that handles character scaling requests from clients using the Model:ScaleTo API

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get or create the remote event
local scaleEvent = ReplicatedStorage:FindFirstChild("ScaleCharacterEvent")
if not scaleEvent then
	scaleEvent = Instance.new("RemoteEvent")
	scaleEvent.Name = "ScaleCharacterEvent"
	scaleEvent.Parent = ReplicatedStorage
end

-- Function to handle character scaling
local function ScaleCharacter(player, scale)
	-- Get player character
	local character = player.Character
	if not character then
		warn("Cannot scale character: Character not found for", player.Name)
		return false
	end

	-- Scale the character using Model:ScaleTo API
	local success, errorMsg = pcall(function()
		character:ScaleTo(scale)
	end)

	if not success then
		warn("Failed to scale character:", errorMsg)
		return false
	end

	return true
end

-- Handle scale requests from clients
scaleEvent.OnServerEvent:Connect(function(player, scale)
	-- Validate input
	if type(scale) ~= "number" then
		warn("Invalid scale value received from", player.Name)
		return
	end

	-- Clamp scale to allowed range
	scale = math.clamp(scale, 0.25, 10)

	-- Apply scale
	local success = ScaleCharacter(player, scale)

	if success then
		print(player.Name .. "'s character scaled to " .. scale)
	else
		warn("Failed to scale", player.Name .. "'s character")
	end
end)

print("Character Size Handler initialized using Model:ScaleTo API")
