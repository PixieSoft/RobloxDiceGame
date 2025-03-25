-- /ReplicatedStorage/ModuleScripts/CombatModule

local CombatModule = {}

-- Include other module scripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local CustomEvents = require(Modules:WaitForChild("CustomEventsModule"))
local SpecialModule = require(Modules:WaitForChild("SpecialActionsModule"))
local DiceModule = require(Modules:WaitForChild("DiceModule"))
local UtilityModule = require(Modules:WaitForChild("UtilityModule"))

-------------------------
-- Elemental Functions
-------------------------
function CombatModule.ExecuteElementalActions(attacker, defender)
	-- Get attacker's stats
	local damage = attacker:GetAttribute("Elemental")
	local element = attacker:GetAttribute("AttackElement")

	-- Apply damage to defender
	UtilityModule.ApplyElementalDamage(attacker, defender, damage, element)
end

-------------------------
-- Attack Functions
-------------------------
function CombatModule.ExecuteAttackActions(attacker, defender)
	-- Get attacker's stats
	local damage = attacker:GetAttribute("Attack")

	-- Apply damage to defender
	UtilityModule.ApplyPhysicalDamage(attacker, defender, damage)
end

-------------------------
-- Defense Functions
-------------------------
function CombatModule.ExecuteDefenseActions(die)
	-- Read the die's current values
	local currentAC = die:GetAttribute("AC") or 0
	local defense = die:GetAttribute("Defense")

	-- Calculate new AC
	local newAC = currentAC + defense

	-- Update the die's AC value
	die:SetAttribute("AC", newAC)

	print(die:GetAttribute("Name") .. " defended " .. defense .. " and has " .. die:GetAttribute("AC") .. " AC")
end

-------------------------
-- Healing Functions
-------------------------
function CombatModule.ExecuteHealingActions(die)
	-- Read the die's current healing value
	local healing = die:GetAttribute("Healing")
	UtilityModule.ApplyHealing(die, healing)
end

-------------------------
-- Reset phase flags
-------------------------
local function ResetPhaseFlags()
	return {
		Heal = false,
		Defense = false,
		Attack = false,
		Elemental = false,
		special = false
	}
end

-------------------------
-- Set phase flags based on a roll
-------------------------
local function SetPhaseFlags(roll)
	-- Clear the phase flags
	local flags = ResetPhaseFlags()

	-- Assign flags based on the roll
	-- Special "phase" is handled by events
	if roll == 1 then
		flags.Heal = true
	elseif roll == 2 then
		flags.Defense = true
	elseif roll == 3 then
		flags.Attack = true
	elseif roll == 4 then
		flags.Elemental = true
	elseif roll == 5 then
		flags.Heal = true
		flags.Defense = true
		flags.Attack = true
		flags.Elemental = true
	end
	return flags
end

-------------------------
-- Execute a round of combat between two dice
-------------------------
function CombatModule.CombatRound(playerDie, enemyDie)
	-- Roll dice and set phase flags
	local playerRoll = math.random(1, 6)
	local playerPhaseFlags = SetPhaseFlags(playerRoll)
	playerDie:SetAttribute("Roll", playerRoll)

	local enemyRoll = math.random(1, 6)
	local enemyPhaseFlags = SetPhaseFlags(enemyRoll)
	enemyDie:SetAttribute("Roll", enemyRoll)

	print(playerDie:GetAttribute("Name") .. " rolled a " .. playerRoll)
	print(enemyDie:GetAttribute("Name") .. " rolled a " .. enemyRoll)

	-------------------------
	-- Special Phase
	--	
	-- This phase uniquely has no regular code to execute and only
	-- fires the phase event because any code that needs to run here
	-- will be added by listeners created by SpecialModule.
	-------------------------
	-- Fire the OnPhase event to trigger any listeners
	local OnSpecialPhase = ReplicatedStorage:WaitForChild("OnSpecialPhase")
	OnSpecialPhase:Fire()
	task.wait(0.01)

	-------------------------
	-- Healing Phase
	-------------------------
	-- Fire the OnPhaseStart event to trigger any listeners
	local OnHealingPhaseStart = ReplicatedStorage:WaitForChild("OnHealingPhaseStart")
	OnHealingPhaseStart:Fire()
	task.wait(0.01)

	-- Execute actions
	if playerPhaseFlags.Heal then CombatModule.ExecuteHealingActions(playerDie) end
	if enemyPhaseFlags.Heal then CombatModule.ExecuteHealingActions(enemyDie) end

	-- Fire the OnPhaseEnd event to trigger any listeners
	local OnHealingPhaseEnd = ReplicatedStorage:WaitForChild("OnHealingPhaseEnd")
	OnHealingPhaseEnd:Fire()
	task.wait(0.01)

	-------------------------
	-- Defense Phase
	-------------------------
	-- Fire the OnPhaseStart event to trigger any listeners
	local OnDefensePhaseStart = ReplicatedStorage:WaitForChild("OnDefensePhaseStart")
	OnDefensePhaseStart:Fire()
	task.wait(0.01)

	-- Execute actions
	if playerPhaseFlags.Defense then CombatModule.ExecuteDefenseActions(playerDie) end
	if enemyPhaseFlags.Defense then CombatModule.ExecuteDefenseActions(enemyDie) end

	-- Fire the OnPhaseEnd event to trigger any listeners
	local OnDefensePhaseEnd = ReplicatedStorage:WaitForChild("OnDefensePhaseEnd")
	OnDefensePhaseEnd:Fire()
	task.wait(0.01)

	-------------------------
	-- Attack Phase
	-------------------------
	-- Fire the OnPhaseStart event to trigger any listeners
	local OnAttackPhaseStart = ReplicatedStorage:WaitForChild("OnAttackPhaseStart")
	OnAttackPhaseStart:Fire()
	task.wait(0.01)

	-- Execute actions
	if playerPhaseFlags.Attack then CombatModule.ExecuteAttackActions(playerDie, enemyDie) end
	if enemyPhaseFlags.Attack then CombatModule.ExecuteAttackActions(enemyDie, playerDie) end

	-- Fire the OnPhaseEnd event to trigger any listeners
	local OnAttackPhaseEnd = ReplicatedStorage:WaitForChild("OnAttackPhaseEnd")
	OnAttackPhaseEnd:Fire()
	task.wait(0.01)

	-------------------------
	-- Elemental Phase
	-------------------------
	-- Fire the OnPhaseStart event to trigger any listeners
	local OnElementalPhaseStart = ReplicatedStorage:WaitForChild("OnElementalPhaseStart")
	OnElementalPhaseStart:Fire()
	task.wait(0.01)

	-- Execute actions
	if playerPhaseFlags.Elemental then CombatModule.ExecuteElementalActions(playerDie, enemyDie) end
	if enemyPhaseFlags.Elemental then CombatModule.ExecuteElementalActions(enemyDie, playerDie) end

	-- Fire the OnPhaseEnd event to trigger any listeners
	local OnElementalPhaseEnd = ReplicatedStorage:WaitForChild("OnElementalPhaseEnd")
	OnElementalPhaseEnd:Fire()
	task.wait(0.01)
