-- /ReplicatedStorage/Modules/Core/BoosterDefs/LavaBalls.lua
-- ModuleScript that defines the LavaBalls booster behavior

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import utility module
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Booster definition 
return {
	-- drop a lava block. 1x1 default. 2x2 if spend 10. 3x3 for 100. 4x4 for 1000.
	-- 5s per ball
	-- generally used for jump boosting
	-- use while jumping. summons in the air. can use this to hold yourself and jump again.
	-- comes into existence colliding only with player. anchors immediately. then becomes
	-- collidable with everything. keep it flat and aligned with the world. 
	name = "Lava Ball",
	description = "Create a platform under you for 5s per ball. Size doubles at 10, 100, and 1000 balls.",
	imageId = "rbxassetid://73449632309262",
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 5, -- 5 seconds
	stacks = false,
	canCancel = true,

	-- Function to calculate and return effect description
	calculateEffect = function(spendingAmount)
		if spendingAmount <= 0 then
			return "Select lava balls to use"
		end

		local totalDuration = 5 * spendingAmount -- 5s per ball
		local timeText = Utility.FormatTimeDuration(totalDuration)

		local sizeText = "1x1"
		if spendingAmount >= 1000 then
			sizeText = "4x4 size"
		elseif spendingAmount >= 100 then
			sizeText = "3x3 size"
		elseif spendingAmount >= 10 then
			sizeText = "2x2 size"
		end

		local timeText = Utility.FormatTimeDuration(totalDuration) -- Always 5 seconds

		local pluralText = spendingAmount > 1 and "lava balls" or "lava ball"
		return "Create a " .. sizeText .. " platform under your feet for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
	end,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
		-- This function only runs on the server
		if not IsServer then return function() end end

		-- Return a proper cleanup function
		return function() end
	end
}
