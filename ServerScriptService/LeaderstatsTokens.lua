local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Stat = require(ReplicatedStorage.Stat)

Players.PlayerAdded:Connect(function(Player)
	if not Stat.WaitForLoad(Player) then return end -- player left!

	local TokensStat = Stat.Get(Player, "Tokens")

	local Tokens = Instance.new("NumberValue", Player.leaderstats)
	Tokens.Name = "Tokens"
	Tokens.Value = TokensStat.Value

	TokensStat.Changed:Connect(function()
		Tokens.Value = TokensStat.Value
	end)
end)
