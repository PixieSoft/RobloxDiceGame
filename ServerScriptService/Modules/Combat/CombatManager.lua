-- /ServerScriptService/Modules/Combat/CombatManager
-- 03/23/25 19:35:20

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local VirtualDie = require(ReplicatedStorage.Modules.Combat.VirtualDie)
local CombatRegistry = require(ReplicatedStorage.Modules.Combat.CombatRegistry)
local CombatSpecialActions = require(script.Parent.CombatSpecialActions)
local UtilityModule = require(ReplicatedStorage.ModuleScripts.UtilityModule)
local DiceModule = require(ReplicatedStorage.ModuleScripts.DiceModule)

local CombatManager = {}

-- Ensure we have all required events in the proper folder structure
function CombatManager.SetupEvents()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Create the Events folder if it doesn't exist
	local EventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not EventsFolder then
		EventsFolder = Instance.new("Folder")
		EventsFolder.Name = "Events"
		EventsFolder.Parent = ReplicatedStorage
	end

	-- Create the Combat events subfolder
	local CombatFolder = EventsFolder:FindFirstChild("Combat")
	if not CombatFolder then
		CombatFolder = Instance.new("Folder")
		CombatFolder.Name = "Combat"
		CombatFolder.Parent = EventsFolder
	end

	-- Combat phases
	local events = {
		"OnHealingPhaseStart",
		"OnHealingPhaseEnd",
		"OnDefensePhaseStart",
		"OnDefensePhaseEnd",
		"OnAttackPhaseStart",
		"OnAttackPhaseEnd",
		"OnElementalPhaseStart",
		"OnElementalPhaseEnd",
		"OnSpecialPhase",
		"OnCombatEnd"
	}

	for _, eventName in ipairs(events) do
		if not CombatFolder:FindFirstChild(eventName) then
			local event = Instance.new("BindableEvent")
			event.Name = eventName
			event.Parent = CombatFolder
			print("Created combat event: " .. eventName)
		end
	end
end

-- Helper function to determine active phases based on roll value
function CombatManager.DetermineActivePhases(roll)
	local phases = {
		Heal = false,
		Defense = false,
		Attack = false,
		Elemental = false,
		Special = false
	}

	-- Assign flags based on roll value (similar to existing CombatModule)
	if roll == 1 then
		phases.Heal = true
	elseif roll == 2 then
		phases.Defense = true
	elseif roll == 3 then
		phases.Attack = true
	elseif roll == 4 then
		phases.Elemental = true
	elseif roll == 5 then
		phases.Heal = true
		phases.Defense = true
		phases.Attack = true
		phases.Elemental = true
	elseif roll == 6 then
		phases.Special = true
	end

	return phases
end

-- Begin a new combat between two dice
function CombatManager.BeginCombat(playerDie, enemyDie)
	-- Ensure events are set up
	CombatManager.SetupEvents()

	-- Create unique combat ID
	local combatId = CombatRegistry:GenerateId()

	-- Create virtual dice
	local playerVirtualDie = VirtualDie.new(playerDie, combatId)
	local enemyVirtualDie = VirtualDie.new(enemyDie, combatId)

	-- Determine tier based on dice
	local tier = math.max(
		playerVirtualDie:GetAttribute("Tier") or 1,
		enemyVirtualDie:GetAttribute("Tier") or 1
	)

	-- Set initial combat stats based on tier
	local tierStats = DiceModule.CombatStatsByTier[tier]

	-- Initialize both virtual dice with tier-appropriate stats
	playerVirtualDie.hp = tierStats.HP
	playerVirtualDie.maxHP = tierStats.MaxHP
	playerVirtualDie.tempHP = tierStats.TempHP
	playerVirtualDie.ac = tierStats.AC

	enemyVirtualDie.hp = tierStats.HP
	enemyVirtualDie.maxHP = tierStats.MaxHP
	enemyVirtualDie.tempHP = tierStats.TempHP
	enemyVirtualDie.ac = tierStats.AC

	-- Register the combat
	local combat = {
		id = combatId,
		startTime = os.time(),
		playerVirtualDie = playerVirtualDie,
		enemyVirtualDie = enemyVirtualDie,
		currentRound = 0,
		maxRounds = tierStats.Rounds,
		status = "Active",
		tier = tier
	}

	CombatRegistry.activeInstances[combatId] = combat

	-- Setup special abilities
	CombatSpecialActions.SetupSpecials(combat)

	print(" ")
	print("Let's get ready to rumble!")

	-- Start combat process
	CombatManager.ProcessCombatRounds(combatId)

	return combatId
