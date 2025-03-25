local SpecialActionsModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local UtilityModule = require(Modules:WaitForChild("UtilityModule"))

-- Central storage for all special listeners
SpecialActionsModule.Listeners = {}

-- Helper function to get or create listeners table for a die
local function GetOrCreateSpecialListeners(die)
	local dieId = die:GetAttribute("Name") or die.Name
	SpecialActionsModule.Listeners[dieId] = SpecialActionsModule.Listeners[dieId] or {}
	return SpecialActionsModule.Listeners[dieId]
end

-- Define special actions
SpecialActionsModule.SpecialActions = {
	-- Healing actions
	Regeneration = function(die)
		local specialListeners = GetOrCreateSpecialListeners(die)

		-- Create an event listener for the healing phase
		local HealingPhaseStartEvent = ReplicatedStorage:WaitForChild("OnHealingPhaseStart")
		local RegenerationHealingPhaseStart = HealingPhaseStartEvent.Event:Connect(function()
			local regenValue = die:GetAttribute("Regeneration") or 0
			if regenValue > 0 then
				UtilityModule.ApplyHealing(die, regenValue)
			end
		end)
		table.insert(specialListeners, RegenerationHealingPhaseStart)

		-- Create a listener for the special phase
		local SpecialPhaseEvent = ReplicatedStorage:WaitForChild("OnSpecialPhase")
		local RegenerationSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if die:GetAttribute("Roll") == 6 then
				local regenOld = die:GetAttribute("Regeneration") or 0
				local regenNew = die:GetAttribute("Tier") or 1
				die:SetAttribute("Regeneration", regenOld + regenNew)
				print("Increasing " .. die:GetAttribute("Name") .. "'s regeneration from " .. regenOld .. " to " .. die:GetAttribute("Regeneration"))
			end
		end)
		table.insert(specialListeners, RegenerationSpecialPhase)

		-- Listen for the End of Combat
		local CombatEndEvent = ReplicatedStorage:WaitForChild("OnCombatEnd")
		local RegenerationEndPhase = CombatEndEvent.Event:Connect(function()
			--print("Clearing " .. die:GetAttribute("Name") .. "'s Regeneration of " .. (die:GetAttribute("Regeneration") or 0))
			die:SetAttribute("Regeneration", nil)
		end)
		table.insert(specialListeners, RegenerationEndPhase)
	end,

	-- Defense actions
	DoubleDefense = function(die)
		local specialListeners = GetOrCreateSpecialListeners(die)

		-- Create a listener for the defense phase
		local DefensePhaseStartEvent = ReplicatedStorage:WaitForChild("OnDefensePhaseStart")
		local DoubleDefenseDefensePhaseStart = DefensePhaseStartEvent.Event:Connect(function()
			if die:GetAttribute("Roll") == 6 then
				local oldAC = die:GetAttribute("AC") or 0
				local newAC = math.max(oldAC * 2, 1) -- If no oldAC, set newAC = 1
				die:SetAttribute("AC", newAC)
				print("Applied DoubleDefense to increase " .. die:GetAttribute("Name") .. "'s AC from " .. oldAC .. " to " .. die:GetAttribute("AC"))
			end
		end)
		table.insert(specialListeners, DoubleDefenseDefensePhaseStart)
	end,

	-- Attack actions
	ShieldBash = function(attacker, defender)
		local specialListeners = GetOrCreateSpecialListeners(attacker)

		-- Declare shared variables
		local shieldBashValue = 0

		-- Listener to get AC at the end of the Defense phase
		local DefensePhaseEndEvent = ReplicatedStorage:WaitForChild("OnDefensePhaseEnd")
		local ShieldBashDefensePhaseEnd = DefensePhaseEndEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				shieldBashValue = attacker:GetAttribute("AC") or 0
				shieldBashValue = shieldBashValue + attacker:GetAttribute("Tier")
			end
		end)
		table.insert(specialListeners, ShieldBashDefensePhaseEnd)

		-- Listener to apply damage at the start of the Attack phase
		local AttackPhaseStartEvent = ReplicatedStorage:WaitForChild("OnAttackPhaseStart")
		local ShieldBashAttackPhaseStart = AttackPhaseStartEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				if shieldBashValue > 0 then
					-- Apply Shield Bash
					print(attacker:GetAttribute("Name") .. " is shield bashing for " .. shieldBashValue .. " physical damage")
					UtilityModule.ApplyPhysicalDamage(attacker, defender, shieldBashValue)
				end
			end
		end)
		table.insert(specialListeners, ShieldBashAttackPhaseStart)
	end,

	-- Elemental actions
	Fireball = function(attacker, defender)
		local specialListeners = GetOrCreateSpecialListeners(attacker)

		-- Declare shared variables
		local fireballAttribute = "FireballDice"

		-- Listen for the special phase
		local SpecialPhaseEvent = ReplicatedStorage:WaitForChild("OnSpecialPhase")
		local FireballSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				local oldDice = attacker:GetAttribute(fireballAttribute) or 0
				local newDice = oldDice + 1
				attacker:SetAttribute(fireballAttribute, newDice)
				print("Increasing " .. attacker:GetAttribute("Name") .. "'s fireball damage from " .. oldDice .. "d6 to " .. newDice .. "d6")
			end
		end)
		table.insert(specialListeners, FireballSpecialPhase)

		-- Listen for the Elemental phase start
		local ElementalPhaseStartEvent = ReplicatedStorage:WaitForChild("OnElementalPhaseStart")
		local FireballElementalPhaseStart = ElementalPhaseStartEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				-- Apply damage
				local damage = UtilityModule.RollDice(attacker:GetAttribute(fireballAttribute), 6)
				UtilityModule.ApplyElementalDamage(attacker, defender, damage, "Fire")
			end
		end)
		table.insert(specialListeners, FireballElementalPhaseStart)
		
		-- Listen for the End of Combat
		local CombatEndEvent = ReplicatedStorage:WaitForChild("OnCombatEnd")
		local FireballEndPhase = CombatEndEvent.Event:Connect(function()
			--print("Clearing " .. attacker:GetAttribute("Name") .. "'s Fireball damage of " .. (attacker:GetAttribute(fireballAttribute) or 0) .. "d6")
			attacker:SetAttribute(fireballAttribute, nil)
		end)
		table.insert(specialListeners, FireballEndPhase)
	end,

	Pyrotechnics = function(attacker, defender)
		local specialListeners = GetOrCreateSpecialListeners(attacker)

		-- Declare shared variables
		local pyroAttribute = "PyrotechnicsDice"

		-- Listen for the special phase
		local SpecialPhaseEvent = ReplicatedStorage:WaitForChild("OnSpecialPhase")
		local PyrotechnicsSpecialPhase = SpecialPhaseEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				local oldDice = attacker:GetAttribute(pyroAttribute) or 0
				local newDice = oldDice + 1
				attacker:SetAttribute(pyroAttribute, newDice)
				print("Increasing " .. attacker:GetAttribute("Name") .. "'s Pyrotechnics damage from " .. oldDice .. "d6 to " .. newDice .. "d6")
			end
		end)
		table.insert(specialListeners, PyrotechnicsSpecialPhase)

		-- Listen for the Elemental phase start
		local ElementalPhaseStartEvent = ReplicatedStorage:WaitForChild("OnElementalPhaseStart")
		local PyrotechnicsElementalPhaseStart = ElementalPhaseStartEvent.Event:Connect(function()
			if attacker:GetAttribute("Roll") == 6 then
				-- Apply damage
				local damage = UtilityModule.RollDice(attacker:GetAttribute(pyroAttribute), 6)
				UtilityModule.ApplyElementalDamage(attacker, defender, damage, UtilityModule.GetRandomElement())
			end
		end)
		table.insert(specialListeners, PyrotechnicsElementalPhaseStart)

		-- Listen for the End of Combat
		local CombatEndEvent = ReplicatedStorage:WaitForChild("OnCombatEnd")
		local PyrotechnicsEndPhase = CombatEndEvent.Event:Connect(function()
			--print("Clearing " .. attacker:GetAttribute("Name") .. "'s Pyrotechnics damage of " .. (attacker:GetAttribute(pyroAttribute) or 0) .. "d6")
			attacker:SetAttribute(pyroAttribute, nil)
		end)
		table.insert(specialListeners, PyrotechnicsEndPhase)
	end,
}

-------------------------
-- Clean up event listeners for a die
-------------------------
function SpecialActionsModule.CleanupSpecialActionListeners(die)
	local dieId = die:GetAttribute("Name") or die.Name
	local specialListeners = SpecialActionsModule.Listeners[dieId]
	if specialListeners then
		for _, connection in ipairs(specialListeners) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
		SpecialActionsModule.Listeners[dieId] = nil -- Clear the table
	end
end

-------------------------
-- Set up Special Action Handlers
-------------------------
function SpecialActionsModule.SetUpSpecialActions(specialAction, sourceDie, targetDie)
	print("Setting up " .. specialAction .. " for " .. sourceDie:GetAttribute("Name") .. " targeting " .. targetDie:GetAttribute("Name"))
	local action = SpecialActionsModule.SpecialActions[specialAction]
	if action then
		action(sourceDie, targetDie)
	else
		warn("Special Action " .. specialAction .. " not found.")
	end
end

return SpecialActionsModule
