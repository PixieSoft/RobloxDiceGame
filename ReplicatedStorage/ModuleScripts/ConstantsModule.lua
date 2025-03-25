-- /ReplicatedStorage/ModuleScripts/ConstantsModule

local ConstantsModule = {
	Fruit = {
		Healing_Name = "HealingFruit",
		Attack_Name = "AttackFruit",
		Defense_Name = "DefenseFruit",
		Elemental_Name = "ElementalFruit",
		Types = {"HealingFruit", "AttackFruit", "DefenseFruit", "ElementalFruit"}, -- Added for easy iteration
	},

	SpawnerSettings = {
		-- Group Settings
		GroupSpawnSettings_Name = "GroupSpawnSettings",
		ActiveSpawners_Name = "ActiveSpawners",
		OverrideSpawners_Name = "OverrideSpawners",

		-- Timer Settings
		DecayTimer_Name = "MinutesUntilDecay",
		SpawnTimerMax_Name = "SpawnTimerMax",
		SpawnTimerMin_Name = "SpawnTimerMin",
		SpawnTimerMax_Default = 30,
		SpawnTimerMin_Default = 60,
	},

	-- Consolidated spawn settings
	FruitSpawners = {
		DefaultSettings = {
			MinSpawn = 1,
			MaxSpawn = 1,
			Probability = 0,
		},

		Attack = {
			MaxSpawn_Name = "AttackFruitMaxSpawn",
			MinSpawn_Name = "AttackFruitMinSpawn",
			Probability_Name = "AttackFruitProbability",
		},
		Defense = {
			MaxSpawn_Name = "DefenseFruitMaxSpawn",
			MinSpawn_Name = "DefenseFruitMinSpawn",
			Probability_Name = "DefenseFruitProbability",
		},
		Elemental = {
			MaxSpawn_Name = "ElementalFruitMaxSpawn",
			MinSpawn_Name = "ElementalFruitMinSpawn",
			Probability_Name = "ElementalFruitProbability",
		},
		Healing = {
			MaxSpawn_Name = "HealingFruitMaxSpawn",
			MinSpawn_Name = "HealingFruitMinSpawn",
			Probability_Name = "HealingFruitProbability",
		},
	}
}

return ConstantsModule
