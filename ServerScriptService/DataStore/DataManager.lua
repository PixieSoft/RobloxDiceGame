--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Require
local DataManager = require(script.Parent.DataManager)

--// Setup
local DataFolder = Instance.new("Folder", game.ReplicatedStorage)
DataFolder.Name = "Data" -- create data folder

--// Functions
function OnPlayerAdded(Player)
	local Loaded = Instance.new("BoolValue")
	Loaded.Name = "Loaded"
	Loaded.Parent = Player

	DataManager.OnPlayerAdded(Player) -- load profile
	local Folder = DataManager:CreateFolder(Player) -- creates all folders based on profile

	local leaderstats = Instance.new("Folder", Player)
	leaderstats.Name = "leaderstats"

	Loaded.Value = true

	while task.wait(10) do -- upload every 10 seconds (its not like a save, its just so the ProfileService has the data cached)
		if Player.Parent == nil or Folder.Parent == nil then break end
		DataManager:FolderToProfile(Player) -- converts a folder to a table and uploads it to the profile
	end
end

function OnPlayerRemoved(Player)
	DataManager:FolderToProfile(Player) -- converts a folder to a table and uploads it to profile
	DataManager.OnPlayerRemoving(Player) -- saves profile
end

--// Main
Players.PlayerAdded:Connect(OnPlayerAdded)

Players.PlayerRemoving:Connect(OnPlayerRemoved)

game:BindToClose(function()
	for _, Player in Players:GetPlayers() do
		OnPlayerRemoved(Player)
	end
end)
