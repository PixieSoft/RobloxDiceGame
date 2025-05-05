-- /ReplicatedStorage/Modules/Core/BoosterDefs/LavaBalls.lua
-- ModuleScript that defines the LavaBalls booster behavior

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Debug system name for logging
local debugSystem = "LavaBalls"

-- Create a table that we can reference from within its own methods
local LavaBallsBooster = {}

-- Define properties
LavaBallsBooster.name = "Lava Ball"
LavaBallsBooster.description = "Create platform under you for 5s per ball. Size increases at 10, 100, 1000."
LavaBallsBooster.imageId = "rbxassetid://73449632309262"
LavaBallsBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
LavaBallsBooster.duration = 5 -- 5 seconds
LavaBallsBooster.stacks = false
LavaBallsBooster.canCancel = true

-- Function to calculate and return effect description
LavaBallsBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select lava balls to use"
	end

	local totalDuration = LavaBallsBooster.duration * spendingAmount -- Use self-referenced duration
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local sizeText = "1x1"
	if spendingAmount >= 1000 then
		sizeText = "4x4 size"
	elseif spendingAmount >= 100 then
		sizeText = "3x3 size"
	elseif spendingAmount >= 10 then
		sizeText = "2x2 size"
	end

	local pluralText = spendingAmount > 1 and "lava balls" or "lava ball"
	return "Create a " .. sizeText .. " platform for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
end

-- Function that runs when booster is activated
LavaBallsBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Implementation of creating platforms would go here
	-- This is a placeholder that would be filled with actual platform creation code

	Utility.Log(debugSystem, "info", "Activated Lava Ball booster for " .. player.Name .. " with " .. qty .. " balls")

	-- Return a proper cleanup function
	return function()
		Utility.Log(debugSystem, "info", "Lava Ball platforms cleaned up for " .. player.Name)
	end
end

return LavaBallsBooster
