-- This file is under DataManager in Roxlox Studio Explorer

return { 
	--// Folders
	{Name = "Stats", Parent = "Player", Type = "Folder"},
	{Name = "Buttons", Parent = "Player", Type = "Folder"},
	{Name = "Other", Parent = "Player", Type = "Folder"},

	--// Main Stats 
	{Name = "Money", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "Tokens", Parent = "Stats", Type = "NumberValue", StartingAmount = 0}, -- Added new Tokens currency
	{Name = "Rebirth", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},

	--// Fruit Currencies
	{Name = "HealingFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "AttackFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "DefenseFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},
	{Name = "ElementalFruit", Parent = "Stats", Type = "NumberValue", StartingAmount = 0},

	--// Other
	{Name = "LastJoin", Parent = "Other", Type = "NumberValue", StartingAmount = 0},
}
