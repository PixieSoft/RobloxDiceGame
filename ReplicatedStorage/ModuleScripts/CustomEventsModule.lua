local CustomEventsModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DefaultParent = ReplicatedStorage

local function createBindableEvent(name)
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = DefaultParent
end

-------------------------
-- Combat Events
-------------------------
createBindableEvent("OnHealingPhaseStart")
createBindableEvent("OnHealingPhaseEnd")
createBindableEvent("OnDefensePhaseStart")
createBindableEvent("OnDefensePhaseEnd")
createBindableEvent("OnAttackPhaseStart")
createBindableEvent("OnAttackPhaseEnd")
createBindableEvent("OnElementalPhaseStart")
createBindableEvent("OnElementalPhaseEnd")
createBindableEvent("OnSpecialPhase")
createBindableEvent("OnACDamageTaken")
createBindableEvent("OnCombatEnd")

-------------------------
-- Spawner Events
-------------------------
createBindableEvent("OnFruitSpawn")
createBindableEvent("OnFruitPickup")
createBindableEvent("OnFruitDecay")
createBindableEvent("OnSpawnerActivate")
createBindableEvent("OnSpawnerDeactivate")

return CustomEventsModule
