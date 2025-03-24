-- /ServerScriptService/Modules/Dice/DiceConstants

local DiceConstants = {
	-- Tier-specific data for dice
	Tier = {
		[1] = {
			MaxStat = 9,
			MaxHP = 10,
			RollSpeed = 1.0,
			SpecialBonus = "",
			MaxXP = 9
		},
		[2] = {
			MaxStat = 99,
			MaxHP = 100, -- Ensure this is 100, not 99
			RollSpeed = 1.2,
			SpecialBonus = "",
			MaxXP = 99
		},
		[3] = {
			MaxStat = 999,
			MaxHP = 1000,
			RollSpeed = 1.5,
			SpecialBonus = "",
			MaxXP = 999
		},
		[4] = {
			MaxStat = 9999,
			MaxHP = 10000,
			RollSpeed = 2.0,
			SpecialBonus = "",
			MaxXP = 9999
		}
	},

	-- Names of each face on the die template
	FaceNames = {
		"FrontFace",
		"AttackFace",
		"DefenseFace",
		"ElementalFace",
		"HealingFace",
		"SpecialFace"
	},

	-- Bar elements found in each face
	BarElements = {
		"BarTop",
		"BarBottom",
		"BarLeft",
		"BarRight"
	},

	-- Stat details including icon and side placement
	StatDetails = {
		Attack = {
			Icon = "⚔️",
			Side = "BarLeft"
		},
		Defense = {
			Icon = "🛡️",
			Side = "BarTop"
		},
		Healing = {
			Icon = "🩹",
			Side = "BarBottom"
		},
		Elemental = {
			Icon = "🔥", -- Default icon, will be replaced by element-specific icon
			Side = "BarRight"
		}
	},

	-- Valid categories for dice
	ValidCategories = {
		"Dark",
		"Fire",
		"Light",
		"Metal", 
		"Nature",
		"Rainbow",
		"TwinTailed",
		"Water"
	},

	-- Valid special abilities for dice
	ValidSpecials = {
		"DoubleDefense",
		"Fireball",
		"Pyrotechnics",
		"Regeneration",
		"ShieldBash",
		"None"
	},

	-- Valid elements for dice
	ValidElements = {
		"Dark",
		"Fire",
		"Nature",
		"Light",
		"Metal",
		"Water"
	},

	-- Default stat order for priority
	DefaultStatOrder = {
		"Healing", 
		"Attack", 
		"Defense", 
		"Elemental"
	}
}

return DiceConstants
