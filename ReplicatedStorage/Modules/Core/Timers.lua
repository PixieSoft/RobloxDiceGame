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

-- Import Stat module for persistence
local Stat = require(ReplicatedStorage.Stat)

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

-- Initialize the timer module
function Timers.Initialize()
	if IsServer then
		-- Create remote events folder if it doesn't exist
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = ReplicatedStorage
		end

		local coreFolder = eventsFolder:FindFirstChild("Core")
		if not coreFolder then
			coreFolder = Instance.new("Folder")
			coreFolder.Name = "Core"
			coreFolder.Parent = eventsFolder
		end

		-- Create update event (server to client)
		updateEvent = coreFolder:FindFirstChild("TimerUpdate")
		if not updateEvent then
			updateEvent = Instance.new("RemoteEvent")
			updateEvent.Name = "TimerUpdate"
			updateEvent.Parent = coreFolder
		end

		-- Create command event (client to server)
		commandEvent = coreFolder:FindFirstChild("TimerCommand")
		if not commandEvent then
			commandEvent = Instance.new("RemoteEvent")
			commandEvent.Name = "TimerCommand"
			commandEvent.Parent = coreFolder
		end

		-- Listen for timer commands from clients
		commandEvent.OnServerEvent:Connect(function(player, command, timerName, ...)
			local fullTimerName = player.UserId .. "_" .. timerName

			if command == "pause" then
				Timers.PauseTimer(player, timerName)
			elseif command == "resume" then
				Timers.ResumeTimer(player, timerName)
			elseif command == "cancel" then
				Timers.CancelTimer(player, timerName)
			end
		end)

		-- Set up player joined/leaving handlers
		Players.PlayerRemoving:Connect(function(player)
			-- Save all active timers for the player
			Timers.SaveAllPlayerTimers(player)
		end)

		Players.PlayerAdded:Connect(function(player)
			-- Load timers when player joins
			Timers.LoadPlayerTimers(player)
		end)
	else
		-- Client initialization
		-- Wait for remote events to be created
		local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
		if not eventsFolder then return false end

		local coreFolder = eventsFolder:WaitForChild("Core", 10)
		if not coreFolder then return false end

		updateEvent = coreFolder:WaitForChild("TimerUpdate", 10)
		commandEvent = coreFolder:WaitForChild("TimerCommand", 10)

		-- Listen for timer updates from the server
		updateEvent.OnClientEvent:Connect(function(timerName, timeRemaining, isPaused, isComplete)
			-- Update local timers based on server data
			local localPlayer = Players.LocalPlayer
			if not localPlayer then return end

			local simpleName = timerName:gsub("^" .. localPlayer.UserId .. "_", "")
			local timer = Timers.GetTimer(localPlayer, simpleName)

			if timer then
				timer.timeRemaining = timeRemaining
				timer.isPaused = isPaused

				if isComplete and not timer.isComplete then
					timer.isComplete = true
					if timer.callbacks.onComplete then
						task.spawn(timer.callbacks.onComplete, timer)
					end
				end
			end
		end)
	end

	-- Start the timer update loop
	Timers.StartUpdateLoop()

	return true
end

