-- /ServerScriptService/Modules/Combat/CombatSpecialActions
-- 03/23/25 20:05:20

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatSpecialActions = {}

-- Store combat-specific special actions data
CombatSpecialActions.CombatSpecials = {}

-- Store event connections for special actions (similar to original implementation)
CombatSpecialActions.Listeners = {}

-- Required events - we'll ensure they exist
local function EnsureEventsExist()
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

-- Helper function to get events folder
local function GetCombatEvents()
	local EventsFolder = ReplicatedStorage:WaitForChild("Events")
	return EventsFolder:WaitForChild("Combat")
end

-- Helper function to get or create listeners table for a die
local function GetOrCreateSpecialListeners(die)
	local dieId = die:GetAttribute("Name") or die.Name
	CombatSpecialActions.Listeners[dieId] = CombatSpecialActions.Listeners[dieId] or {}
	return CombatSpecialActions.Listeners[dieId]
end

-- Define special actions for virtual dice
CombatSpecialActions.SpecialActions = {
	-- Healing actions
	Regeneration = function(combat, virtualDie, targetDie)
		local combatId = combat.id
		local dieId = virtualDie:GetAttribute("Name")
		local specialListeners = GetOrCreateSpecialListeners(virtualDie)
		local CombatEvents = GetCombatEvents()

		-- Initialize tracking for this combat and die
		CombatSpecialActions.CombatSpecials[combatId] = CombatSpecialActions.CombatSpecials[combatId] or {}
		CombatSpecialActions.CombatSpecials[combatId][dieId] = CombatSpecialActions.CombatSpecials[combatId][dieId] or {}

		-- Create an event listener for the healing phase
		local HealingPhaseStartEvent = CombatEvents:WaitForChild("OnHealingPhaseStart")
		local RegenerationHealingPhaseStart = HealingPhaseStartEvent.Event:Connect(function()
			local regenValue = CombatSpecialActions.CombatSpecials[combatId] and 
				CombatSpecialActions.CombatSpecials[combatId][dieId] and 
				CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration or 0

			if regenValue > 0 then
				-- Apply healing
				local currentHP = virtualDie.hp
				local maxHP = virtualDie:GetAttribute("MaxHP")
				virtualDie.hp = math.min(maxHP, currentHP + regenValue)

				print("Applied Regeneration: " .. virtualDie:GetAttribute("Name") .. 
					" healed for " .. regenValue)
			end
		end)
		table.insert(specialListeners, RegenerationHealingPhaseStart)

		-- Create a listener for the special phase
		local SpecialPhaseEvent = CombatEvents:WaitForChild("OnSpecialPhase")
		local RegenerationSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local regenOld = CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration or 0
				local regenNew = virtualDie:GetAttribute("Tier") or 1

				-- Store in our tracking structure
				CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration = regenOld + regenNew

				print("Increasing " .. dieId .. "'s regeneration from " .. regenOld .. 
					" to " .. CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration)
			end
		end)
		table.insert(specialListeners, RegenerationSpecialPhase)

		-- Listen for the End of Combat
		local CombatEndEvent = CombatEvents:WaitForChild("OnCombatEnd")
		local RegenerationEndPhase = CombatEndEvent.Event:Connect(function()
			-- Clear regeneration value
			if CombatSpecialActions.CombatSpecials[combatId] and 
				CombatSpecialActions.CombatSpecials[combatId][dieId] then
				print("Clearing " .. dieId .. "'s Regeneration of " .. 
					(CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration or 0))
				CombatSpecialActions.CombatSpecials[combatId][dieId].regeneration = nil
			end
		end)
		table.insert(specialListeners, RegenerationEndPhase)
	end,

	-- Defense actions
	DoubleDefense = function(combat, virtualDie, targetDie)
		local dieId = virtualDie:GetAttribute("Name")
		local specialListeners = GetOrCreateSpecialListeners(virtualDie)
		local CombatEvents = GetCombatEvents()

		-- Create a listener for the defense phase
		local DefensePhaseEndEvent = CombatEvents:WaitForChild("OnDefensePhaseEnd")
		local DoubleDefensePhaseEnd = DefensePhaseEndEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local oldAC = virtualDie.ac
				virtualDie.ac = math.max(oldAC * 2, 1)
				print("Applied DoubleDefense to increase " .. virtualDie:GetAttribute("Name") .. 
					"'s AC from " .. oldAC .. " to " .. virtualDie.ac)
			end
		end)
		table.insert(specialListeners, DoubleDefensePhaseEnd)
	end,

	-- Attack actions
	ShieldBash = function(combat, virtualDie, targetDie)
		local combatId = combat.id
		local dieId = virtualDie:GetAttribute("Name")
		local specialListeners = GetOrCreateSpecialListeners(virtualDie)
		local CombatEvents = GetCombatEvents()

		-- Initialize tracking structure
		CombatSpecialActions.CombatSpecials[combatId] = CombatSpecialActions.CombatSpecials[combatId] or {}
		CombatSpecialActions.CombatSpecials[combatId][dieId] = CombatSpecialActions.CombatSpecials[combatId][dieId] or {}

		-- Declare shared variable
		local shieldBashValue = 0

		-- Create a listener for the defense phase end
		local DefensePhaseEndEvent = CombatEvents:WaitForChild("OnDefensePhaseEnd")
		local ShieldBashDefensePhaseEnd = DefensePhaseEndEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				shieldBashValue = virtualDie.ac + virtualDie:GetAttribute("Tier")

				-- Also store in combat specials for persistence between phases if needed
				CombatSpecialActions.CombatSpecials[combatId][dieId].shieldBashValue = shieldBashValue
			end
		end)
		table.insert(specialListeners, ShieldBashDefensePhaseEnd)

		-- Create a listener for the attack phase start
		local AttackPhaseStartEvent = CombatEvents:WaitForChild("OnAttackPhaseStart")
		local ShieldBashAttackPhaseStart = AttackPhaseStartEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 and shieldBashValue > 0 then
				-- Get CombatManager to apply damage
				local CombatManager = require(script.Parent.CombatManager)
				print(virtualDie:GetAttribute("Name") .. " is shield bashing for " .. 
					shieldBashValue .. " physical damage")
				CombatManager.ApplyPhysicalDamage(virtualDie, targetDie, shieldBashValue)

				-- Clear the value after use
				shieldBashValue = 0
				CombatSpecialActions.CombatSpecials[combatId][dieId].shieldBashValue = 0
			end
		end)
		table.insert(specialListeners, ShieldBashAttackPhaseStart)
	end,

	-- Elemental actions
	Fireball = function(combat, virtualDie, targetDie)
		local combatId = combat.id
		local dieId = virtualDie:GetAttribute("Name")
		local specialListeners = GetOrCreateSpecialListeners(virtualDie)
		local CombatEvents = GetCombatEvents()

		-- Initialize tracking structure
		CombatSpecialActions.CombatSpecials[combatId] = CombatSpecialActions.CombatSpecials[combatId] or {}
		CombatSpecialActions.CombatSpecials[combatId][dieId] = CombatSpecialActions.CombatSpecials[combatId][dieId] or {}

		-- Create a listener for the special phase
		local SpecialPhaseEvent = CombatEvents:WaitForChild("OnSpecialPhase")
		local FireballSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local oldDice = CombatSpecialActions.CombatSpecials[combatId][dieId].fireballDice or 0
				local newDice = oldDice + 1

				-- Store in tracking structure
				CombatSpecialActions.CombatSpecials[combatId][dieId].fireballDice = newDice

				print("Increasing " .. dieId .. "'s fireball damage from " .. 
					oldDice .. "d6 to " .. newDice .. "d6")
			end
		end)
		table.insert(specialListeners, FireballSpecialPhase)

		-- Create a listener for the elemental phase
		local ElementalPhaseStartEvent = CombatEvents:WaitForChild("OnElementalPhaseStart")
		local FireballElementalPhase = ElementalPhaseStartEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local numDice = CombatSpecialActions.CombatSpecials[combatId][dieId].fireballDice or 0

				if numDice > 0 then
					-- Roll damage dice
					local damage = 0
					for i = 1, numDice do
						damage = damage + math.random(1, 6)
					end

					-- Apply damage
					local CombatManager = require(script.Parent.CombatManager)
					print(virtualDie:GetAttribute("Name") .. " is casting Fireball for " .. 
						damage .. " fire damage")
					CombatManager.ApplyElementalDamage(virtualDie, targetDie, damage, "Fire")
				end
			end
		end)
		table.insert(specialListeners, FireballElementalPhase)

		-- Listen for the End of Combat
		local CombatEndEvent = CombatEvents:WaitForChild("OnCombatEnd")
		local FireballEndPhase = CombatEndEvent.Event:Connect(function()
			-- Clear fireball dice
			if CombatSpecialActions.CombatSpecials[combatId] and 
				CombatSpecialActions.CombatSpecials[combatId][dieId] then
				print("Clearing " .. dieId .. "'s Fireball damage of " .. 
					(CombatSpecialActions.CombatSpecials[combatId][dieId].fireballDice or 0) .. "d6")
				CombatSpecialActions.CombatSpecials[combatId][dieId].fireballDice = nil
			end
		end)
		table.insert(specialListeners, FireballEndPhase)
	end,

	Pyrotechnics = function(combat, virtualDie, targetDie)
		local combatId = combat.id
		local dieId = virtualDie:GetAttribute("Name")
		local specialListeners = GetOrCreateSpecialListeners(virtualDie)
		local UtilityModule = require(ReplicatedStorage.ModuleScripts.UtilityModule)
		local CombatEvents = GetCombatEvents()

		-- Initialize tracking structure
		CombatSpecialActions.CombatSpecials[combatId] = CombatSpecialActions.CombatSpecials[combatId] or {}
		CombatSpecialActions.CombatSpecials[combatId][dieId] = CombatSpecialActions.CombatSpecials[combatId][dieId] or {}

		-- Create a listener for the special phase
		local SpecialPhaseEvent = CombatEvents:WaitForChild("OnSpecialPhase")
		local PyrotechnicsSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local oldDice = CombatSpecialActions.CombatSpecials[combatId][dieId].pyrotechnicsDice or 0
				local newDice = oldDice + 1

				-- Store in tracking structure
				CombatSpecialActions.CombatSpecials[combatId][dieId].pyrotechnicsDice = newDice

				print("Increasing " .. dieId .. "'s Pyrotechnics damage from " .. 
					oldDice .. "d6 to " .. newDice .. "d6")
			end
		end)
		table.insert(specialListeners, PyrotechnicsSpecialPhase)

		-- Create a listener for the elemental phase
		local ElementalPhaseStartEvent = CombatEvents:WaitForChild("OnElementalPhaseStart")
		local PyrotechnicsElementalPhase = ElementalPhaseStartEvent.Event:Connect(function()
			if virtualDie:GetAttribute("Roll") == 6 then
				local numDice = CombatSpecialActions.CombatSpecials[combatId][dieId].pyrotechnicsDice or 0

				if numDice > 0 then
					-- Roll damage dice
					local damage = 0
					for i = 1, numDice do
						damage = damage + math.random(1, 6)
					end

					-- Get random element
					local element = UtilityModule.GetRandomElement()

					-- Apply damage
					local CombatManager = require(script.Parent.CombatManager)
					print(virtualDie:GetAttribute("Name") .. " is casting Pyrotechnics for " .. 
						damage .. " " .. element .. " damage")
					CombatManager.ApplyElementalDamage(virtualDie, targetDie, damage, element)
				end
			end
		end)
		table.insert(specialListeners, PyrotechnicsElementalPhase)

		-- Listen for the End of Combat
		local CombatEndEvent = CombatEvents:WaitForChild("OnCombatEnd")
		local PyrotechnicsEndPhase = CombatEndEvent.Event:Connect(function()
			-- Clear pyrotechnics dice
			if CombatSpecialActions.CombatSpecials[combatId] and 
				CombatSpecialActions.CombatSpecials[combatId][dieId] then
				print("Clearing " .. dieId .. "'s Pyrotechnics damage of " .. 
					(CombatSpecialActions.CombatSpecials[combatId][dieId].pyrotechnicsDice or 0) .. "d6")
				CombatSpecialActions.CombatSpecials[combatId][dieId].pyrotechnicsDice = nil
			end
		end)
		table.insert(specialListeners, PyrotechnicsEndPhase)
	end,
}

