-- /ReplicatedStorage/Modules/Core/Timers.lua
-- ModuleScript that provides timer functionality for managing timed events, effects, and boosters

local Timers = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Determine if we're on the server or client
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

-- Import modules
local Stat = require(ReplicatedStorage.Stat)
local Utility = require(ReplicatedStorage.Modules.Core.Utility) -- Import Utility for Log

-- Debug settings
local debugSystem = "Timers" -- System name for debug logs

-- Timer data structures
local timerRegistry = {} -- Main registry containing all timer objects by player and name
local activeTimersCount = 0 -- Track how many timers are active for performance

-- Remote events for client-server communication
local remoteFolder
local updateEvent
local commandEvent

-- Constants
local UPDATE_INTERVAL = 0.1 -- How often to update timers (in seconds)
local LOW_TIME_THRESHOLD = 0.1 -- Default low time threshold (10% of total duration)

-- Timer class definition
local Timer = {}
Timer.__index = Timer

-- Helper function to generate a consistent fully qualified timer name
-- @param playerId (number) - The player's UserId
-- @param timerName (string) - The simple timer name
-- @return (string) - The fully qualified timer name
function Timers.GetFullTimerName(playerId, timerName)
	return playerId .. "_" .. timerName
end

-- Helper function to extract player ID and simple name from a fully qualified timer name
-- @param fullTimerName (string) - The fully qualified timer name
-- @return (number, string) - The player ID and simple timer name
function Timers.ParseFullTimerName(fullTimerName)
	local underscoreIndex = string.find(fullTimerName, "_")
	if not underscoreIndex then
		return nil, fullTimerName -- Not a valid full timer name
	end

	local playerIdStr = string.sub(fullTimerName, 1, underscoreIndex - 1)
	local simpleName = string.sub(fullTimerName, underscoreIndex + 1)

	return tonumber(playerIdStr), simpleName
end

-- Initialize the timer module
function Timers.Initialize()
	Utility.Log(debugSystem, "info", "Initializing Timer module")

	if IsServer then
		-- Create remote events folder if it doesn't exist
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = ReplicatedStorage
			Utility.Log(debugSystem, "info", "Created Events folder")
		end

		local coreFolder = eventsFolder:FindFirstChild("Core")
		if not coreFolder then
			coreFolder = Instance.new("Folder")
			coreFolder.Name = "Core"
			coreFolder.Parent = eventsFolder
			Utility.Log(debugSystem, "info", "Created Core folder")
		end

		-- Create update event (server to client)
		updateEvent = coreFolder:FindFirstChild("TimerUpdate")
		if not updateEvent then
			updateEvent = Instance.new("RemoteEvent")
			updateEvent.Name = "TimerUpdate"
			updateEvent.Parent = coreFolder
			Utility.Log(debugSystem, "info", "Created TimerUpdate RemoteEvent")
		end

		-- Create command event (client to server)
		commandEvent = coreFolder:FindFirstChild("TimerCommand")
		if not commandEvent then
			commandEvent = Instance.new("RemoteEvent")
			commandEvent.Name = "TimerCommand"
			commandEvent.Parent = coreFolder
			Utility.Log(debugSystem, "info", "Created TimerCommand RemoteEvent")
		end

		-- Listen for timer commands from clients
		commandEvent.OnServerEvent:Connect(function(player, command, timerName, ...)
			Utility.Log(debugSystem, "info", "Received command: " .. command .. " for timer: " .. timerName .. " from player: " .. player.Name)
			if command == "cancel" then
				Timers.CancelTimer(player, timerName)
			end
		end)

		-- Set up player joined/leaving handlers
		Players.PlayerRemoving:Connect(function(player)
			-- Save all timers for the player when they leave
			-- This preserves exact time remaining for each timer
			Utility.Log(debugSystem, "info", "Player " .. player.Name .. " leaving - saving all timers")
			Timers.SaveAllPlayerTimers(player)
		end)

		Players.PlayerAdded:Connect(function(player)
			-- Load timers when player joins
			-- This will automatically resume them from where they left off
			Utility.Log(debugSystem, "info", "Player " .. player.Name .. " joined - loading timers")
			Timers.LoadPlayerTimers(player)
		end)
	else
		-- Client initialization
		-- Wait for remote events to be created
		Utility.Log(debugSystem, "info", "Initializing client-side timers")
		local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
		if not eventsFolder then 
			Utility.Log(debugSystem, "warn", "Failed to find Events folder")
			return false 
		end

		local coreFolder = eventsFolder:WaitForChild("Core", 10)
		if not coreFolder then 
			Utility.Log(debugSystem, "warn", "Failed to find Core folder")
			return false 
		end

		updateEvent = coreFolder:WaitForChild("TimerUpdate", 10)
		commandEvent = coreFolder:WaitForChild("TimerCommand", 10)

		if not updateEvent or not commandEvent then
			Utility.Log(debugSystem, "warn", "Failed to find timer remote events")
			return false
		end

		-- Listen for timer updates from the server
		updateEvent.OnClientEvent:Connect(function(fullTimerName, timeRemaining, isComplete)
			-- Update local timers based on server data
			local localPlayer = Players.LocalPlayer
			if not localPlayer then return end

			-- Parse the full timer name to get the player ID and simple name
			local timerPlayerId, simpleName = Timers.ParseFullTimerName(fullTimerName)

			-- Only update timers for this client
			if timerPlayerId ~= localPlayer.UserId then return end

			local timer = Timers.GetTimer(localPlayer, simpleName)

			if timer then
				timer.timeRemaining = timeRemaining

				if isComplete and not timer.isComplete then
					timer.isComplete = true
					Utility.Log(debugSystem, "info", "Timer completed: " .. simpleName)
					if timer.callbacks.onComplete then
						task.spawn(timer.callbacks.onComplete, timer)
					end
				end
			end
		end)
	end

	-- Start the timer update loop
	Timers.StartUpdateLoop()
	Utility.Log(debugSystem, "info", "Timer module initialized")

	return true
