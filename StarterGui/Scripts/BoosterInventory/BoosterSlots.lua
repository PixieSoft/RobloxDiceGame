-- /StarterGui/Scripts/BoosterInventory/BoosterSlots.lua
-- LocalScript that initializes and manages the booster inventory UI

local debugSystem = "BoosterInventory" -- Debug system identifier

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import Utility for logging
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Get the player
local player = Players.LocalPlayer

-- Wait for the player GUI to load
local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu", 10)

if not Menu then
	Utility.Log(debugSystem, "warn", "Menu GUI not found after 10 seconds")
	return
end

-- Create or get the BoosterEvents folder in ReplicatedStorage
local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
if not boosterEvents then
	boosterEvents = Instance.new("Folder")
	boosterEvents.Name = "BoosterEvents"
	boosterEvents.Parent = ReplicatedStorage

	-- Create standard booster events
	local events = {
		"BoosterActivated",
		"BoosterDeactivated",
		"UseBooster",
		"BoosterActionFailed"
	}

	for _, eventName in ipairs(events) do
		if not boosterEvents:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = boosterEvents
		endwwwwwwwwwww
	end
end

-- Get the BoosterInventory module
local BoosterInventory
local success, result = pcall(function()
	return require(ReplicatedStorage.Modules.Core.BoosterInventory)
end)

if not success then
	Utility.Log(debugSystem, "warn", "Failed to load BoosterInventory module: " .. tostring(result))
	return
end
BoosterInventory = result

-- Function to display a notification message
local function showNotification(message, color, duration)
	duration = duration or 3 -- Default duration in seconds
	color = color or Color3.fromRGB(255, 255, 255) -- Default color is white

	-- Look for an existing notification system
	local notificationUI = playerGui:FindFirstChild("NotificationUI")

	-- If notification UI doesn't exist, create a simple one
	if not notificationUI then
		notificationUI = Instance.new("ScreenGui")
		notificationUI.Name = "NotificationUI"
		notificationUI.ResetOnSpawn = false
		notificationUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		notificationUI.Parent = playerGui

		-- Create notification container
		local container = Instance.new("Frame")
		container.Name = "NotificationContainer"
		container.Position = UDim2.new(0.5, 0, 0.1, 0)
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Size = UDim2.new(0, 300, 0, 0)
		container.BackgroundTransparency = 1
		container.Parent = notificationUI

		-- Setup auto-layout
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 5)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = container
	end

	-- Get container
	local container = notificationUI:FindFirstChild("NotificationContainer")

	-- Create notification message
	local notification = Instance.new("Frame")
	notification.Name = "Notification_" .. os.time()
	notification.Size = UDim2.new(1, 0, 0, 40)
	notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	notification.BackgroundTransparency = 0.2
	notification.BorderSizePixel = 0
	notification.Parent = container

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = notification

	-- Create message text
	local text = Instance.new("TextLabel")
	text.Name = "Message"
	text.Size = UDim2.new(1, -20, 1, 0)
	text.Position = UDim2.new(0, 10, 0, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = color
	text.TextSize = 14
	text.Font = Enum.Font.GothamBold
	text.Text = message
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Parent = notification

	-- Animate in
	notification.Size = UDim2.new(1, 0, 0, 0)
	notification.BackgroundTransparency = 1
	text.TextTransparency = 1

	-- Tweening animation in
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = game:GetService("TweenService"):Create(notification, tweenInfo, {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0.2
	})
	local textTween = game:GetService("TweenService"):Create(text, tweenInfo, {
		TextTransparency = 0
	})

	tween:Play()
	textTween:Play()

	-- Setup removal after duration
	task.delay(duration, function()
		-- Animate out
		local outTween = game:GetService("TweenService"):Create(notification, tweenInfo, {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		})
		local outTextTween = game:GetService("TweenService"):Create(text, tweenInfo, {
			TextTransparency = 1
		})

		outTween:Play()
		outTextTween:Play()

		outTween.Completed:Connect(function()
			notification:Destroy()
		end)
	end)

	return notification
end

-- Wait for player data to load
local function waitForPlayerData()
	-- Try to get the Stat module
	local Stat = require(ReplicatedStorage.Stat)
	if not Stat.WaitForLoad(player) then
		Utility.Log(debugSystem, "warn", "Player data failed to load")
		return false
	end
	return true
end

-- Initialize the module once data is loaded
local function initializeInventory()
	Utility.Log(debugSystem, "info", "Initializing booster inventory...")

	-- Initialize the module with the Menu UI
	BoosterInventory.Initialize(Menu)

	-- Initial population of the inventory
	BoosterInventory.Refresh()

	-- Setup event connection for Menu visibility changes
	Menu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if Menu.Enabled then
			-- Refresh the inventory when the menu becomes visible
			BoosterInventory.ForceRefresh() -- Use the force refresh method
		end
	end)

	Utility.Log(debugSystem, "info", "Booster inventory initialization complete")
