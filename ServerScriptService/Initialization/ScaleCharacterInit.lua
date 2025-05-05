-- /ServerScriptService/Initialization/ScaleCharacterInit.lua
-- Script that initializes the ScaleCharacter module

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Debug system name for logging
local debugSystem = "Scaling"

-- The module auto-initializes, but we can explicitly initialize it again if needed
-- This is useful if we want to make sure initialization happens in a specific order
local success = ScaleCharacter.Initialize()

if success then
	Utility.Log(debugSystem, "info", "ScaleCharacter module initialized successfully")
else
	Utility.Log(debugSystem, "warn", "Failed to initialize ScaleCharacter module")
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