end

-- Process all rounds of combat
function CombatManager.ProcessCombatRounds(combatId)
	local combat = CombatRegistry:GetCombat(combatId)
	if not combat or combat.status ~= "Active" then return end

	-- Combat main loop
	while combat.currentRound < combat.maxRounds do
		combat.currentRound += 1

		print(" ")
		print("Round " .. combat.currentRound .. "...Fight!!!")

		-- Execute a single round
		CombatManager.ExecuteCombatRound(combat)

		-- Check for early termination
		if CombatManager.IsCombatOver(combat) then
			print(" ")
			CombatManager.EndCombat(combatId)
			print(" ")
			break
		end

		-- Wait between rounds
		task.wait(0.5)
	end

	-- End combat if we reached maximum rounds
	if combat.status == "Active" then
		print(" ")
		CombatManager.EndCombat(combatId)
		print(" ")
	end
end

-- Execute a single round of combat
function CombatManager.ExecuteCombatRound(combat)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Roll dice
	local playerRoll = math.random(1, 6)
	local enemyRoll = math.random(1, 6)

	-- Set rolls on virtual dice
	playerDie:SetAttribute("Roll", playerRoll)
	enemyDie:SetAttribute("Roll", enemyRoll)

	print(playerDie:GetAttribute("Name") .. " rolled a " .. playerRoll)
	print(enemyDie:GetAttribute("Name") .. " rolled a " .. enemyRoll)

	-- Determine active phases
	local playerPhases = CombatManager.DetermineActivePhases(playerRoll)
	local enemyPhases = CombatManager.DetermineActivePhases(enemyRoll)

	-- Get reference to the Events folder
	local EventsFolder = ReplicatedStorage:WaitForChild("Events")
	local CombatEvents = EventsFolder:WaitForChild("Combat")

	-- Execute combat phases in order

	-- Special Phase
	local OnSpecialPhase = CombatEvents:WaitForChild("OnSpecialPhase")
	OnSpecialPhase:Fire()
	task.wait(0.01) -- Small delay for event processing

	-- Healing Phase
	local OnHealingPhaseStart = CombatEvents:WaitForChild("OnHealingPhaseStart")
	OnHealingPhaseStart:Fire()
	task.wait(0.01) -- Small delay for event processing
	CombatManager.ExecuteHealingPhase(combat, playerPhases, enemyPhases)
	local OnHealingPhaseEnd = CombatEvents:WaitForChild("OnHealingPhaseEnd")
	OnHealingPhaseEnd:Fire()
	task.wait(0.01) -- Small delay for event processing

	-- Defense Phase
	local OnDefensePhaseStart = CombatEvents:WaitForChild("OnDefensePhaseStart")
	OnDefensePhaseStart:Fire()
	task.wait(0.01) -- Small delay for event processing
	CombatManager.ExecuteDefensePhase(combat, playerPhases, enemyPhases)
	local OnDefensePhaseEnd = CombatEvents:WaitForChild("OnDefensePhaseEnd")
	OnDefensePhaseEnd:Fire()
	task.wait(0.01) -- Small delay for event processing

	-- Attack Phase
	local OnAttackPhaseStart = CombatEvents:WaitForChild("OnAttackPhaseStart")
	OnAttackPhaseStart:Fire()
	task.wait(0.01) -- Small delay for event processing
	CombatManager.ExecuteAttackPhase(combat, playerPhases, enemyPhases)
	local OnAttackPhaseEnd = CombatEvents:WaitForChild("OnAttackPhaseEnd")
	OnAttackPhaseEnd:Fire()
	task.wait(0.01) -- Small delay for event processing

	-- Elemental Phase
	local OnElementalPhaseStart = CombatEvents:WaitForChild("OnElementalPhaseStart")
	OnElementalPhaseStart:Fire()
	task.wait(0.01) -- Small delay for event processing
	CombatManager.ExecuteElementalPhase(combat, playerPhases, enemyPhases)
	local OnElementalPhaseEnd = CombatEvents:WaitForChild("OnElementalPhaseEnd")
	OnElementalPhaseEnd:Fire()
	task.wait(0.01) -- Small delay for event processing
