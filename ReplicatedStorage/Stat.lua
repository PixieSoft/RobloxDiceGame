--[[
HOW TO USE THIS MODULE

Stat.Get(Player, StatName(string)) returns the Stat instance, looks through all folders in ReplicatedStorage.Data until it's found.
Stat.GetDataFolder(Player) returns ReplicatedStorage.Data[PlayerName]
Stat.WaitForLoad(Player) loads and returns a boolean wether the loading succeeded or not.

]]

local Stat = {}
Stat.Cached = {} -- Stat's that have been looked up previously are stored here. This makes it so there's no searching the 2nd time you use it

local Data

local function CreatePath(EndInstance, StartInstance)
	local Path = {}
	local CurrentLayer = StartInstance
	repeat -- loop that imports the names of the parents
		table.insert(Path, 1, CurrentLayer.Parent.Name)
		CurrentLayer = CurrentLayer.Parent
	until -- until the parent is the playerdata
	CurrentLayer.Parent == EndInstance
	return Path
end

local function ReadPath(Path, StartInstance)
	local StatInstance = StartInstance
	for _, Child in Path do
		StatInstance = StatInstance[Child] -- this creates the path one by one
	end
	return StatInstance
end

function Stat.Get(Player: Player, StatName: string) -- returns stat instance
	if StatName == nil then -- the Player argument is actually the StatName, and StatName is nil, aka its called from the client
		StatName = Player
		Player = game.Players.LocalPlayer
	end
	
	if not Data then
		Data = game.ReplicatedStorage:WaitForChild("Data")
	end

	local PlayerData = Data:FindFirstChild(Player.Name)
	
	if not PlayerData then
		task.wait(0.1)
		return Stat.Get(Player, StatName)
	end

	local CachedStat = Stat.Cached[StatName]
	if CachedStat then -- stat is being looked up for the second time if this is true
		return CachedStat == {} and PlayerData[StatName] or ReadPath(CachedStat, PlayerData)[StatName] -- returns a StatInstance
	end

	-- first time u look up the stat
	if PlayerData.Stats:FindFirstChild(StatName) then
		Stat.Cached[StatName] = {"Stats"}
		return PlayerData.Stats[StatName]
	else
		for _,v in PlayerData:GetDescendants() do
			if v.Name == StatName then
				Stat.Cached[StatName] = {}

				--// Creates a path and puts it into the Cached folder so it can be accessed directly next time the stat is looked up
				if v.Parent ~= PlayerData then -- check if it even has a path
					Stat.Cached[StatName] = CreatePath(PlayerData, v) -- creates a table with the childnames to create the path
				end

				return v
			end
		end
	end
	
	return nil
end

function Stat.GetDataFolder(Player: Player)
	if not Data then
		Data = game.ReplicatedStorage.Data
	end
	
	return Data[Player.Name]
end

function Stat.WaitForLoad(Player: any): boolean
	Player = Player or game.Players.LocalPlayer	
	repeat wait() until Player:FindFirstChild("Loaded") and Player.Loaded.Value and Player.Parent ~= nil
	
	return Player.Parent ~= nil
end

return Stat
