-- /ReplicatedStorage/Modules/Core/BoosterDefs/Pearls.lua
-- ModuleScript that defines the Pearls booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Create a table that we can reference from within its own methods
local PearlsBooster = {}

-- Define properties
PearlsBooster.name = "Pearls"
PearlsBooster.description = "Add +1m of underwater breathing."
PearlsBooster.imageId = "rbxassetid://109760311419104z"
PearlsBooster.boosterType = "DiceBoost" -- Affects dice appearance or performance
PearlsBooster.duration = 60 -- 1 minute per pearl
PearlsBooster.stacks = false
PearlsBooster.canCancel = true

-- Function to calculate and return effect description
PearlsBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select pearls to use"
	end

	local totalDuration = PearlsBooster.duration * spendingAmount -- Self-referenced duration
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pearlText = spendingAmount > 1 and "pearls" or "pearl"
	return "Adds " .. timeText .. " of underwater breathing using " .. spendingAmount .. " " .. pearlText .. "."
end

-- Function that runs when booster is activated
PearlsBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Check if the UsePearlEvent exists
	local usePearlEvent = ReplicatedStorage.Events.Core:FindFirstChild("UsePearlEvent")

	-- Fire server event if it exists
	if usePearlEvent then
		usePearlEvent:FireServer(player, qty)
	else
		print("Warning: UsePearlEvent not found for Pearl booster")
	end

	-- Return a proper cleanup function
	return function()
		print("Pearl booster effect ended for " .. player.Name)
	end
end

return PearlsBooster
