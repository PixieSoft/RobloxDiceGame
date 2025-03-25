local ReplicatedStorage = game.ReplicatedStorage
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local Constants = require(Modules.ConstantsModule)
local Stat = require(ReplicatedStorage.Stat)

game.Players.PlayerAdded:Connect(function(player)
	-- Wait for stats to load before setting up leaderstats
	if not Stat.WaitForLoad(player) then return end

	-- Create a leaderstats folder for the player if it doesn't exist
	if not player:FindFirstChild("leaderstats") then
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local leaderstats = player:WaitForChild("leaderstats")

	-- Helper function to set up a fruit stat with Changed event listener
	local function setupFruitStat(fruitName)
		local fruitStat = Stat.Get(player, fruitName)

		local leaderstatValue = Instance.new("IntValue")
		leaderstatValue.Name = fruitName
		leaderstatValue.Value = fruitStat.Value
		leaderstatValue.Parent = leaderstats

		-- Set up Changed event listener to keep leaderstats in sync
		fruitStat.Changed:Connect(function()
			leaderstatValue.Value = fruitStat.Value
		end)
	end

	-- Set up all fruit types
	setupFruitStat(Constants.Fruit.Healing_Name)
	setupFruitStat(Constants.Fruit.Attack_Name)
	setupFruitStat(Constants.Fruit.Defense_Name)
	setupFruitStat(Constants.Fruit.Elemental_Name)
end)
