-- In this module you can edit the multiplier's in game.

local Multipliers = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Stat = require(ReplicatedStorage.Stat)

--// Main
function Multipliers.GetMoneyMultiplier(Player)
	local Multi = 1
	
	-- Gamepass
	local DoubleMoneyExists = ReplicatedStorage.GamepassIds:FindFirstChild("DoubleMoney")
	
	if DoubleMoneyExists then
		local DoubleMoneyOwned = Stat.Get(Player, "DoubleMoney").Value
		
		if DoubleMoneyOwned then
			Multi *= 2
		end
	end
	
	-- Rebirth
	local Rebirth = Stat.Get(Player, "Rebirth")
	Multi *= (Rebirth.Value + 1)
	
	return Multi	
end

return Multipliers
