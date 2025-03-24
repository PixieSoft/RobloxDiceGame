-- /ServerScriptService/Modules/Combat/CombatServerHandler
-- 03/23/25 15:20:25

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Require modules
local CombatManager = require(script.Parent.CombatManager)
local CombatRegistry = require(ReplicatedStorage.Modules.Combat.CombatRegistry)

-- Get combat events
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") or Instance.new("Folder", ReplicatedStorage)
combatEvents.Name = "CombatEvents"

local startCombatEvent = combatEvents:FindFirstChild("StartCombat") or Instance.new("RemoteEvent", combatEvents)
startCombatEvent.Name = "StartCombat"

local endCombatEvent = combatEvents:FindFirstChild("EndCombat") or Instance.new("RemoteEvent", combatEvents)
endCombatEvent.Name = "EndCombat"

-- Helper function to clean up combat flags
local function CleanupDiceCombatFlags(die)
	if not die then return end

	local success, message = pcall(function()
		die:SetAttribute("IsInCombat", false)
		die:SetAttribute("LoadedInDiceBox", nil)
	end)

	if not success then
		warn("Failed to clean up die: " .. message)
	end
end

-- More thorough cleanup function that tries to find dice in player inventories
local function ThoroughDiceCleanup(diceName)
	-- Try to find the die in all player inventories
	for _, player in ipairs(Players:GetPlayers()) do
		local inventory = player:FindFirstChild("DiceInventory")
		if inventory then
			local die = inventory:FindFirstChild(diceName)
			if die then
				CleanupDiceCombatFlags(die)
				return true
			end
		end
	end

	-- Try to find the die in workspace as a fallback
	local workspaceDie = workspace:FindFirstChild(diceName, true)
	if workspaceDie then
		CleanupDiceCombatFlags(workspaceDie)
		return true
	end

	return false
end

-- Function to validate dice for combat
local function ValidateDice(playerDie, enemyDie)
	-- Check if dice exist
	if not playerDie or not enemyDie then
		return false, "One or both dice are missing"
	end

	-- Store important information for later
	if not playerDie:GetAttribute("OriginalName") then
		playerDie:SetAttribute("OriginalName", playerDie.Name)
	end

	if not enemyDie:GetAttribute("OriginalName") then
		enemyDie:SetAttribute("OriginalName", enemyDie.Name)
	end

	-- Check if dice are already in combat
	if playerDie:GetAttribute("IsInCombat") == true then
		-- Force cleanup and check again, just in case
		CleanupDiceCombatFlags(playerDie)
		ThoroughDiceCleanup(playerDie.Name)

		if playerDie:GetAttribute("IsInCombat") == true then
			return false, "Player die is already in combat"
		end
	end

	if enemyDie:GetAttribute("IsInCombat") == true then
		-- Force cleanup and check again, just in case
		CleanupDiceCombatFlags(enemyDie)
		ThoroughDiceCleanup(enemyDie.Name)

		if enemyDie:GetAttribute("IsInCombat") == true then
			return false, "Enemy die is already in combat"
		end
	end

	-- Additional validation can be added here
	return true, "Dice are valid for combat"
end

-- Handle the StartCombat event from clients
startCombatEvent.OnServerEvent:Connect(function(player, playerDie, enemyDie)
	print("Received combat request from: " .. player.Name)

	-- Validate dice
	local isValid, message = ValidateDice(playerDie, enemyDie)
	if not isValid then
		warn("Combat validation failed: " .. message)
		-- You could send a notification back to the client here
		return
	end

	-- Mark dice as in combat to prevent duplicate combats
	playerDie:SetAttribute("IsInCombat", true)
	enemyDie:SetAttribute("IsInCombat", true)

	print("Starting server-side combat between " .. playerDie.Name .. " and " .. enemyDie.Name)
	local combatId = CombatManager.BeginCombat(playerDie, enemyDie)
end)

-- Handle combat end events
-- Create a BindableEvent for CombatEndedSignal if it doesn't exist
if not CombatRegistry.CombatEndedSignal then
	CombatRegistry.CombatEndedSignal = Instance.new("BindableEvent")
end

-- Cleanup the IsInCombat flag when combat ends
CombatRegistry.CombatEndedSignal.Event:Connect(function(combatId, result)
	local combat = CombatRegistry:GetCombat(combatId)
	if combat then
		-- Get the real dice references
		local playerDie = combat.playerVirtualDie and combat.playerVirtualDie.realDie
		local enemyDie = combat.enemyVirtualDie and combat.enemyVirtualDie.realDie

		-- Clear combat flags on the original dice objects
		CleanupDiceCombatFlags(playerDie)
		CleanupDiceCombatFlags(enemyDie)

		-- Perform more thorough cleanup - find and clear flags on original dice
		if playerDie then
			local playerDieName = playerDie:GetAttribute("OriginalName") or playerDie.Name
			ThoroughDiceCleanup(playerDieName)
		end

		if enemyDie then
			local enemyDieName = enemyDie:GetAttribute("OriginalName") or enemyDie.Name
			ThoroughDiceCleanup(enemyDieName)
		end
	end
end)

print("Combat server handler initialized")

return {
	StartCombat = function(playerDie, enemyDie)
		-- Validate dice
		local isValid, message = ValidateDice(playerDie, enemyDie)
		if not isValid then
			warn("Combat validation failed: " .. message)
			return nil
		end

		-- Mark dice as in combat
		playerDie:SetAttribute("IsInCombat", true)
		enemyDie:SetAttribute("IsInCombat", true)

		-- Start combat
		local combatId = CombatManager.BeginCombat(playerDie, enemyDie)
		return combatId
	end,

	-- Expose cleanup functions for debugging
	CleanupDiceCombatFlags = CleanupDiceCombatFlags,
	ThoroughDiceCleanup = ThoroughDiceCleanup
}