end

-- Special Phase handling
function CombatManager.ExecuteSpecialPhase(combat)
	-- No direct logic needed here since special actions are handled via events
end

-- Healing Phase handling - simplified
function CombatManager.ExecuteHealingPhase(combat, playerPhases, enemyPhases)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Execute healing actions
	if playerPhases.Heal then
		CombatManager.ExecuteHealingActions(playerDie)
	end

	if enemyPhases.Heal then
		CombatManager.ExecuteHealingActions(enemyDie)
	end
end

-- Defense Phase handling - simplified
function CombatManager.ExecuteDefensePhase(combat, playerPhases, enemyPhases)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Execute defense actions
	if playerPhases.Defense then
		CombatManager.ExecuteDefenseActions(playerDie)
	end

	if enemyPhases.Defense then
		CombatManager.ExecuteDefenseActions(enemyDie)
	end
end

-- Attack Phase handling - simplified
function CombatManager.ExecuteAttackPhase(combat, playerPhases, enemyPhases)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Execute attack actions
	if playerPhases.Attack then
		CombatManager.ExecuteAttackActions(playerDie, enemyDie)
	end

	if enemyPhases.Attack then
		CombatManager.ExecuteAttackActions(enemyDie, playerDie)
	end
end

-- Elemental Phase handling - simplified
function CombatManager.ExecuteElementalPhase(combat, playerPhases, enemyPhases)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Execute elemental actions
	if playerPhases.Elemental then
		CombatManager.ExecuteElementalActions(playerDie, enemyDie)
	end

	if enemyPhases.Elemental then
		CombatManager.ExecuteElementalActions(enemyDie, playerDie)
	end
end

-- Handle healing actions for a die
function CombatManager.ExecuteHealingActions(virtualDie)
	-- Get healing value
	local healing = virtualDie:GetAttribute("Healing")
	if healing <= 0 then return end

	-- Apply healing
	local currentHP = virtualDie.hp
	local tempHP = virtualDie.tempHP
	local maxHP = virtualDie:GetAttribute("MaxHP")

	-- Calculate new HP
	local newHP = currentHP + healing

	if newHP > maxHP then
		-- If healing exceeds max HP, calculate excess and add to TempHP
		local excessHealing = newHP - maxHP
		virtualDie.hp = maxHP
		tempHP = tempHP + math.floor(excessHealing / 2)

		-- Ensure TempHP doesn't exceed 50% of max HP
		local maxTempHP = maxHP * 0.5
		if tempHP > maxTempHP then
			tempHP = maxTempHP
		end

		virtualDie.tempHP = tempHP
	else
		-- Otherwise just add healing to current HP
		virtualDie.hp = newHP
	end

	print(virtualDie:GetAttribute("Name") .. " healed " .. healing .. 
		" and has " .. virtualDie.hp .. " HP and " .. virtualDie.tempHP .. " Temp")
end

-- Handle defense actions for a die
function CombatManager.ExecuteDefenseActions(virtualDie)
	-- Get defense value
	local defense = virtualDie:GetAttribute("Defense")
	if defense <= 0 then return end

	-- Add to AC
	local currentAC = virtualDie.ac
	local newAC = currentAC + defense
	virtualDie.ac = newAC

	print(virtualDie:GetAttribute("Name") .. " defended " .. defense .. 
		" and has " .. virtualDie.ac .. " AC")