end

-- Create a new timer
function Timers.CreateTimer(player, name, duration, callbacks)
	if type(player) ~= "userdata" or not player:IsA("Player") then
		Utility.Log(debugSystem, "warn", "Invalid player object provided to CreateTimer")
		return nil
	end

	if type(name) ~= "string" or name == "" then
		Utility.Log(debugSystem, "warn", "Invalid timer name provided to CreateTimer")
		return nil
	end

	if type(duration) ~= "number" or duration <= 0 then
		Utility.Log(debugSystem, "warn", "Invalid duration provided to CreateTimer: " .. tostring(duration))
		return nil
	end

	callbacks = callbacks or {}

	-- Generate the full timer name with player ID
	local fullTimerName = Timers.GetFullTimerName(player.UserId, name)

	-- Check if timer already exists
	if Timers.TimerExists(player, name) then
		Utility.Log(debugSystem, "warn", "Timer with name '" .. name .. "' already exists for player " .. player.Name)
		return Timers.GetTimer(player, name)
	end

	-- Create the timer object
	local timer = setmetatable({
		name = fullTimerName,
		simpleName = name,
		playerId = player.UserId,
		duration = duration,
		timeRemaining = duration,
		isComplete = false,
		isHalfwayReached = false,
		isLowTimeReached = false,
		lowTimeThreshold = callbacks.lowTimeThreshold or (duration * LOW_TIME_THRESHOLD),
		callbacks = {
			onTick = callbacks.onTick,
			onComplete = callbacks.onComplete,
			onCancel = callbacks.onCancel,
			onHalfway = callbacks.onHalfway,
			onLowTime = callbacks.onLowTime,
			onStart = callbacks.onStart,
			onPause = callbacks.onPause,
			onResume = callbacks.onResume
		},
		initialCallbacksFired = false
	}, Timer)

	-- Initialize player registry if needed
	if not timerRegistry[player.UserId] then
		timerRegistry[player.UserId] = {}
	end

	-- Add timer to registry
	timerRegistry[player.UserId][name] = timer
	activeTimersCount = activeTimersCount + 1
	Utility.Log(debugSystem, "info", "Created timer: " .. name .. " for player: " .. player.Name .. 
		" with duration: " .. duration .. "s")

	-- Save timer to player data
	if IsServer then
		Timers.SaveTimer(player, name, timer)
	end

	-- We no longer fire onStart callback immediately
	-- Let the update loop handle this to avoid duplicate firing

	return timer
