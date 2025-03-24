-- /ReplicatedStorage/Modules/Combat/VirtualDie

local VirtualDie = {}
VirtualDie.__index = VirtualDie

-- Creates a new virtual die based on a real die
function VirtualDie.new(realDie, combatId)
	local self = setmetatable({}, VirtualDie)

	-- Store reference to real die but only for final results
	self.realDie = realDie
	self.combatId = combatId

	-- Copy all attributes from the real die
	self.attributes = {}
	local realAttributes = realDie:GetAttributes()
	for name, value in pairs(realAttributes) do
		self.attributes[name] = value
	end

	-- Initialize combat-specific properties
	self.hp = self.attributes.MaxHP or 100
	self.tempHP = 0
	self.ac = 0
	self.currentRoll = 0

	return self
end

-- Methods for accessing attributes (similar to real dice)
function VirtualDie:GetAttribute(name)
	return self.attributes[name]
end

function VirtualDie:SetAttribute(name, value)
	self.attributes[name] = value
end

return VirtualDie