end

-- Handle attack actions for a die
function CombatManager.ExecuteAttackActions(attacker, defender)
	-- Get attack value
	local damage = attacker:GetAttribute("Attack")
	if damage <= 0 then return end

	-- Apply damage
	CombatManager.ApplyPhysicalDamage(attacker, defender, damage)
end

-- Handle elemental actions for a die
function CombatManager.ExecuteElementalActions(attacker, defender)
	-- Get elemental damage
	local damage = attacker:GetAttribute("Elemental")
	if damage <= 0 then return end

	-- Get element type
	local element = attacker:GetAttribute("AttackElement")

	-- Apply elemental damage
	CombatManager.ApplyElementalDamage(attacker, defender, damage, element)
end

-- Apply physical damage logic
function CombatManager.ApplyPhysicalDamage(attacker, defender, damage)
	-- Record full damage for logs
	local fullDamage = damage

	-- Apply damage to armor
	if damage > 0 and defender.ac > 0 then
		if damage >= defender.ac then
			damage = damage - defender.ac
			defender.ac = 0
		else
			defender.ac = defender.ac - damage
			damage = 0
		end
	end

	-- Apply remaining damage to Temp HP
	if damage > 0 and defender.tempHP > 0 then
		if damage >= defender.tempHP then
			damage = damage - defender.tempHP
			defender.tempHP = 0
		else
			defender.tempHP = defender.tempHP - damage
			damage = 0
		end
	end

	-- Apply remaining damage to HP
	if damage > 0 then
		-- Check for overkill
		if damage >= defender.hp + 100 then
			print("Fucking overkill, bro!!!!!!!")
		end

		-- Apply damage
		defender.hp = math.max(0, defender.hp - damage)
	end

	print(attacker:GetAttribute("Name") .. " dealt " .. fullDamage .. " damage. " .. 
		defender:GetAttribute("Name") .. " took " .. damage .. " and has " .. 
		defender.ac .. " AC, " .. defender.tempHP .. " Temp, " .. defender.hp .. " HP")
end

-- Apply elemental damage logic
function CombatManager.ApplyElementalDamage(attacker, defender, damage, damageElement)
	-- Record full damage for logs
	local fullDamage = damage

	-- Check for resistance
	local resistAmount = defender:GetAttribute("Resistance") or 0
	local resistElement = defender:GetAttribute("ResistElement") or ""

	-- Apply resistance if elements match
	if resistElement == damageElement then
		damage = math.max(0, damage - resistAmount)
	end

	-- Apply damage to Temp HP
	if damage > defender.tempHP then
		damage = damage - defender.tempHP
		defender.tempHP = 0
	else
		defender.tempHP = defender.tempHP - damage
		damage = 0
	end

	-- Apply remaining damage to HP
	if damage > 0 then
		defender.hp = math.max(0, defender.hp - damage)
	end

	print(attacker:GetAttribute("Name") .. " dealt " .. fullDamage .. " " .. damageElement .. 
		" damage. " .. defender:GetAttribute("Name") .. " took " .. damage .. 
		" and has " .. defender.ac .. " AC, " .. defender.tempHP .. " Temp, " .. defender.hp .. " HP")
end

-- Check if combat is over
function CombatManager.IsCombatOver(combat)
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Combat ends if max rounds reached or either die has 0 HP
	return combat.currentRound >= combat.maxRounds or
		playerDie.hp <= 0 or
		enemyDie.hp <= 0
end

