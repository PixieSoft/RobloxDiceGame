-- /ReplicatedStorage/Modules/Core/BoosterDefs/Pearls.lua
-- ModuleScript that defines the Pearls booster

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Booster definition 
return {
	-- +1m underwater breathing (get 5m free) and a speed boost
	-- also can buy longer base water breathing time
	-- in center of game, there's a cup. it gets a pearl in it for every pearl people find.
	-- anyone can fight the boss. if you win, you get all the pearls. split if multiplayer.
	-- exclusive boss fights? optional for starter?
	name = "Pearls",
	description = "Applies a glitch effect to your dice for 30 minutes",
	imageId = "rbxassetid://109760311419104z",
	boosterType = "DiceBoost", -- Will be mapped to Boosters.BoosterTypes.DICE
	duration = 1800, -- 30 minutes = 1800 seconds
	stacks = false,
	canCancel = true,

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
