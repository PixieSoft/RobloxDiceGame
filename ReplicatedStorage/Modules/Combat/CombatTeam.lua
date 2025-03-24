-- /ReplicatedStorage/Modules/Combat/CombatTeam
-- Manages a team of virtual dice in combat, handling shared resources and team actions

local CombatTeam = {}
CombatTeam.__index = CombatTeam

-------------------------
-- Constructor
-------------------------
function CombatTeam.new(config)
	-- Validate required config
	assert(config.members and #config.members > 0, "CombatTeam requires at least one member")

	local self = setmetatable({}, CombatTeam)

	-- Store team configuration
	self._members = config.members
	self._isSharedPool = config.isSharedPool or false
	self._isBossTeam = config.isBossTeam or false

	-- Initialize shared resource pools if needed
	if self._isSharedPool then
		self:_initializeSharedPools()
	end

	return self
end

-------------------------
-- Private Methods
-------------------------
function CombatTeam:_initializeSharedPools()
	-- For teams of 9 lower-tier dice facing a boss, MaxHP matches the boss tier
	-- e.g. 9 tier-2 dice (100 HP each) vs tier-3 boss (1000 HP) get 1000 MaxHP
	local memberTier = self._members[1]:GetAttribute("Tier")
	local bossLevel = memberTier + 1

	-- Reference the tier values from DiceModule
	local DiceModule = require(game.ReplicatedStorage.ModuleScripts.DiceModule)
	local tierStats = DiceModule.CombatStatsByTier[bossLevel]

	-- Set MaxHP to match the boss tier's HP value
	self._sharedMaxHP = tierStats.HP

	-- Initialize current HP to MaxHP
	self._sharedHP = self._sharedMaxHP

	-- Sum up shared defensive stats from all members
	local totalAC = 0
	local totalTempHP = 0

	for _, member in ipairs(self._members) do
		totalAC = totalAC + member:GetAttribute("AC")
		totalTempHP = totalTempHP + (member:GetAttribute("TempHP") or 0)
	end

	-- Store shared defensive pools
	self._sharedAC = totalAC
	self._sharedTempHP = totalTempHP
end

function CombatTeam:_distributeResults(result)
	-- Update combat records for all team members
	for _, member in ipairs(self._members) do
		local realDie = member.realDie
		if realDie then
			-- Increment appropriate counter based on result
			local recordType = self._isBossTeam and "Boss" or "Regular"
			local counterName = recordType .. result
			local currentCount = realDie:GetAttribute(counterName) or 0
			realDie:SetAttribute(counterName, currentCount + 1)
		end
	end
end

-------------------------
-- Resource Management
-------------------------
function CombatTeam:GetHP()
	if self._isSharedPool then
		return self._sharedHP
	else
		-- For non-shared pools, return first member's HP
		-- (typically only used in 1v1 fights)
		return self._members[1]:GetAttribute("HP")
	end
end

function CombatTeam:GetAC()
	if self._isSharedPool then
		return self._sharedAC
	else
		return self._members[1]:GetAttribute("AC")
	end
end

function CombatTeam:GetTempHP()
	if self._isSharedPool then
		return self._sharedTempHP
	else
		return self._members[1]:GetAttribute("TempHP")
	end
end

function CombatTeam:TakeDamage(damage)
	if self._isSharedPool then
		-- Apply damage to shared resources in order: AC -> TempHP -> HP
		if self._sharedAC > 0 then
			if damage > self._sharedAC then
				damage = damage - self._sharedAC
				self._sharedAC = 0
			else
				self._sharedAC = self._sharedAC - damage
				damage = 0
			end
		end

		if damage > 0 and self._sharedTempHP > 0 then
			if damage > self._sharedTempHP then
				damage = damage - self._sharedTempHP
				self._sharedTempHP = 0
			else
				self._sharedTempHP = self._sharedTempHP - damage
				damage = 0
			end
		end

		if damage > 0 then
			self._sharedHP = math.max(0, self._sharedHP - damage)
		end
	else
		-- For non-shared pools, damage goes to the first member
		-- (typically only used in 1v1 fights)
		local member = self._members[1]
		member:SetAttribute("HP", math.max(0, member:GetAttribute("HP") - damage))
	end
end

function CombatTeam:ApplyHealing(healing)
	if self._isSharedPool then
		-- Apply healing to shared HP pool
		local newHP = self._sharedHP + healing

		-- If healing would exceed max HP, convert excess to temp HP
		if newHP > self._sharedMaxHP then
			local excess = newHP - self._sharedMaxHP
			self._sharedHP = self._sharedMaxHP
			-- Add half of excess as temp HP, up to 50% of max HP
			local maxTempHP = self._sharedMaxHP * 0.5
			self._sharedTempHP = math.min(maxTempHP, self._sharedTempHP + math.floor(excess / 2))
		else
			self._sharedHP = newHP
		end
	else
		-- For non-shared pools, healing goes to the first member
		local member = self._members[1]
		member:SetAttribute("HP", math.min(member:GetAttribute("MaxHP"), member:GetAttribute("HP") + healing))
	end
end

function CombatTeam:AddAC(amount)
	if self._isSharedPool then
		self._sharedAC = self._sharedAC + amount
	else
		local member = self._members[1]
		member:SetAttribute("AC", member:GetAttribute("AC") + amount)
	end
end

-------------------------
-- Team Management
-------------------------
function CombatTeam:GetMembers()
	return self._members
end

function CombatTeam:GetMemberCount()
	return #self._members
end

function CombatTeam:IsDefeated()
	return self:GetHP() <= 0
end

function CombatTeam:RecordResult(result)
	assert(result == "Win" or result == "Loss" or result == "Tie", "Invalid result type")
	self:_distributeResults(result)
end

-------------------------
-- Combat Actions
-------------------------
function CombatTeam:GetMemberActions()
	local actions = {}
	for _, member in ipairs(self._members) do
		-- Each member rolls independently
		local roll = math.random(1, 6)
		member:SetAttribute("Roll", roll)

		-- Store the action for this member
		table.insert(actions, {
			member = member,
			roll = roll
		})
	end
	return actions
end

return CombatTeam
