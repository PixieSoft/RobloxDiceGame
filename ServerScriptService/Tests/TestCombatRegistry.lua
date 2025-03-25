-- ServerScriptService/Tests/TestCombatRegistry

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRegistry = require(ReplicatedStorage.Modules.Combat.CombatRegistry)

-- Basic test function
local function TestCombatRegistry()
	-- Test creating a combat
	local testConfig = {
		type = "DUEL",
		participants = {"Die1", "Die2"}  -- Just strings for now
	}

	local combat = CombatRegistry:CreateCombat(testConfig)
	print("Created combat:", combat.id)

	-- Test retrieving the combat
	local retrieved = CombatRegistry:GetCombat(combat.id)
	print("Retrieved same combat:", retrieved.id == combat.id)

	-- Test ending the combat
	local ended = CombatRegistry:EndCombat(combat.id)
	print("Combat ended successfully:", ended)

	-- Verify it's gone
	local afterEnd = CombatRegistry:GetCombat(combat.id)
	print("Combat no longer exists:", afterEnd == nil)
end

TestCombatRegistry()
