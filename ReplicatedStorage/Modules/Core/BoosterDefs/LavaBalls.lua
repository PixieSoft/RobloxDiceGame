-- /ReplicatedStorage/Modules/Core/BoosterDefs/LavaBalls.lua
-- ModuleScript that defines the LavaBalls booster

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

-- Booster definition 
return {
	-- drop a lava block. 1x1 default. 2x2 if spend 10. 3x3 for 100. 4x4 for 1000.
	-- 5s per ball
	-- generally used for jump boosting
	-- use while jumping. summons in the air. can use this to hold yourself and jump again.
	-- comes into existence colliding only with player. anchors immediately. then becomes
	-- collidable with everything. keep it flat and aligned with the world. 
	name = "Lava Ball",
	description = "Drops a block under your feet for 5s. Using 10 doubles the size. Using 100 triples the size.",
	imageId = "rbxassetid://73449632309262",
	boosterType = "PlayerBoost", -- Will be mapped to Boosters.BoosterTypes.PLAYER
	duration = 5, -- 5 seconds
	stacks = false,
	canCancel = true,

	-- Function that runs when booster is activated
	onActivate = function(player, qty)
		-- This function only runs on the server
		if not IsServer then return function() end end

		-- Return a proper cleanup function
		return function() end
	end
}
