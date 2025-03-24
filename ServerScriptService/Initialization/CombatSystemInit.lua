-- /ServerScriptService/Initialization/CombatSystemInit
-- 03/22/25 12:50:06

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize all required modules
local function InitializeCombatSystem()
	print("Initializing VirtualDie Combat System...")

	-- Create the modules folder if it doesn't exist
	local combatModulesFolder = ServerScriptService:FindFirstChild("Modules")
	if not combatModulesFolder then
		combatModulesFolder = Instance.new("Folder")
		combatModulesFolder.Name = "Modules"
		combatModulesFolder.Parent = ServerScriptService
	end

	local combatFolder = combatModulesFolder:FindFirstChild("Combat")
	if not combatFolder then
		combatFolder = Instance.new("Folder")
		combatFolder.Name = "Combat"
		combatFolder.Parent = combatModulesFolder
	end

	-- Check for required modules in ReplicatedStorage
	local replicatedModulesFolder = ReplicatedStorage:FindFirstChild("Modules")
	if not replicatedModulesFolder then
		replicatedModulesFolder = Instance.new("Folder")
		replicatedModulesFolder.Name = "Modules"
		replicatedModulesFolder.Parent = ReplicatedStorage
	end

	local replicatedCombatFolder = replicatedModulesFolder:FindFirstChild("Combat")
	if not replicatedCombatFolder then
		replicatedCombatFolder = Instance.new("Folder")
		replicatedCombatFolder.Name = "Combat"
		replicatedCombatFolder.Parent = replicatedModulesFolder
	end

	-- Ensure the CombatRegistry is loaded first
	local CombatRegistry = require(ReplicatedStorage.Modules.Combat.CombatRegistry)

	-- Create the BindableEvent for CombatEndedSignal
	CombatRegistry.CombatEndedSignal = Instance.new("BindableEvent")

	-- Ensure we have BindableEvents for combat phases
	local CombatManager = require(ServerScriptService.Modules.Combat.CombatManager)
	CombatManager.SetupEvents()

	-- Require the CombatServerHandler to set up events (after CombatEndedSignal is created)
	local CombatServerHandler = require(ServerScriptService.Modules.Combat.CombatServerHandler)

	-- Make sure the combat events are initialized
	local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents")
	if not combatEvents then
		combatEvents = Instance.new("Folder")
		combatEvents.Name = "CombatEvents"
		combatEvents.Parent = ReplicatedStorage

		-- Create standard events
		local startCombatEvent = Instance.new("RemoteEvent")
		startCombatEvent.Name = "StartCombat"
		startCombatEvent.Parent = combatEvents

		local endCombatEvent = Instance.new("RemoteEvent")
		endCombatEvent.Name = "EndCombat"
		endCombatEvent.Parent = combatEvents
	end

	print("VirtualDie Combat System initialized successfully!")
end

-- Run initialization
InitializeCombatSystem()
