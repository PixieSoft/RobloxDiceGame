-- /ServerScriptService/Initialization/DiceSystemInit
local ServerScriptService = game:GetService("ServerScriptService")

-- Load the DiceSpawnerManager module
local DiceSpawnerManager = require(ServerScriptService.Modules.Dice.DiceSpawnerManager)

-- The manager will automatically start handling spawners when required
print("Dice Spawner System Initialized")