end

-- Listen for booster updates from server
-- Connect to BoosterActivated event
local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
if activatedEvent then
	activatedEvent.OnClientEvent:Connect(function(boosterName, expirationTime)
		-- Refresh the inventory when a booster is activated
		if Menu.Enabled then
			BoosterInventory.Refresh()
		end

		-- Show notification
		local timeLeft = math.floor((expirationTime - os.time()) / 60 + 0.5) -- Round to nearest minute
		local message = boosterName .. " activated for " .. timeLeft .. " minutes"
		showNotification(message, Color3.fromRGB(0, 255, 0), 3)
	end)
end

-- Connect to BoosterDeactivated event
local deactivatedEvent = boosterEvents:FindFirstChild("BoosterDeactivated")
if deactivatedEvent then
	deactivatedEvent.OnClientEvent:Connect(function(boosterName)
		-- Refresh the inventory when a booster is deactivated
		if Menu.Enabled then
			BoosterInventory.Refresh()
		end

		-- Show notification
		local message = boosterName .. " effect has ended"
		showNotification(message, Color3.fromRGB(200, 200, 0), 3)
	end)
end

-- Connect to BoosterActionFailed event
local failureEvent = boosterEvents:FindFirstChild("BoosterActionFailed")
if not failureEvent then
	-- Create the event if it doesn't exist
	failureEvent = Instance.new("RemoteEvent")
	failureEvent.Name = "BoosterActionFailed"
	failureEvent.Parent = boosterEvents
end

-- Listen for booster activation failures
failureEvent.OnClientEvent:Connect(function(boosterName, reason)
	-- Print a message to the output
	Utility.Log(debugSystem, "info", "Booster activation failed: " .. boosterName .. " " .. reason)

	-- Force refresh the inventory immediately to show correct counts
	if Menu.Enabled then
		BoosterInventory.ForceRefresh() -- Force a complete refresh
	end

	-- Show notification to the player about why it failed
	local message = "Cannot use " .. boosterName .. ": " .. reason
	showNotification(message, Color3.fromRGB(255, 100, 100), 3)
end)

-- Make sure player data is loaded before initializing
if not waitForPlayerData() then
	Utility.Log(debugSystem, "info", "Waiting for player data to load...")

	-- Set up a retry system
	local attempts = 0
	local maxAttempts = 5

	local retryConnection
	retryConnection = RunService.Heartbeat:Connect(function()
		attempts = attempts + 1
		if waitForPlayerData() then
			retryConnection:Disconnect()
			initializeInventory()
		elseif attempts >= maxAttempts then
			Utility.Log(debugSystem, "warn", "Failed to load player data after " .. maxAttempts .. " attempts")
			retryConnection:Disconnect()
		end
		task.wait(1) -- Wait 1 second between attempts
	end)
else
	-- Player data is already loaded, initialize immediately
	initializeInventory()
end

-- Player events for leaderstats/booster changes
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		child.ChildAdded:Connect(function(statsChild)
			if statsChild.Name == "Boosters" then
				-- Connect to changes in the Boosters folder
				statsChild.ChildAdded:Connect(function()
					if Menu.Enabled then
						BoosterInventory.Refresh()
					end
				end)

				statsChild.ChildRemoved:Connect(function()
					if Menu.Enabled then
						BoosterInventory.Refresh()
					end
				end)

				for _, booster in ipairs(statsChild:GetChildren()) do
					booster.Changed:Connect(function()
						if Menu.Enabled then
							BoosterInventory.Refresh()
						end
					end)
				end
			end
		end)
	end
end)

-- Setup active booster monitoring for UI updates
local function updateActiveTimers()
	-- Find all active boosters in leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local boostersFolder = leaderstats:FindFirstChild("Boosters")
	if not boostersFolder then return end

	-- Look for active boosters (ones ending with _Active)
	for _, child in ipairs(boostersFolder:GetChildren()) do
		if child.Name:match("_Active$") and child:IsA("NumberValue") and child.Value > 0 then
			local boosterName = child.Name:gsub("_Active$", "")
			local timeLeft = child.Value

			-- If the menu is open, update the UI to show the timer
			if Menu.Enabled then
				-- This could update a timer display on the booster slot if we create one
				-- For now we'll just keep the UI refreshed
				task.spawn(function()
					-- Only one refresh every 10 seconds to avoid overwhelming the UI
					if os.time() % 10 == 0 then
						BoosterInventory.Refresh()
					end
				end)
			end
		end
	end
end

-- Set up a heartbeat connection to update active booster timers
RunService.Heartbeat:Connect(function()
	task.spawn(updateActiveTimers) -- Run in a separate thread to avoid framerate issues
end)

Utility.Log(debugSystem, "info", "BoosterSlots script loaded successfully")
