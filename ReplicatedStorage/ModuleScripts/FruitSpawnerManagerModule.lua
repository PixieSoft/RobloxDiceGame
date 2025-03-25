local FruitSpawnerManagerModule = {}

-- Debug Settings
local DEBUG_ENABLED = false

local function debugPrint(...)
	if DEBUG_ENABLED then
		print("[SpawnerManager]", ...)
	end
end

-- Services
local CollectionService = game:GetService("CollectionService")

-- Module Dependencies
local Constants = require(script.Parent.ConstantsModule)
local FruitManagerModule = require(script.Parent.FruitManagerModule)

-- Private variables
local spawners = {}

--[[ Spawner Setup and Management ]]--
function FruitSpawnerManagerModule.EnsureSpawnerSetup(spawner)
	if not spawner:IsA("BasePart") then return end

	local flags = spawner:FindFirstChild("Flags") or Instance.new("Folder")
	flags.Name = "Flags"
	flags.Parent = spawner

	local activeFlag = flags:FindFirstChild("Active") or Instance.new("BoolValue")
	activeFlag.Name = "Active"
	activeFlag.Value = false
	activeFlag.Parent = flags

	-- Set default spawn timer attributes
	if spawner:GetAttribute(Constants.SpawnerSettings.SpawnTimerMin_Name) == nil then
		spawner:SetAttribute(Constants.SpawnerSettings.SpawnTimerMin_Name, 
			Constants.SpawnerSettings.SpawnTimerMin_Default)
	end
	if spawner:GetAttribute(Constants.SpawnerSettings.SpawnTimerMax_Name) == nil then
		spawner:SetAttribute(Constants.SpawnerSettings.SpawnTimerMax_Name, 
			Constants.SpawnerSettings.SpawnTimerMax_Default)
	end

	-- Set up default attributes for each fruit type
	for _, fruitName in ipairs(Constants.Fruit.Types) do
		local settings
		if fruitName == Constants.Fruit.Attack_Name then
			settings = Constants.FruitSpawners.Attack
		elseif fruitName == Constants.Fruit.Defense_Name then
			settings = Constants.FruitSpawners.Defense
		elseif fruitName == Constants.Fruit.Elemental_Name then
			settings = Constants.FruitSpawners.Elemental
		elseif fruitName == Constants.Fruit.Healing_Name then
			settings = Constants.FruitSpawners.Healing
		end

		if settings then
			if spawner:GetAttribute(settings.Probability_Name) == nil then
				spawner:SetAttribute(settings.Probability_Name, Constants.FruitSpawners.DefaultSettings.Probability)
			end
			if spawner:GetAttribute(settings.MinSpawn_Name) == nil then
				spawner:SetAttribute(settings.MinSpawn_Name, Constants.FruitSpawners.DefaultSettings.MinSpawn)
			end
			if spawner:GetAttribute(settings.MaxSpawn_Name) == nil then
				spawner:SetAttribute(settings.MaxSpawn_Name, Constants.FruitSpawners.DefaultSettings.MaxSpawn)
			end
		end
	end
end

function FruitSpawnerManagerModule.HideSpawners()
	debugPrint("Hiding spawners...")
	for spawner in pairs(spawners) do
		if spawner and spawner:IsA("BasePart") then
			spawner.Transparency = 1
		end
	end
	debugPrint("Spawners hidden")
end

function FruitSpawnerManagerModule.OnSpawnerAdded(spawner)
	if spawner:IsA("BasePart") then
		FruitSpawnerManagerModule.EnsureSpawnerSetup(spawner)
		spawners[spawner] = true
	end
end

function FruitSpawnerManagerModule.OnSpawnerRemoved(spawner)
	spawners[spawner] = nil
end

