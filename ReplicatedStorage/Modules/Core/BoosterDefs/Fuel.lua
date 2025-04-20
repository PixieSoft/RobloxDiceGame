-- /ReplicatedStorage/Modules/Core/BoosterDefs/Fuel.lua
-- ModuleScript that defines the Fuel booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Booster definition 
return {
	-- 1 fuel used per teleport
	-- 1 fuel to fill gauge for jetpack to fly, minecarts to go faster?
	-- make flowers grow?
	-- 100 poops to summon boss in greenhouse or somewhere?
	name = "Fuel",
	description = "Fill your fuel gauge for transportation.",
	imageId = "rbxassetid://7123456792", -- Replace with actual image ID
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 60, -- Not really a duration-based booster, but set to 60 seconds
	stacks = false, -- Cannot stack, simply fills the gauge
	canCancel = false, -- Nothing to cancel

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select fuel to use"
		end

		local fuelText = spendingAmount > 1 and "poops" or "poop"
		return "Fill your fuel gauge using " .. spendingAmount .. " " .. fuelText .. "."
	end,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
		-- This function only runs on the server
		if not IsServer then return function() end end

		-- Return a proper cleanup function
		return function() end
	end
}