-- Setup specials for a combat
function CombatSpecialActions.SetupSpecials(combat)
	-- Make sure events exist
	EnsureEventsExist()

	-- Initialize tracking
	local combatId = combat.id
	CombatSpecialActions.CombatSpecials[combatId] = {}

	-- Register player die special
	local playerDie = combat.playerVirtualDie
	local playerSpecial = playerDie:GetAttribute("Special")
	if playerSpecial and CombatSpecialActions.SpecialActions[playerSpecial] then
		print("Setting up " .. playerSpecial .. " for " .. playerDie:GetAttribute("Name") .. 
			" targeting " .. combat.enemyVirtualDie:GetAttribute("Name"))
		combat.playerSpecial = playerSpecial
		CombatSpecialActions.SpecialActions[playerSpecial](combat, playerDie, combat.enemyVirtualDie)
	end

	-- Register enemy die special
	local enemyDie = combat.enemyVirtualDie
	local enemySpecial = enemyDie:GetAttribute("Special")
	if enemySpecial and CombatSpecialActions.SpecialActions[enemySpecial] then
		print("Setting up " .. enemySpecial .. " for " .. enemyDie:GetAttribute("Name") .. 
			" targeting " .. combat.playerVirtualDie:GetAttribute("Name"))
		combat.enemySpecial = enemySpecial
		CombatSpecialActions.SpecialActions[enemySpecial](combat, enemyDie, combat.playerVirtualDie)
	end
