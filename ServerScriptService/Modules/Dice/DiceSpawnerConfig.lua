-- /ServerScriptService/Modules/Dice/DiceSpawnerConfig
-- Place this module in ServerScriptService since it's only used for server-side spawning
local DiceSpawnerConfig = {}

-- Constants
local ValidTiers = {1, 2, 3, 4}
local ValidCategories = {
	"Dark",
	"Fire",
	"Light",
	"Metal", 
	"Nature",
	"Rainbow",
	"TwinTailed",
	"Water"
}
local ValidSpecials = {
	"DoubleDefense",
	"Fireball",
	"DoubleDefense",
	"ShieldBash",
	"Regeneration",
	"None"
}
local ValidElements = {
	"Dark",
	"Fire",
	"Nature",
	"Light",
	"Metal",
	"Water"
}
local ValidFrameStyles = {
	"Classic",
	"Fire",
	"Water",
	"Nature",
	"Gold",
	"Silver",
	"Shadow",
	"Light"
}
local DefaultStatOrder = {"Healing", "Attack", "Defense", "Elemental"}

-- Utility function to check if a value exists in a table
local function Contains(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

-- Get full stat priority by filling in missing stats in default order
local function GetFullStatPriority(partialPriority)
	local fullPriority = {}
	local usedStats = {}

	-- Add specified stats first
	for _, stat in ipairs(partialPriority) do
		table.insert(fullPriority, stat)
		usedStats[stat] = true
	end

	-- Add remaining stats in default order
	for _, stat in ipairs(DefaultStatOrder) do
		if not usedStats[stat] then
			table.insert(fullPriority, stat)
		end
	end

	return fullPriority
end

-- Validate the configuration
local function ValidateConfig(config)
	local errors = {}

	-- Validate tier
	if not Contains(ValidTiers, config.tier) then
		table.insert(errors, string.format("Invalid tier: %d. Must be between 1 and 4.", config.tier))
	end

	-- Validate category
	if not Contains(ValidCategories, config.category) then
		table.insert(errors, "Invalid category: " .. config.category)
	end

	-- Validate special
	if not Contains(ValidSpecials, config.special) then
		table.insert(errors, "Invalid special: " .. config.special)
	end

	-- Validate elements
	if not Contains(ValidElements, config.attackElement) then
		table.insert(errors, "Invalid attack element: " .. config.attackElement)
	end
	if not Contains(ValidElements, config.resistElement) then
		table.insert(errors, "Invalid resist element: " .. config.resistElement)
	end

	-- Validate frame style if provided
	if config.frameStyle and not Contains(ValidFrameStyles, config.frameStyle) then
		table.insert(errors, "Invalid frame style: " .. config.frameStyle)
	end

	-- Validate stat priority
	local usedStats = {}
	for _, stat in ipairs(config.statPriority) do
		if usedStats[stat] then
			table.insert(errors, "Duplicate stat in priority list: " .. stat)
		end
		if not Contains(DefaultStatOrder, stat) then
			table.insert(errors, "Invalid stat type: " .. stat)
		end
		usedStats[stat] = true
	end

	-- Validate spawnerEnabled flag if provided
	if config.spawnerEnabled ~= nil and type(config.spawnerEnabled) ~= "boolean" then
		table.insert(errors, "SpawnerEnabled flag must be a boolean (true or false)")
	end

	-- Validate configEnabled flag if provided
	if config.configEnabled ~= nil and type(config.configEnabled) ~= "boolean" then
		table.insert(errors, "ConfigEnabled flag must be a boolean (true or false)")
	end

	return {
		isValid = #errors == 0,
		errors = errors
	}
end

-- Create a new dice spawner configuration
function DiceSpawnerConfig.New(config)
	local validation = ValidateConfig(config)

	if not validation.isValid then
		error("Invalid configuration: " .. table.concat(validation.errors, ", "))
	end

	local fullStatPriority = GetFullStatPriority(config.statPriority)

	return {
		tier = config.tier,
		category = config.category,
		special = config.special,
		attackElement = config.attackElement,
		resistElement = config.resistElement,
		statPriority = config.statPriority,
		fullStatPriority = fullStatPriority,
		frameStyle = config.frameStyle,
		spawnerEnabled = config.spawnerEnabled ~= false, -- Default to true if not specified
		configEnabled = config.configEnabled ~= false -- Default to true if not specified
	}
end

return DiceSpawnerConfig
