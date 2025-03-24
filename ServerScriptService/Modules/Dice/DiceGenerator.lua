-- /ServerScriptService/Modules/Dice/DiceGenerator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DiceConstants = require(ServerScriptService.Modules.Dice.DiceConstants)
local DiceModule = require(ReplicatedStorage.ModuleScripts.DiceModule)
local UtilityModule = require(ReplicatedStorage.ModuleScripts.UtilityModule)
local DiceAppearance = require(ServerScriptService.Modules.Dice.DiceAppearance)

local DiceGenerator = {}

-- Get template die reference
local DiceTemplate = ReplicatedStorage.Assets.Dice.Dice

-------------------------
-- Helper Functions
-------------------------
-- Generates stats based on priority order and tier maximum
local function GenerateStatsFromPriority(statPriority, tierData)
	local stats = {
		Attack = 0,
		Defense = 0,
		Healing = 0,
		Elemental = 0
	}

	local remaining = tierData.MaxStat

	-- Generate stats in priority order
	for _, statName in ipairs(statPriority) do
		if remaining > 0 then
			-- Roll from 0 to remaining points
			local allocation = math.random(0, remaining)
			stats[statName] = allocation
			remaining = remaining - allocation
		else
			-- No points left, set to 0
			stats[statName] = 0
		end
	end

	-- Any remaining points after all stats are processed are simply ignored

	return stats
end

-------------------------
-- Main Functions
-------------------------
-- Generate die data based on spawn configuration
function DiceGenerator.GenerateDieData(config)
	-- Validate config
	assert(config, "DiceSpawnerConfig required")
	assert(config.tier, "Config must specify tier")

	-- Get tier data
	local tierData = DiceConstants.Tier[config.tier]
	assert(tierData, "Invalid tier specified in config")

	-- Generate stats based on priority
	local stats = GenerateStatsFromPriority(config.fullStatPriority, tierData)

	-- Create die data table
	local dieData = {
		-- Stats
		Attack = stats.Attack,
		Defense = stats.Defense,
		Healing = stats.Healing,
		Elemental = stats.Elemental,

		-- Configuration values
		Name = "Die" .. "_" .. math.random(100,999),
		Tier = config.tier,
		Category = config.category,
		Special = config.special,
		AttackElement = config.attackElement,
		ResistElement = config.resistElement,

		-- Tier-based attributes
		MaxHP = tierData.MaxHP, -- Make sure this is correctly set from the tier data
		HP = tierData.MaxHP, -- Start at full health
		RollSpeed = tierData.RollSpeed,
		SpecialBonus = tierData.SpecialBonus,
		MaxXP = tierData.MaxXP,
		XP = 0, -- Start with no XP

		-- Default attributes
		FrameEnabled = true,
		Resistance = 10 * config.tier, -- Scale resistance with tier
	}

	return dieData
end

-- Creates a die in the workspace at the specified position with optional CFrame
function DiceGenerator.CreateDieInWorld(config, positionOrCFrame)
	-- Generate die data
	local dieData = DiceGenerator.GenerateDieData(config)

	-- Clone template
	local diePart = DiceTemplate:Clone()

	-- Check if we received a position or a CFrame
	if typeof(positionOrCFrame) == "Vector3" then
		diePart.Position = positionOrCFrame
	elseif typeof(positionOrCFrame) == "CFrame" then
		diePart.CFrame = positionOrCFrame
	else
		warn("CreateDieInWorld received invalid position type: " .. typeof(positionOrCFrame))
		diePart.Position = Vector3.new(0, 0, 0)
	end

	-- Set the die's name to match its Name attribute
	diePart.Name = dieData.Name

	-- Set attributes based on dieData
	for key, value in pairs(dieData) do
		diePart:SetAttribute(key, value)
	end

	-- Set up visual appearance
	DiceAppearance.ConfigureDie(diePart, {
		frameStyle = config.frameStyle or "Classic"
	})

	-- Parent to workspace
	diePart.Parent = workspace

	return diePart
end

-- Creates a die directly in a player's inventory
function DiceGenerator.CreateDieInInventory(config, player)
	-- Generate die data
	local dieData = DiceGenerator.GenerateDieData(config)

	-- Get or create inventory folder
	local inventory = player:FindFirstChild("DiceInventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "DiceInventory"
		inventory.Parent = player
	end

	-- Clone template
	local diePart = DiceTemplate:Clone()

	-- Set the die's name to match its Name attribute
	diePart.Name = dieData.Name

	-- Set attributes based on dieData
	for key, value in pairs(dieData) do
		diePart:SetAttribute(key, value)
	end

	-- Set up visual appearance
	DiceAppearance.ConfigureDie(diePart, {
		frameStyle = config.frameStyle or "Classic"
	})

	-- Parent to inventory
	diePart.Parent = inventory

	return diePart
end

return DiceGenerator
