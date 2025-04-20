-- /ReplicatedStorage/Modules/Core/BoosterDefs/Pearls.lua
-- ModuleScript that defines the Pearls booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Booster definition 
return {
	-- +1m underwater breathing (get 5m free) and a speed boost
	-- also can buy longer base water breathing time
	-- in center of game, there's a cup. it gets a pearl in it for every pearl people find.
	-- anyone can fight the boss. if you win, you get all the pearls. split if multiplayer.
	-- exclusive boss fights? optional for starter?
	name = "Pearls",
	description = "Add +1m of underwater breathing.",
	imageId = "rbxassetid://109760311419104z",
	boosterType = "DiceBoost",     -- Affects dice appearance or performance
	duration = 60,
	stacks = false,
	canCancel = true,

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select pearls to use"
		end

		local totalDuration = 60 * spendingAmount -- 30 minutes per pearl
		local timeText = Utility.FormatTimeDuration(totalDuration)

		local pearlText = spendingAmount > 1 and "pearls" or "pearl"
		return "Adds " .. timeText .. " of underwater breathing using " .. spendingAmount .. " " .. pearlText .. "."
	end,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
		-- This function only runs on the server
		if not IsServer then return function() end end

		-- Fire server event 
		local UsePearlEvent = ReplicatedStorage.Events.Core:WaitForChild("UsePearlEvent")
		UsePearlEvent:FireServer(player, qty)

		-- Return a proper cleanup function
		return function() end
	end
}