function CombatManager.EndCombat(combatId)
	local combat = CombatRegistry:GetCombat(combatId)
	if not combat then return end

	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	-- Get final stats
	local playerName = playerDie:GetAttribute("Name")
	local playerAC = playerDie.ac
	local playerHP = playerDie.hp
	local playerTemp = playerDie.tempHP

	local enemyName = enemyDie:GetAttribute("Name")
	local enemyAC = enemyDie.ac
	local enemyHP = enemyDie.hp
	local enemyTemp = enemyDie.tempHP

	-- Determine outcome
	local message = ""
	local result = ""

	if playerHP == enemyHP then
		message = "Combat ended in a tie"
		result = "Tie"

		-- Track achievement
		if playerHP ~= 0 and playerHP ~= combat.playerVirtualDie:GetAttribute("MaxHP") then
			message = "Combat ended in a very unlikely tie"
		end
	elseif playerHP > 0 and enemyHP <= 0 then
		message = "Combat ended with " .. playerName .. "'s glorious victory over " .. enemyName
		result = "PlayerWin"
	elseif enemyHP > 0 and playerHP <= 0 then
		message = "Combat ended with " .. enemyName .. "'s crushing defeat of " .. playerName
		result = "EnemyWin"
	else
		message = "Combat ended...somehow..."
		result = "Undetermined"
	end

	-- Print combat summary
	message = message .. " after " .. combat.currentRound .. " out of " .. combat.maxRounds .. " rounds"
	print(message)

	-- Print ending stats
	print(playerName .. " has " .. playerAC .. " AC, " .. playerTemp .. " Temp, " .. playerHP .. " HP")
	print(enemyName .. " has " .. enemyAC .. " AC, " .. enemyTemp .. " Temp, " .. enemyHP .. " HP")
	print(" ")

	-- Store result in combat record
	combat.result = result
	combat.status = "Completed"
	combat.endTime = os.time()

	-- Get references to the original dice for cleanup
	local realPlayerDie = playerDie.realDie
	local realEnemyDie = enemyDie.realDie

	-- DIRECT CLEANUP: Clear the combat flags on the real dice
	if realPlayerDie then
		realPlayerDie:SetAttribute("IsInCombat", false)
		realPlayerDie:SetAttribute("LoadedInDiceBox", nil)
	end

	if realEnemyDie then
		realEnemyDie:SetAttribute("IsInCombat", false)
		realEnemyDie:SetAttribute("LoadedInDiceBox", nil)
	end

	-- EMERGENCY CLEANUP: Find dice by name in player inventories as a backup
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		local inventory = player:FindFirstChild("DiceInventory")
		if inventory then
			-- Check for player die
			if realPlayerDie then
				local playerDieInInventory = inventory:FindFirstChild(realPlayerDie.Name)
				if playerDieInInventory then
					playerDieInInventory:SetAttribute("IsInCombat", false)
					playerDieInInventory:SetAttribute("LoadedInDiceBox", nil)
				end
			end

			-- Check for enemy die
			if realEnemyDie then
				local enemyDieInInventory = inventory:FindFirstChild(realEnemyDie.Name)
				if enemyDieInInventory then
					enemyDieInInventory:SetAttribute("IsInCombat", false)
					enemyDieInInventory:SetAttribute("LoadedInDiceBox", nil)
				end
			end
		end
	end

	-- Double-check VirtualDie attributes that might be copied
	if playerDie:GetAttribute("IsInCombat") then
		playerDie:SetAttribute("IsInCombat", false)
	end

	if enemyDie:GetAttribute("IsInCombat") then
		enemyDie:SetAttribute("IsInCombat", false)
	end

	-- Fire combat end events
	local EventsFolder = ReplicatedStorage:WaitForChild("Events")
	local CombatEvents = EventsFolder:WaitForChild("Combat")
	local OnCombatEnd = CombatEvents:WaitForChild("OnCombatEnd")
	OnCombatEnd:Fire()
	task.wait(0.01) -- Small delay for event processing

	-- Fire virtual event for combat end
	CombatSpecialActions.ApplyCombatEnd(combat)

	-- Final verification of cleanup
	if realPlayerDie and realPlayerDie:GetAttribute("IsInCombat") then
		realPlayerDie:SetAttribute("IsInCombat", false)
	end

	if realEnemyDie and realEnemyDie:GetAttribute("IsInCombat") then
		realEnemyDie:SetAttribute("IsInCombat", false)
	end

	-- End combat in registry
	CombatRegistry:EndCombat(combatId)
end

return CombatManager
