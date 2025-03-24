-- /ReplicatedStorage/Modules/Combat/CombatRegistry
-- 03/22/25 12:48:56

local CombatRegistry = {
	activeInstances = {}, -- Stores all active combat instances
	instanceCounter = 0,  -- For generating unique IDs
	CombatEndedSignal = nil -- Will be set in CombatSystemInit
}

-- Creates and returns a new unique combat ID
function CombatRegistry:GenerateId()
	self.instanceCounter += 1
	return string.format(
		"Combat_%d_%d", 
		os.time(),
		self.instanceCounter
	)
end

-- Basic functions to manage combat instances
function CombatRegistry:CreateCombat(combatConfig)
	local combatId = self:GenerateId()

	-- Store key information about this combat instance
	self.activeInstances[combatId] = {
		id = combatId,
		startTime = os.time(),
		lastActivity = os.time(),
		participants = combatConfig.participants,
		combatType = combatConfig.type
	}

	return self.activeInstances[combatId]
end

function CombatRegistry:GetCombat(combatId)
	return self.activeInstances[combatId]
end

function CombatRegistry:EndCombat(combatId)
	local combat = self.activeInstances[combatId]
	if combat then
		-- Fire the combat ended signal if it exists
		if self.CombatEndedSignal then
			self.CombatEndedSignal:Fire(combatId, combat.result or "Unknown")
		end

		-- Remove from active instances
		self.activeInstances[combatId] = nil
		return true
	end
	return false
end

-- Get all active combats
function CombatRegistry:GetActiveCombats()
	return self.activeInstances
end

-- Get active combats for a player
function CombatRegistry:GetActiveCombatsForPlayer(player)
	local playerCombats = {}

	for combatId, combat in pairs(self.activeInstances) do
		-- Check if this player is involved in the combat
		if combat.playerVirtualDie and combat.playerVirtualDie.realDie and 
			combat.playerVirtualDie.realDie:GetAttribute("Owner") == player.Name then
			playerCombats[combatId] = combat
		end
	end

	return playerCombats
end

return CombatRegistry
