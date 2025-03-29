-- /ServerScriptService/DataStore/Values.lua
-- This file defines the data structure for player data storage
-- Represents the hierarchy and default values for all persistent player data

return { 
	--// Folders
	{Name = "Stats", Parent = "Player", Type = "Folder"},
	{Name = "Buttons", Parent = "Player", Type = "Folder"},
	{Name = "Other", Parent = "Player", Type = "Folder"},
	{Name = "Boosters", Parent = "Player", Type = "Folder"}, -- New folder for boosters

	--// Main Stats 
	{Name = "Money", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "Tokens", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "Rebirth", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},

	--// Fruit Currencies
	{Name = "HealingFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "AttackFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "DefenseFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "ElementalFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},

	--// Boosters
	{Name = "LightCrystals", Parent = "Boosters", Type = "NumberValue", StartingAmount = 0},
	{Name = "Mushrooms", Parent = "Boosters", Type = "NumberValue", StartingAmount = 0},
	{Name = "LavaBalls", Parent = "Boosters", Type = "NumberValue", StartingAmount = 0},
	{Name = "Fuel", Parent = "Boosters", Type = "NumberValue", StartingAmount = 0},
	{Name = "Bugs", Parent = "Boosters", Type = "NumberValue", StartingAmount = 0},

	--// Other
	{Name = "LastJoin", Parent = "Other", Type = "NumberValue", StartingAmount = 0},
}