end

-- Check if a timer exists for a player
function Timers.TimerExists(player, name)
	if not player or not player.UserId then return false end

	return timerRegistry[player.UserId] and timerRegistry[player.UserId][name] ~= nil
end

-- Get a timer object for a player
function Timers.GetTimer(player, name)
	if not player or not player.UserId then return nil end
	if not timerRegistry[player.UserId] then return nil end

	return timerRegistry[player.UserId][name]
end

-- Get a timer object by its full name
function Timers.GetTimerByFullName(fullTimerName)
	local playerId, simpleName = Timers.ParseFullTimerName(fullTimerName)
	if not playerId or not simpleName then return nil end
	if not timerRegistry[playerId] then return nil end

	return timerRegistry[playerId][simpleName]
end

-- Get the time remaining for a timer
function Timers.GetTimeRemaining(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer then return 0 end

	return timer.timeRemaining
end

-- Cancel a timer
function Timers.CancelTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer then 
		Utility.Log(debugSystem, "warn", "Attempted to cancel non-existent timer: " .. name .. " for player: " .. player.Name)
		return false 
	end

	-- Call the onCancel callback if provided
	if timer.callbacks.onCancel then
		task.spawn(timer.callbacks.onCancel, timer)
	end

	-- Remove the timer from the registry
	if timerRegistry[player.UserId] then
		timerRegistry[player.UserId][name] = nil
		activeTimersCount = activeTimersCount - 1
		Utility.Log(debugSystem, "info", "Canceled timer: " .. name .. " for player: " .. player.Name)

		-- Clean up if this was the last timer for the player
		if not next(timerRegistry[player.UserId]) then
			timerRegistry[player.UserId] = nil
		end
	end

	-- Remove the timer from player data
	if IsServer then
		Timers.RemoveTimer(player, name)
	elseif IsClient then
		-- If we're on the client, send cancel command to server
		commandEvent:FireServer("cancel", name)
	end

	return true
end

-- Cancel a timer by its full name
function Timers.CancelTimerByFullName(fullTimerName)
	local playerId, simpleName = Timers.ParseFullTimerName(fullTimerName)
	if not playerId or not simpleName then 
		Utility.Log(debugSystem, "warn", "Invalid full timer name: " .. tostring(fullTimerName))
		return false 
	end

	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		Utility.Log(debugSystem, "warn", "Player with ID " .. playerId .. " not found")
		return false
	end

	return Timers.CancelTimer(player, simpleName)
end

-- Complete a timer (called internally when a timer reaches zero)
function Timers.CompleteTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer or timer.isComplete then return false end

	timer.isComplete = true
	timer.timeRemaining = 0
	Utility.Log(debugSystem, "info", "Completed timer: " .. name .. " for player: " .. player.Name)

	-- Call the onComplete callback if provided
	if timer.callbacks.onComplete then
		task.spawn(timer.callbacks.onComplete, timer)
	end

	-- Remove the timer from the registry
	if timerRegistry[player.UserId] then
		timerRegistry[player.UserId][name] = nil
		activeTimersCount = activeTimersCount - 1
		Utility.Log(debugSystem, "info", "Removed completed timer: " .. name .. " from registry (Total active timers: " .. activeTimersCount .. ")")

		-- Clean up if this was the last timer for the player
		if not next(timerRegistry[player.UserId]) then
			timerRegistry[player.UserId] = nil
			Utility.Log(debugSystem, "info", "Removed empty timer registry for player: " .. player.Name)
		end
	end

	-- Remove the timer from player data
	if IsServer then
		Timers.RemoveTimer(player, name)
	end

	return true
end

-- Helper function for updating a timer
local function updateTimer(timer, deltaTime)
	if timer.isComplete then return false end

	-- Update the timer
	local previousTimeRemaining = timer.timeRemaining
	timer.timeRemaining = math.max(0, timer.timeRemaining - deltaTime)

	-- Check for halfway point
	if not timer.isHalfwayReached and timer.timeRemaining <= timer.duration / 2 then
		timer.isHalfwayReached = true
		Utility.Log(debugSystem, "info", "Timer " .. timer.simpleName .. " reached halfway point")
		if timer.callbacks.onHalfway then
			task.spawn(timer.callbacks.onHalfway, timer)
		end
	end

	-- Check for low time
	if not timer.isLowTimeReached and timer.timeRemaining <= timer.lowTimeThreshold then
		timer.isLowTimeReached = true
		Utility.Log(debugSystem, "info", "Timer " .. timer.simpleName .. " reached low time threshold")
		if timer.callbacks.onLowTime then
			task.spawn(timer.callbacks.onLowTime, timer)
		end
	end

	-- Only call tick if time actually changed (by at least 0.1 second to avoid excessive callbacks)
	if math.abs(previousTimeRemaining - timer.timeRemaining) >= 0.1 and timer.callbacks.onTick then
		task.spawn(timer.callbacks.onTick, timer)
	end

	-- Check for completion
	if timer.timeRemaining <= 0 and not timer.isComplete then
		timer.isComplete = true
		Utility.Log(debugSystem, "info", "Timer " .. timer.simpleName .. " completed")

		-- Call the onComplete callback
		if timer.callbacks.onComplete then
			task.spawn(timer.callbacks.onComplete, timer)
		end

		return true -- Timer completed
	end

	return false -- Timer still active
end

-- Main timer update loop
function Timers.StartUpdateLoop()
	-- Only start the update loop once
	if Timers._updateConnection then 
		Utility.Log(debugSystem, "warn", "Attempted to start update loop when it's already running")
		return 
	end

	-- IMPORTANT: Timer callback execution control flow
	-- 1. When a timer is created, we set initialCallbacksFired = false
	-- 2. We do NOT fire the onStart callback in CreateTimer anymore
	-- 3. The first update cycle will fire onStart and set initialCallbacksFired = true
	-- 4. Subsequent update cycles will skip the onStart firing
	-- This prevents the onStart callback from being executed twice

	local lastUpdateTime = os.time()
	Utility.Log(debugSystem, "info", "Starting timer update loop")

	Timers._updateConnection = RunService.Heartbeat:Connect(function()
		-- Skip update if no active timers
		if activeTimersCount <= 0 then return end

		-- Calculate time since last update
		local currentTime = os.time()
		local deltaTime = currentTime - lastUpdateTime

		-- Only update if enough time has passed
		if deltaTime < 1 then return end

		lastUpdateTime = currentTime

		-- Update all timers
		for playerId, playerTimers in pairs(timerRegistry) do
			for timerName, timer in pairs(playerTimers) do
				-- Check if it's the timer's first update cycle
				if not timer.initialCallbacksFired then
					-- Fire onStart callback - this should only happen once per timer
					if timer.callbacks.onStart then
						Utility.Log(debugSystem, "info", "Firing onStart callback for timer: " .. timer.simpleName)
						task.spawn(timer.callbacks.onStart, timer)
					end
					timer.initialCallbacksFired = true
					-- Skip the rest of the update for this timer's first cycle
					-- to avoid updating it before callbacks are properly set up
					continue
				end

				local isCompleted = updateTimer(timer, deltaTime)

				-- On the server, update clients with timer state
				if IsServer then
					local player = Players:GetPlayerByUserId(playerId)
					if player then
						-- Save timer data if it's not completed
						if not isCompleted then
							Timers.SaveTimer(player, timerName, timer)
						end

						-- Send update to client - using the full timer name for proper identification
						updateEvent:FireClient(
							player, 
							timer.name, -- Using full timer name (e.g. "12345_Crystals")
							timer.timeRemaining, 
							timer.isComplete
						)
					end
				end

				-- Remove completed timers from registry
				if isCompleted then
					playerTimers[timerName] = nil
					activeTimersCount = activeTimersCount - 1
					Utility.Log(debugSystem, "info", "Removed completed timer: " .. timerName .. " (Total active timers: " .. activeTimersCount .. ")")

					-- If this was the last timer for the player, clean up
					if not next(playerTimers) then
						timerRegistry[playerId] = nil
						Utility.Log(debugSystem, "info", "Removed empty timer registry for player ID: " .. playerId)
					end

					-- Remove from player data
					if IsServer then
						local player = Players:GetPlayerByUserId(playerId)
						if player then
							Timers.RemoveTimer(player, timerName)
						end
					end
				end
			end
		end
	end)
end

-- Save timer data to player stats (persistence)
function Timers.SaveTimer(player, name, timer)
	if not IsServer then return end
	if not player or not timer then
		Utility.Log(debugSystem, "warn", "Attempted to save timer with invalid player or timer")
		return false
	end

	-- Ensure player data is loaded
	if not Stat.WaitForLoad(player) then
		Utility.Log(debugSystem, "warn", "Failed to save timer - player data not loaded")
		return false
	end

	-- Get player data folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then
		Utility.Log(debugSystem, "warn", "Failed to save timer - player data folder not found")
		return false
	end

	-- Get or create Timers folder
	local timersFolder = playerData:FindFirstChild("Timers")
	if not timersFolder then
		timersFolder = Instance.new("Folder")
		timersFolder.Name = "Timers"
		timersFolder.Parent = playerData
	end

	-- Create or update timer data
	local timerFolder = timersFolder:FindFirstChild(name)
	if not timerFolder then
		timerFolder = Instance.new("Folder")
		timerFolder.Name = name
		timerFolder.Parent = timersFolder
	end

	-- Set timer properties
	local function setOrCreateValue(valueName, valueType, value)
		local valueObj = timerFolder:FindFirstChild(valueName)
		if not valueObj then
			valueObj = Instance.new(valueType)
			valueObj.Name = valueName
			valueObj.Parent = timerFolder
		end
		valueObj.Value = value
	end

	-- Save basic timer properties - only keep what we need
	setOrCreateValue("Duration", "NumberValue", timer.duration)
	setOrCreateValue("TimeRemaining", "NumberValue", timer.timeRemaining)
	setOrCreateValue("IsComplete", "BoolValue", timer.isComplete)
	setOrCreateValue("IsHalfwayReached", "BoolValue", timer.isHalfwayReached)
	setOrCreateValue("IsLowTimeReached", "BoolValue", timer.isLowTimeReached)
	setOrCreateValue("LowTimeThreshold", "NumberValue", timer.lowTimeThreshold)

	-- No logging for routine saves
	return true
end

-- Remove timer data from player stats
function Timers.RemoveTimer(player, name)
	if not IsServer then return end
	if not player then
		Utility.Log(debugSystem, "warn", "Attempted to remove timer with invalid player")
		return false
	end

	-- Ensure player data is loaded
	if not Stat.WaitForLoad(player) then return false end

	-- Get player data folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then return false end

	-- Get Timers folder
	local timersFolder = playerData:FindFirstChild("Timers")
	if not timersFolder then return false end

	-- Remove timer data if it exists
	local timerFolder = timersFolder:FindFirstChild(name)
	if timerFolder then
		timerFolder:Destroy()
		return true
	end

	return false
end

-- Save all timers for a player (typically when they leave)
function Timers.SaveAllPlayerTimers(player)
	if not IsServer then return end
	if not player or not player.UserId then
		Utility.Log(debugSystem, "warn", "Attempted to save all timers with invalid player")
		return
	end

	local playerTimers = timerRegistry[player.UserId]
	if not playerTimers then
		return
	end

	local timerCount = 0
	for timerName, timer in pairs(playerTimers) do
		Timers.SaveTimer(player, timerName, timer)
		timerCount = timerCount + 1
	end

	if timerCount > 0 then
		Utility.Log(debugSystem, "info", "Saved " .. timerCount .. " timers for player: " .. player.Name)
	end
end

-- Load timers for a player (typically when they join)
function Timers.LoadPlayerTimers(player)
	if not IsServer then return end
	if not player then
		Utility.Log(debugSystem, "warn", "Attempted to load timers with invalid player")
		return
	end

	-- Ensure player data is loaded
	if not Stat.WaitForLoad(player) then
		Utility.Log(debugSystem, "warn", "Failed to load timers - player data not loaded")
		return
	end

	-- Get player data folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then
		Utility.Log(debugSystem, "warn", "Failed to load timers - player data folder not found")
		return
	end

	-- Get Timers folder
	local timersFolder = playerData:FindFirstChild("Timers")
	if not timersFolder then
		-- No timers to load, this is normal for new players
		return
	end

	-- Load all timers
	local loadedCount = 0
	for _, timerFolder in ipairs(timersFolder:GetChildren()) do
		if timerFolder:IsA("Folder") then
			local timerName = timerFolder.Name

			-- Skip if this timer is already in the registry
			if Timers.TimerExists(player, timerName) then continue end

			-- Helper function to get value
			local function getValue(name, default)
				local valueObj = timerFolder:FindFirstChild(name)
				return valueObj and valueObj.Value or default
			end

			-- Get timer properties
			local duration = getValue("Duration", 0)
			local timeRemaining = getValue("TimeRemaining", 0)
			local isComplete = getValue("IsComplete", false)

			-- If timer is already complete or has no time remaining, clean it up
			if isComplete or timeRemaining <= 0 then
				Timers.RemoveTimer(player, timerName)
				continue
			end

			-- Get additional properties
			local isHalfwayReached = getValue("IsHalfwayReached", false)
			local isLowTimeReached = getValue("IsLowTimeReached", false)
			local lowTimeThreshold = getValue("LowTimeThreshold", duration * LOW_TIME_THRESHOLD)

			-- Create timer in memory
			local fullTimerName = Timers.GetFullTimerName(player.UserId, timerName)
			local timer = setmetatable({
				name = fullTimerName,
				simpleName = timerName,
				playerId = player.UserId,
				duration = duration,
				timeRemaining = timeRemaining, -- Use exact time that was saved
				isComplete = isComplete,
				isHalfwayReached = isHalfwayReached,
				isLowTimeReached = isLowTimeReached,
				lowTimeThreshold = lowTimeThreshold,
				callbacks = {},
				initialCallbacksFired = true -- Don't trigger onStart again for loaded timers
			}, Timer)

			-- Initialize player registry if needed
			if not timerRegistry[player.UserId] then
				timerRegistry[player.UserId] = {}
			end

			-- Add timer to registry
			timerRegistry[player.UserId][timerName] = timer
			activeTimersCount = activeTimersCount + 1
			loadedCount = loadedCount + 1

			-- Update the timer data
			Timers.SaveTimer(player, timerName, timer)
		end
	end

	if loadedCount > 0 then
		Utility.Log(debugSystem, "info", "Loaded " .. loadedCount .. " timers for player: " .. player.Name)
	end
end

-- Function to get all active timers for all players
-- @return (table) - Table containing all timers organized by player UserID and timer name
function Timers.GetAllPlayersTimers()
	-- Only allow this function on the server
	if not IsServer then 
		Utility.Log(debugSystem, "warn", "GetAllPlayersTimers can only be called from server code")
		return {} 
	end

	-- Return a deep copy of the timer registry to prevent external modification
	local result = {}
	local playerCount = 0

	for userId, playerTimers in pairs(timerRegistry) do
		result[userId] = {}
		playerCount = playerCount + 1

		for timerName, timer in pairs(playerTimers) do
			-- Include only essential information to avoid exposing internal details
			result[userId][timerName] = {
				duration = timer.duration,
				timeRemaining = timer.timeRemaining,
				isComplete = timer.isComplete,
				playerId = timer.playerId,
				simpleName = timer.simpleName,
				fullName = timer.name,
				-- Include additional timer metadata as needed
				isHalfwayReached = timer.isHalfwayReached,
				isLowTimeReached = timer.isLowTimeReached
			}
		end
	end

	return result
end

-- Get debugging information
function Timers.GetDebugInfo()
	local playerCount = 0
	for _ in pairs(timerRegistry) do
		playerCount = playerCount + 1
	end

	local info = {
		activeTimersCount = activeTimersCount,
		playerCount = playerCount
	}

	Utility.Log(debugSystem, "info", "GetDebugInfo called - " .. info.activeTimersCount .. 
		" active timers across " .. info.playerCount .. " players")

	return info
end

-- Initialize the module
Timers.Initialize()

return Timers
-- /ReplicatedStorage/Modules/Core/Timers.lua
