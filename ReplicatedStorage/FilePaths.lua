local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FilePaths = {}

FilePaths.Core = {
	Constants = ServerScriptService.Modules.Core.Constants,
	EventManager = ServerScriptService.Modules.Shared.EventManager,
	Types = ServerScriptService.Modules.Shared.Types,
	Utility = ServerScriptService.Modules.Shared.Utility,
}

FilePaths.Combat = {
	CombatManager = ServerScriptService.Modules.Combat.CombatManager,
	DiceManager = ServerScriptService.Modules.Combat.DiceManager,
	SpecialActions = ServerScriptService.Modules.Combat.SpecialActions,
}

FilePaths.Fruit = {
	FruitManager = ServerScriptService.Modules.Fruit.FruitManager,
	GroupManager = ServerScriptService.Modules.Fruit.FruitSpawnerGroupManager,
	SpawnerManager = ServerScriptService.Modules.Fruit.FruitSpawnerManager,
}

FilePaths.Assets = {
	Cart = ReplicatedStorage.Assets.Cart,
	DieFaces = ReplicatedStorage.Assets.DieFaces,
	Fruit = ReplicatedStorage.Assets.Fruit,
}

-- Verify specified Module Paths exist
for category, paths in pairs(FilePaths) do
	for name, path in pairs(paths) do
		assert(path ~= nil, string.format("Missing module path: %s.%s", category, name))
	end
end

return FilePaths
