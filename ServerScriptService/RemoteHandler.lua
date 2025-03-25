--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Requires
local Stat = require(ReplicatedStorage.Stat)

--// Variables
local Remotes = ReplicatedStorage.RemoteEvents

Remotes.BuyRebirth.OnServerEvent:Connect(function(Player) -- Needs a debounce
	local Money = Stat.Get(Player, "Money")
	local Rebirth = Stat.Get(Player, "Rebirth")
	
	local RebirthPrice = ReplicatedStorage["Game Settings"].Balancing.RebirthPrice.Value
	
	if Money.Value >= RebirthPrice * (Rebirth.Value + 1) then
		Money.Value = 0
		
		local AmountOfButtons = #ReplicatedStorage.TemplatePlot.Buttons:GetChildren()
		for i = 1, AmountOfButtons do
			Stat.Get(Player, "Button"..i).Value = false	
		end
		
		Rebirth.Value += 1
		
		-- Clear Drops
		local PlayerDropperPartsFolder = workspace.DropperParts:FindFirstChild(Player.Name .. "-DropperParts")
		
		for _, Drop in PlayerDropperPartsFolder:GetChildren() do
			Drop:Destroy()
		end
	end
end)