end

-------------------------
-- End of Combat
-------------------------
function CombatModule.EndCombat(playerDie, enemyDie, round, finalRound)
	-- Get player values
	local playerName = playerDie:GetAttribute("Name")
	local playerAC = playerDie:GetAttribute("AC")
	local playerHP = playerDie:GetAttribute("HP")
	local playerTemp = playerDie:GetAttribute("TempHP")

	-- Get enemy values
	local enemyName = enemyDie:GetAttribute("Name")
	local enemyAC = enemyDie:GetAttribute("AC")
	local enemyHP = enemyDie:GetAttribute("HP")
	local enemyTemp = enemyDie:GetAttribute("TempHP")
	
	-- Initialize message
	local message = ""
	
	if playerHP == enemyHP then
		message = "Combat ended in a tie"
		
		-- Track achievement
		if playerHP ~= 0 and playerHP ~= 100 then
			message = "Combat ended in a very unlikely tie"
		end
	elseif playerHP > 0 and enemyHP <= 0 then
		message = "Combat ended with " .. playerName .. "'s glorious victory over " .. enemyName
	elseif enemyHP > 0 and playerHP <= 0 then
		message = "Combat ended with " .. enemyName .. "'s crushing defeat of " .. playerName
	else
		message = "Combat ended...somehow..."
	end
	
	-- Print the combat summary
	message = message .. " after " .. round .. " out of " .. finalRound .. " rounds"
	print(message)
	
	-- Print ending stats
	print(playerName .. " has " .. playerAC .. " AC, " .. playerTemp .. " Temp, " .. playerHP .. " HP")
	print(enemyName .. " has " .. enemyAC .. " AC, " .. enemyTemp .. " Temp, " .. enemyHP .. " HP")
	print(" ")
end

-------------------------
-- Begin a new combat
-------------------------
function CombatModule.BeginCombat(playerDie, enemyDie)
	-- Set initial combat values for each die
	local dice = {playerDie, enemyDie}
	local tier = 0

	-- Compare tiers, update tier variable with the highest tier, and set initial stats
	for _, die in ipairs(dice) do
		local dieTier = die:GetAttribute("Tier")
		if dieTier > tier then
			tier = dieTier
		end
		die:SetAttribute("HP", DiceModule.CombatStatsByTier[tier].HP)
		die:SetAttribute("MaxHP", DiceModule.CombatStatsByTier[tier].MaxHP)
		die:SetAttribute("TempHP", DiceModule.CombatStatsByTier[tier].TempHP)
		die:SetAttribute("AC", DiceModule.CombatStatsByTier[tier].AC)
	end

	-- Set number of rounds
	local finalRound = DiceModule.CombatStatsByTier[tier].Rounds 

	-- Start the combat
	print(" ")
	print("Let's get ready to rumble!")

	-- DEBUG: Hard-code Special Actions for testing 
	--playerDie:SetAttribute("Special", "Regeneration")
	--enemyDie:SetAttribute("Special", "Pyrotechnics")

	-- Set up Special Abilities
	SpecialModule.SetUpSpecialActions(playerDie:GetAttribute("Special"), playerDie, enemyDie)
	SpecialModule.SetUpSpecialActions(enemyDie:GetAttribute("Special"), enemyDie, playerDie)

	-------------------------
	-- Combat loop
	-------------------------
	--finalRound = 10 -- Hard coding temporarily, determine from TierScore of dice?
	local message = nil
	for round = 1, finalRound do
		print(" ")
		print("Round " .. round .. "...Fight!!!")
		CombatModule.CombatRound(playerDie, enemyDie)

		-- Check for deaths
		if playerDie:GetAttribute("HP") <= 0 or enemyDie:GetAttribute("HP") <= 0 or round >= finalRound then
			print(" ")
			CombatModule.EndCombat(playerDie, enemyDie, round, finalRound)
			print(" ")
			break
		end		
	end

	-- Fire the OnCombatEnd event to trigger any listeners
	-- Mostly used to remove temporary die modifications
	local OnCombatEnd = ReplicatedStorage:WaitForChild("OnCombatEnd")
	OnCombatEnd:Fire()
	task.wait(0.01)
	
	-- Clean up Special Action listeners
	SpecialModule.CleanupSpecialActionListeners(playerDie)
	SpecialModule.CleanupSpecialActionListeners(enemyDie)
end

return CombatModule