--[[ Probability Management ]]--
function FruitSpawnerManagerModule.LoadProbabilities(spawner)
	local fruitProbabilities = {}
	local totalGiven = 0

	-- Determine whether to use spawner's settings or group settings
	local attributeSource = spawner
	local groupSettings = spawner.Parent:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)

	if groupSettings and groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then
		attributeSource = groupSettings
	end

	-- Read probability attributes from the determined source
	for attributeName, probability in pairs(attributeSource:GetAttributes()) do
		if string.find(attributeName, "Probability") then
			local fruitName = string.gsub(attributeName, "Probability", "")
			fruitProbabilities[fruitName] = probability
			totalGiven = totalGiven + probability
		end
	end

	-- Assign any remaining probability to HealingFruit
	if totalGiven < 100 then
		local healingFruitName = Constants.Fruit.Healing_Name
		local currentHealingProb = fruitProbabilities[healingFruitName] or 0
		fruitProbabilities[healingFruitName] = currentHealingProb + (100 - totalGiven)
	end

	return fruitProbabilities
end

function FruitSpawnerManagerModule.SetupRanges(fruitProbabilities)
	local ranges = {}
	local cumulative = 0
	for fruitName, probability in pairs(fruitProbabilities) do
		local rangeStart = cumulative
		cumulative = cumulative + probability
		ranges[fruitName] = {
			name = fruitName,
			rangeStart = rangeStart,
			rangeEnd = cumulative
		}
	end
	return ranges
end

function FruitSpawnerManagerModule.PickFruit(fruitRanges)
	local randomNum = math.random() * 100
	for _, rangeData in pairs(fruitRanges) do
		if randomNum > rangeData.rangeStart and randomNum <= rangeData.rangeEnd then
			return rangeData.name
		end
	end
	return next(fruitRanges).name
end

function FruitSpawnerManagerModule.DetermineSpawnAmount(spawner, fruitName)
	-- Determine whether to use spawner's settings or group settings
	local attributeSource = spawner
	local groupSettings = spawner.Parent:FindFirstChild(Constants.SpawnerSettings.GroupSpawnSettings_Name)

	if groupSettings and groupSettings:GetAttribute(Constants.SpawnerSettings.OverrideSpawners_Name) then
		attributeSource = groupSettings
	end

	-- Get the minimum and maximum spawn values for the fruit
	local minValue, maxValue
	local settings

	if fruitName == Constants.Fruit.Attack_Name then
		settings = Constants.FruitSpawners.Attack
	elseif fruitName == Constants.Fruit.Defense_Name then
		settings = Constants.FruitSpawners.Defense
	elseif fruitName == Constants.Fruit.Elemental_Name then
		settings = Constants.FruitSpawners.Elemental
	elseif fruitName == Constants.Fruit.Healing_Name then
		settings = Constants.FruitSpawners.Healing
	end

	if settings then
		minValue = attributeSource:GetAttribute(settings.MinSpawn_Name)
		maxValue = attributeSource:GetAttribute(settings.MaxSpawn_Name)
	end

	-- Treat 0 or negative values as nil
	minValue = minValue and minValue > 0 and minValue or nil
	maxValue = maxValue and maxValue > 0 and maxValue or nil

	if minValue and not maxValue then
		return minValue
	elseif maxValue and not minValue then
		return math.random(1, maxValue)
	elseif minValue and maxValue then
		if maxValue < minValue then
			return minValue
		else
			return math.random(minValue, maxValue)
		end
	else
		return 1
	end
end

function FruitSpawnerManagerModule.FruitExistsAtSpawner(spawner)
	for _, obj in ipairs(workspace:GetChildren()) do
		if (obj:IsA("BasePart") or obj:IsA("Model")) and
			obj:GetAttribute("SpawnerId") == spawner:GetFullName() then
			return true
		end
	end
	return false
end

function FruitSpawnerManagerModule.GetSpawners()
	return spawners
end

-- Initialize module
local function Initialize()
	debugPrint("Initializing spawner manager...")
	-- Set up existing spawners
	for _, spawner in ipairs(CollectionService:GetTagged("FruitSpawner")) do
		FruitSpawnerManagerModule.OnSpawnerAdded(spawner)
	end

	-- Listen for spawner additions and removals
	CollectionService:GetInstanceAddedSignal("FruitSpawner"):Connect(FruitSpawnerManagerModule.OnSpawnerAdded)
	CollectionService:GetInstanceRemovedSignal("FruitSpawner"):Connect(FruitSpawnerManagerModule.OnSpawnerRemoved)

	debugPrint("Spawner manager initialized")
end

Initialize()

return FruitSpawnerManagerModule
