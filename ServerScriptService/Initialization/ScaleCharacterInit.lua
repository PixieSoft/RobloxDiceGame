-- /ServerScriptService/Initialization/ScaleCharacterInit.lua
-- Script that initializes the ScaleCharacter module

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load the ScaleCharacter module
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)

-- The module auto-initializes, but we can explicitly initialize it again if needed
-- This is useful if we want to make sure initialization happens in a specific order
local success = ScaleCharacter.Initialize()

if success then
	print("ScaleCharacter module initialized successfully")
else
	warn("Failed to initialize ScaleCharacter module")
end

-- Example of how to use the module (for reference):
--[[
-- Scale a player to a specific numeric value:
ScaleCharacter.SetScale(player, 2.5)

-- Scale a player using a preset:
ScaleCharacter.SetScale(player, "large")

-- Get a player's current scale (returns value and name):
local scaleValue, scaleName = ScaleCharacter.GetScale(player)
]]
