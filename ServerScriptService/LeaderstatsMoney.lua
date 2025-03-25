--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Stat = require(ReplicatedStorage.Stat)

Players.PlayerAdded:Connect(function(Player)
	if not Stat.WaitForLoad(Player) then return end -- player left!
	
	local MoneyStat = Stat.Get(Player, "Money")
	
	local Money = Instance.new("NumberValue", Player.leaderstats)
	Money.Name = "Money"
	Money.Value = MoneyStat.Value
	
	MoneyStat.Changed:Connect(function()
		Money.Value = MoneyStat.Value
	end)
end)
