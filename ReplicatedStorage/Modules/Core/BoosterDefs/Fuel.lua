-- /ReplicatedStorage/Modules/Core/BoosterDefs/Fuel.lua
-- ModuleScript that defines the Fuel booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Create a table that we can reference from within its own methods
local FuelBooster = {}

-- Define properties
FuelBooster.name = "Fuel"
FuelBooster.description = "Fill your fuel gauge for transportation."
FuelBooster.imageId = "rbxassetid://7123456792" -- Replace with actual image ID
FuelBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
FuelBooster.duration = 60 -- Not really a duration-based booster, but set to 60 seconds
FuelBooster.stacks = false -- Cannot stack, simply fills the gauge
FuelBooster.canCancel = false -- Nothing to cancel

-- Function to calculate and return effect description
FuelBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select fuel to use"
	end

	-- Even though this doesn't use duration directly, we could reference it if needed
	-- This shows the pattern still works for non-duration-dependent calculations
	local fuelText = spendingAmount > 1 and "poops" or "poop"
	return "Fill your fuel gauge using " .. spendingAmount .. " " .. fuelText .. "."
end

-- Function that runs when booster is activated
FuelBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Placeholder for actual fuel system implementation
	print("Activated Fuel booster for " .. player.Name .. " with " .. qty .. " fuel")

	-- Return a proper cleanup function
	return function()
		-- No cleanup needed for this booster
	end
end

return FuelBooster
