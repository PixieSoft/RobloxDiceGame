-- /StarterGui/Scripts/BoosterInventory/BoosterSlots.lua
-- LocalScript that initializes and manages the booster inventory UI
-- This script connects to the BoosterInventory module to populate the UI with booster slots

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the player
local player = Players.LocalPlayer

-- Wait for the player GUI to load
local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu", 10)

if not Menu then
	warn("Menu GUI not found after 10 seconds")
	return
end

-- Get the BoosterInventory module
local BoosterInventory
local success, result = pcall(function()
	return require(ReplicatedStorage.Modules.Core.BoosterInventory)
end)

if not success then
	warn("Failed to load BoosterInventory module: " .. tostring(result))
	return
end
BoosterInventory = result

-- Wait for player data to load
local function waitForPlayerData()
	-- Try to get the Stat module
	local Stat = require(ReplicatedStorage.Stat)
	if not Stat.WaitForLoad(player) then
		warn("Player data failed to load")
		return false
	end
	return true
end

-- Initialize the module once data is loaded
local function initializeInventory()
	print("Initializing booster inventory...")

	-- Initialize the module with the Menu UI
	BoosterInventory.Initialize(Menu)

	-- Initial population of the inventory
	BoosterInventory.Refresh()

	-- Setup event connection for Menu visibility changes
	-- Fixed: Use Enabled instead of Visible for ScreenGui instances
	Menu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if Menu.Enabled then
			-- Refresh the inventory when the menu becomes visible
			BoosterInventory.Refresh()
		end
	end)

	print("Booster inventory initialization complete")
end

-- Make sure player data is loaded before initializing
if not waitForPlayerData() then
	print("Waiting for player data to load...")

	-- Set up a retry system
	local attempts = 0
	local maxAttempts = 5

	local retryConnection
	retryConnection = game:GetService("RunService").Heartbeat:Connect(function()
		attempts = attempts + 1
		if waitForPlayerData() then
			retryConnection:Disconnect()
			initializeInventory()
		elseif attempts >= maxAttempts then
			warn("Failed to load player data after " .. maxAttempts .. " attempts")
			retryConnection:Disconnect()
		end
		task.wait(1) -- Wait 1 second between attempts
	end)
else
	-- Player data is already loaded, initialize immediately
	initializeInventory()
end

-- Listen for booster updates from server
local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
if not boosterEvents then
	-- Create the events folder if it doesn't exist
	boosterEvents = Instance.new("Folder")
	boosterEvents.Name = "BoosterEvents"
	boosterEvents.Parent = ReplicatedStorage

	-- Create standard booster events
	local events = {
		"BoosterActivated",
		"BoosterDeactivated",
		"UseBooster"
	}

	for _, eventName in ipairs(events) do
		if not boosterEvents:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = boosterEvents
		end
	end
end

-- Connect to booster update events
local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
if activatedEvent then
	activatedEvent.OnClientEvent:Connect(function(boosterName, expirationTime)
		-- Refresh the inventory when a booster is activated
		-- Fixed: Use Enabled instead of Visible for ScreenGui instances
		if Menu.Enabled then
			BoosterInventory.Refresh()
		end
	end)
end

local deactivatedEvent = boosterEvents:FindFirstChild("BoosterDeactivated")
if deactivatedEvent then
	deactivatedEvent.OnClientEvent:Connect(function(boosterName)
		-- Refresh the inventory when a booster is deactivated
		-- Fixed: Use Enabled instead of Visible for ScreenGui instances
		if Menu.Enabled then
			BoosterInventory.Refresh()
		end
	end)
end

-- Player events for leaderstats/booster changes
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		child.ChildAdded:Connect(function(statsChild)
			if statsChild.Name == "Boosters" then
				-- Connect to changes in the Boosters folder
				statsChild.ChildAdded:Connect(function()
					-- Fixed: Use Enabled instead of Visible for ScreenGui instances
					if Menu.Enabled then
						BoosterInventory.Refresh()
					end
				end)

				statsChild.ChildRemoved:Connect(function()
					-- Fixed: Use Enabled instead of Visible for ScreenGui instances
					if Menu.Enabled then
						BoosterInventory.Refresh()
					end
				end)

				for _, booster in ipairs(statsChild:GetChildren()) do
					booster.Changed:Connect(function()
						-- Fixed: Use Enabled instead of Visible for ScreenGui instances
						if Menu.Enabled then
							BoosterInventory.Refresh()
						end
					end)
				end
			end
		end)
	end
end)

print("BoosterSlots script loaded successfully")