end

-- Clean up specials when combat ends
function CombatSpecialActions.CleanupSpecials(combat)
	-- Clean up event connections
	local playerDie = combat.playerVirtualDie
	local enemyDie = combat.enemyVirtualDie

	local playerDieId = playerDie:GetAttribute("Name")
	local enemyDieId = enemyDie:GetAttribute("Name")

	-- Disconnect player die listeners
	if CombatSpecialActions.Listeners[playerDieId] then
		for _, connection in ipairs(CombatSpecialActions.Listeners[playerDieId]) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
		CombatSpecialActions.Listeners[playerDieId] = nil
	end

	-- Disconnect enemy die listeners
	if CombatSpecialActions.Listeners[enemyDieId] then
		for _, connection in ipairs(CombatSpecialActions.Listeners[enemyDieId]) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
		CombatSpecialActions.Listeners[enemyDieId] = nil
	end

	-- Remove combat tracking data
	local combatId = combat.id
	CombatSpecialActions.CombatSpecials[combatId] = nil

	print("Combat " .. combat.id .. " ended, special actions cleaned up")
end

-- Handle combat end event
function CombatSpecialActions.ApplyCombatEnd(combat)
	-- This function is called at the end of combat
	-- The OnCombatEnd event will be fired separately by the CombatManager
	-- Make sure cleanup has been done
	CombatSpecialActions.CleanupSpecials(combat)
end

-- The following functions are no longer needed since we're using real events
-- but we'll keep them as empty functions for compatibility with the CombatManager
function CombatSpecialActions.ApplySpecialPhase(combat) end
function CombatSpecialActions.ApplyHealingPhaseStart(combat) end
function CombatSpecialActions.ApplyHealingPhaseEnd(combat) end
function CombatSpecialActions.ApplyDefensePhaseStart(combat) end
function CombatSpecialActions.ApplyDefensePhaseEnd(combat) end
function CombatSpecialActions.ApplyAttackPhaseStart(combat) end
function CombatSpecialActions.ApplyAttackPhaseEnd(combat) end
function CombatSpecialActions.ApplyElementalPhaseStart(combat) end
function CombatSpecialActions.ApplyElementalPhaseEnd(combat) end

return CombatSpecialActions
