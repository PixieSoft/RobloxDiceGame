-- /ReplicatedStorage/Modules/Core/BoosterDefs/Crystals.lua
-- ModuleScript that defines the Crystal booster

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

-- Import modules
local Utility = require(ReplicatedStorage.Modules.Core.Utility)
local Stat = require(ReplicatedStorage.Stat)
local Timers = require(ReplicatedStorage.Modules.Core.Timers)

-- Create a table that we can reference from within its own methods
local CrystalBooster = {}

-- Define properties
CrystalBooster.name = "Crystals"
CrystalBooster.description = "Activate crystal power for 10s per crystal."
CrystalBooster.imageId = "rbxassetid://72049224483385"
CrystalBooster.boosterType = "PlayerBoost" -- Will be mapped to Boosters.BoosterTypes.PLAYER
CrystalBooster.duration = 10 -- 10 seconds per item used
CrystalBooster.stacks = false -- effect does not stack
CrystalBooster.canCancel = true -- can be canceled by player

-- Function to calculate and return effect description
CrystalBooster.calculateEffect = function(spendingAmount)
	if spendingAmount <= 0 then
		return "Select crystals to use"
	end

	local totalDuration = CrystalBooster.duration * spendingAmount -- Self-reference to duration property
	local timeText = Utility.FormatTimeDuration(totalDuration)

	local pluralText = spendingAmount > 1 and "crystals" or "crystal"
	return "Crystal power for " .. timeText .. " using " .. spendingAmount .. " " .. pluralText .. "."
end

-- Helper function to ensure the required stats exist
local function ensureStats(player)
	if not IsServer then return false end

	-- Wait for player data to load
	if not Stat.WaitForLoad(player) then
		warn("Crystal Booster: Failed to wait for player data to load")
		return false
	end

	-- Get or create the Boosters folder
	local playerData = Stat.GetDataFolder(player)
	if not playerData then return false end

	local boostersFolder = playerData:FindFirstChild("Boosters")
	if not boostersFolder then
		-- This should already exist, but create it if not
		boostersFolder = Instance.new("Folder")
		boostersFolder.Name = "Boosters"
		boostersFolder.Parent = playerData
	end

	-- Get or create CrystalsActive stat under Boosters
	local crystalsActiveStat = boostersFolder:FindFirstChild("CrystalsActive")
	if not crystalsActiveStat then
		crystalsActiveStat = Instance.new("BoolValue")
		crystalsActiveStat.Name = "CrystalsActive"
		crystalsActiveStat.Value = false
		crystalsActiveStat.Parent = boostersFolder
		print("Created CrystalsActive stat for " .. player.Name)
	end

	return true
end

-- Function that runs when booster is activated
CrystalBooster.onActivate = function(player, qty)
	-- This function only runs on the server
	if not IsServer then return function() end end

	-- Ensure stats exist
	if not ensureStats(player) then
		warn("Crystal Booster: Failed to ensure stats for " .. player.Name)
		return function() end
	end

	-- Get stat references
	local playerData = Stat.GetDataFolder(player)
	local boostersFolder = playerData:FindFirstChild("Boosters")
	local crystalsActiveStat = boostersFolder:FindFirstChild("CrystalsActive")

	-- Calculate duration
	local totalDuration = qty * CrystalBooster.duration

	-- Set the crystal active status
	crystalsActiveStat.Value = true

	print("Crystal booster activated for " .. player.Name .. ": Active for " .. totalDuration .. " seconds")

	-- Create a timer with callbacks using the Timers module
	local timerName = "CrystalsEffect"

	-- Define callbacks for the timer
	local callbacks = {
		onTick = function(timer)
			-- Update any visual effects or other systems on each tick
			-- Debug output to confirm timer is ticking
			if timer.timeRemaining % 1 < 0.1 then -- Only print on whole seconds approximately
				print("Crystal effect: " .. math.floor(timer.timeRemaining) .. " seconds remaining for " .. player.Name)
			end
		end,

		onComplete = function(timer)
			-- Set crystal active status to false when timer completes
			if crystalsActiveStat then
				crystalsActiveStat.Value = false
			end
			print("Crystal effect expired for " .. player.Name)
		end,

		onPause = function(timer)
			print("Crystal effect paused for " .. player.Name .. " with " .. math.floor(timer.timeRemaining) .. " seconds remaining")
		end,

		onResume = function(timer)
			print("Crystal effect resumed for " .. player.Name .. " with " .. math.floor(timer.timeRemaining) .. " seconds remaining")
		end,

		onCancel = function(timer)
			-- Set crystal active status to false if timer is canceled
			if crystalsActiveStat then
				crystalsActiveStat.Value = false
			end
			print("Crystal effect canceled for " .. player.Name)
		end,

		onHalfway = function(timer)
			print("Crystal effect halfway point reached for " .. player.Name)
		end,

		onLowTime = function(timer)
			print("Crystal effect almost expired for " .. player.Name .. " (Low time warning)")
		end,

		onStart = function(timer)
			print("Crystal effect started for " .. player.Name .. " with duration of " .. timer.duration .. " seconds")
		end,

		-- Set low time threshold to 2 seconds
		lowTimeThreshold = 2
	}

	-- Create the timer
	local timer = Timers.CreateTimer(player, timerName, totalDuration, callbacks)

	if not timer then
		warn("Crystal Booster: Failed to create timer for " .. player.Name)
		return function() end
	end

	-- Return cleanup function that will run when the booster expires or is canceled
	return function()
		-- Cancel the timer if it's still active
		if Timers.TimerExists(player, timerName) then
			Timers.CancelTimer(player, timerName)
		end

		-- Set crystal active status to false
		if crystalsActiveStat then
			crystalsActiveStat.Value = false
		end

		print("Crystal booster cleanup function called for " .. player.Name)
	end
end

return CrystalBooster
