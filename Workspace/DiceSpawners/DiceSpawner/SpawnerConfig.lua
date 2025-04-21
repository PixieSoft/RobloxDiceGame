-- /Workspace/DiceSpawners/DiceSpawner/SpawnerConfig.lua
local ServerScriptService = game:GetService("ServerScriptService")
local DiceSpawnerConfig = require(ServerScriptService.Modules.Dice.DiceSpawnerConfig)

-- Configuration values for this spawner
local config = {
	-- SpawnerEnabled: Whether this spawner is active and will spawn dice
	-- Setting to false disables dice spawning without removing the spawner
	spawnerEnabled = true,

	-- ConfigEnabled: Whether this spawner's configuration should be applied
	-- Setting to false makes the spawner use default configuration instead
	configEnabled = false,

	-- Tier: Controls the base stats and number of rounds in combat
	-- Valid options: 1, 2, 3, 4
	tier = 3,

	-- Category: Determines which set of face images to use from DieFaces
	-- Valid options: "Dark", "Fire", "Light", "Metal", "Nature", "Rainbow", "TwinTailed", "Water"
	category = "Light",

	-- Special: The special ability this die will have
	-- Valid options: "DoubleDefense", "Fireball", "None"
	special = "DoubleDefense",

	-- AttackElement: The element type for this die's elemental attacks
	-- Valid options: "Dark", "Fire", "Nature", "Light", "Metal", "Water"
	attackElement = "Light",

	-- ResistElement: The element type this die has resistance against
	-- Valid options: "Dark", "Fire", "Nature", "Light", "Metal", "Water"
	resistElement = "Dark",

	-- StatPriority: Order of importance for stats (remaining stats will be added in default order)
	-- Valid stats: "Healing", "Attack", "Defense", "Elemental"
	-- Note: You don't need to specify all stats - unspecified ones will be added in default order
	statPriority = { },
	
	-- FrameStyle: Style of frame to apply to the dice.
	-- THIS IS JUST FOR TESTING: Need to update the list of styles and have some kind of
	-- mapping from die type or element or something to style. May want to leave this here
	-- as a default or override though.
	frameStyle = "Light",
}

-- Create and return the configuration
return DiceSpawnerConfig.New(config)