-- Create a new timer
function Timers.CreateTimer(player, name, duration, callbacks)
	if type(player) ~= "userdata" or not player:IsA("Player") then
		warn("Timers: Invalid player object provided to CreateTimer")
		return nil
	end

	if type(name) ~= "string" or name == "" then
		warn("Timers: Invalid timer name provided to CreateTimer")
		return nil
	end

	if type(duration) ~= "number" or duration <= 0 then
		warn("Timers: Invalid duration provided to CreateTimer")
		return nil
	end

	callbacks = callbacks or {}

	-- Generate the full timer name with player ID
	local fullTimerName = player.UserId .. "_" .. name

	-- Check if timer already exists
	if Timers.TimerExists(player, name) then
		warn("Timers: Timer with name '" .. name .. "' already exists for player " .. player.Name)
		return Timers.GetTimer(player, name)
	end

	-- Create the timer object
	local timer = setmetatable({
		name = fullTimerName,
		simpleName = name,
		playerId = player.UserId,
		duration = duration,
		timeRemaining = duration,
		startTime = os.time(),
		lastUpdateTime = os.time(),
		isPaused = false,
		isComplete = false,
		isHalfwayReached = false,
		isLowTimeReached = false,
		lowTimeThreshold = callbacks.lowTimeThreshold or (duration * LOW_TIME_THRESHOLD),
		callbacks = {
			onTick = callbacks.onTick,
			onComplete = callbacks.onComplete,
			onPause = callbacks.onPause,
			onResume = callbacks.onResume,
			onCancel = callbacks.onCancel,
			onHalfway = callbacks.onHalfway,
			onLowTime = callbacks.onLowTime,
			onStart = callbacks.onStart
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

	-- Save timer to player data
	if IsServer then
		Timers.SaveTimer(player, name, timer)
	end

	-- We'll fire the onStart callback in the main update loop to ensure consistent ordering

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

-- Get the time remaining for a timer
function Timers.GetTimeRemaining(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer then return 0 end

	return timer.timeRemaining
end

-- Pause a timer
function Timers.PauseTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer or timer.isPaused or timer.isComplete then return false end

	timer.isPaused = true

	-- Save the timer state to player data
	if IsServer then
		Timers.SaveTimer(player, name, timer)
	elseif IsClient then
		-- If we're on the client, send pause command to server
		commandEvent:FireServer("pause", name)
	end

	-- Call the onPause callback if provided
	if timer.callbacks.onPause then
		task.spawn(timer.callbacks.onPause, timer)
	end

	return true
end

-- Resume a timer
function Timers.ResumeTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer or not timer.isPaused or timer.isComplete then return false end

	timer.isPaused = false
	timer.lastUpdateTime = os.time()

	-- Save the timer state to player data
	if IsServer then
		Timers.SaveTimer(player, name, timer)
	elseif IsClient then
		-- If we're on the client, send resume command to server
		commandEvent:FireServer("resume", name)
	end

	-- Call the onResume callback if provided
	if timer.callbacks.onResume then
		task.spawn(timer.callbacks.onResume, timer)
	end

	return true
end

-- Cancel a timer
function Timers.CancelTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer then return false end

	-- Call the onCancel callback if provided
	if timer.callbacks.onCancel then
		task.spawn(timer.callbacks.onCancel, timer)
	end

	-- Remove the timer from the registry
	if timerRegistry[player.UserId] then
		timerRegistry[player.UserId][name] = nil
		activeTimersCount = activeTimersCount - 1

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

-- Complete a timer (called internally when a timer reaches zero)
function Timers.CompleteTimer(player, name)
	local timer = Timers.GetTimer(player, name)
	if not timer or timer.isComplete then return false end

	timer.isComplete = true
	timer.timeRemaining = 0

	-- Call the onComplete callback if provided
	if timer.callbacks.onComplete then
		task.spawn(timer.callbacks.onComplete, timer)
	end

	-- Remove the timer from the registry
	if timerRegistry[player.UserId] then
		timerRegistry[player.UserId][name] = nil
		activeTimersCount = activeTimersCount - 1

		-- Clean up if this was the last timer for the player
		if not next(timerRegistry[player.UserId]) then
			timerRegistry[player.UserId] = nil
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
	if timer.isPaused or timer.isComplete then return false end

	-- Update the timer
	local previousTimeRemaining = timer.timeRemaining
	timer.timeRemaining = math.max(0, timer.timeRemaining - deltaTime)

	-- Check for halfway point
	if not timer.isHalfwayReached and timer.timeRemaining <= timer.duration / 2 then
		timer.isHalfwayReached = true
		if timer.callbacks.onHalfway then
			task.spawn(timer.callbacks.onHalfway, timer)
		end
	end

	-- Check for low time
	if not timer.isLowTimeReached and timer.timeRemaining <= timer.lowTimeThreshold then
		timer.isLowTimeReached = true
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
	if Timers._updateConnection then return end

	local lastUpdateTime = os.time()

	Timers._updateConnection = RunService.Heartbeat:Connect(function()
		-- Skip update if no active timers
		if activeTimersCount <= 0 then return end

		-- Calculate time since last update
		local currentTime = os.time()
		local deltaTime = currentTime - lastUpdateTime

		-- Only update if enough time has passed (at least 1 second)
		if deltaTime < 1 then return end

		lastUpdateTime = currentTime

		-- Update all timers
		for playerId, playerTimers in pairs(timerRegistry) do
			for timerName, timer in pairs(playerTimers) do
				-- Skip updating if timer was just created (allow all callbacks to be set up first)
				if os.time() - timer.startTime < 1 and not timer.initialCallbacksFired then
					-- Fire onStart callback if not already fired
					if timer.callbacks.onStart then
						task.spawn(timer.callbacks.onStart, timer)
					end
					timer.initialCallbacksFired = true
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

						-- Send update to client
						updateEvent:FireClient(
							player, 
							timer.name, 
							timer.timeRemaining, 
							timer.isPaused, 
							timer.isComplete
						)
					end
				end

				-- Remove completed timers from registry
				if isCompleted then
					playerTimers[timerName] = nil
					activeTimersCount = activeTimersCount - 1

					-- If this was the last timer for the player, clean up
					if not next(playerTimers) then
						timerRegistry[playerId] = nil
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
	if not player or not timer then return end

	-- Ensure player data is loaded
	if not Stat.WaitForLoad(player) then
		warn("Timers: Failed to save timer - player data not loaded")
		return false
	end

	-- Get player data folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then
		warn("Timers: Failed to save timer - player data folder not found")
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

	-- Save basic timer properties
	setOrCreateValue("Duration", "NumberValue", timer.duration)
	setOrCreateValue("TimeRemaining", "NumberValue", timer.timeRemaining)
	setOrCreateValue("StartTime", "NumberValue", timer.startTime)
	setOrCreateValue("LastUpdateTime", "NumberValue", os.time())
	setOrCreateValue("IsPaused", "BoolValue", timer.isPaused)
	setOrCreateValue("IsComplete", "BoolValue", timer.isComplete)
	setOrCreateValue("IsHalfwayReached", "BoolValue", timer.isHalfwayReached)
	setOrCreateValue("IsLowTimeReached", "BoolValue", timer.isLowTimeReached)
	setOrCreateValue("LowTimeThreshold", "NumberValue", timer.lowTimeThreshold)

	return true
end

-- Remove timer data from player stats
function Timers.RemoveTimer(player, name)
	if not IsServer then return end
	if not player then return end

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
	if not player or not player.UserId then return end

	local playerTimers = timerRegistry[player.UserId]
	if not playerTimers then return end

	for timerName, timer in pairs(playerTimers) do
		Timers.SaveTimer(player, timerName, timer)
	end
end

-- Load timers for a player (typically when they join)
function Timers.LoadPlayerTimers(player)
	if not IsServer then return end
	if not player then return end

	-- Ensure player data is loaded
	if not Stat.WaitForLoad(player) then return end

	-- Get player data folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then return end

	-- Get Timers folder
	local timersFolder = playerData:FindFirstChild("Timers")
	if not timersFolder then return end

	-- Load all timers
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
			local isPaused = getValue("IsPaused", false)
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

			-- Calculate how long since this timer was last updated
			local lastUpdateTime = getValue("LastUpdateTime", os.time())
			local currentTime = os.time()
			local timeSinceUpdate = currentTime - lastUpdateTime

			-- Adjust time remaining if the timer wasn't paused
			if not isPaused and timeSinceUpdate > 0 then
				timeRemaining = math.max(0, timeRemaining - timeSinceUpdate)

				-- If timer would have completed, clean it up
				if timeRemaining <= 0 then
					Timers.RemoveTimer(player, timerName)
					continue
				end
			end

			-- Create timer in memory
			local timer = setmetatable({
				name = player.UserId .. "_" .. timerName,
				simpleName = timerName,
				playerId = player.UserId,
				duration = duration,
				timeRemaining = timeRemaining,
				startTime = getValue("StartTime", os.time() - (duration - timeRemaining)),
				lastUpdateTime = currentTime,
				isPaused = isPaused,
				isComplete = isComplete,
				isHalfwayReached = isHalfwayReached,
				isLowTimeReached = isLowTimeReached,
				lowTimeThreshold = lowTimeThreshold,
				callbacks = {}
			}, Timer)

			-- Initialize player registry if needed
			if not timerRegistry[player.UserId] then
				timerRegistry[player.UserId] = {}
			end

			-- Add timer to registry
			timerRegistry[player.UserId][timerName] = timer
			activeTimersCount = activeTimersCount + 1

			-- Update the timer data with adjusted values
			Timers.SaveTimer(player, timerName, timer)
		end
	end
end

-- Get information about all timers for a player
function Timers.GetAllTimers(player)
	if not player or not player.UserId then return {} end
	if not timerRegistry[player.UserId] then return {} end

	local result = {}
	for name, timer in pairs(timerRegistry[player.UserId]) do
		result[name] = {
			duration = timer.duration,
			timeRemaining = timer.timeRemaining,
			isPaused = timer.isPaused,
			isComplete = timer.isComplete
		}
	end

	return result
end

-- Get debugging information
function Timers.GetDebugInfo()
	return {
		activeTimersCount = activeTimersCount,
		playerCount = #table.keys(timerRegistry)
	}
end

-- Initialize the module
Timers.Initialize()

return Timers
