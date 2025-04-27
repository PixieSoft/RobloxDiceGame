-- /ServerScriptService/AdminTools/TimerDashboard.lua
-- Script that creates a dashboard for monitoring and managing player timers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Timers = require(ReplicatedStorage.Modules.Core.Timers)
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Configuration
local UPDATE_INTERVAL = 3 -- How often to update the dashboard (seconds)

-- Create a simple dashboard UI for a player
local function createDashboardForPlayer(player)
	-- Create dashboard ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TimerDashboard"
	gui.ResetOnSpawn = false

	-- Create background frame
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(0.3, 0, 0.5, 0)
	background.Position = UDim2.new(0, 10, 1, -10 - background.Size.Y.Scale * 1000) -- Position at bottom left
	background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.Parent = gui

	-- Create title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.08, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.SourceSansBold
	title.Text = "Timer Dashboard"
	title.BorderSizePixel = 0
	title.Parent = background

	-- Create scroll frame for timer list
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "TimerList"
	scrollFrame.Size = UDim2.new(1, -10, 0.92, -10)
	scrollFrame.Position = UDim2.new(0, 5, 0.08, 5)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = background

	-- Create refresh button
	local refreshButton = Instance.new("TextButton")
	refreshButton.Name = "RefreshButton"
	refreshButton.Size = UDim2.new(0.2, 0, 0.06, 0)
	refreshButton.Position = UDim2.new(0.78, 0, 0.01, 0)
	refreshButton.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
	refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshButton.TextSize = 14
	refreshButton.Font = Enum.Font.SourceSans
	refreshButton.Text = "Refresh"
	refreshButton.BorderSizePixel = 0
	refreshButton.Parent = background

	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.05, 0)
	closeButton.Position = UDim2.new(0.92, 0, 0, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Text = "X"
	closeButton.BorderSizePixel = 0
	closeButton.Parent = background

	-- Create toggle button (for showing/hiding the dashboard)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 100, 0, 30)
	toggleButton.Position = UDim2.new(0, 10, 1, -45)
	toggleButton.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 14
	toggleButton.Font = Enum.Font.SourceSansBold
	toggleButton.Text = "Timers"
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = gui

	-- Handle close button
	closeButton.MouseButton1Click:Connect(function()
		background.Visible = false
	end)

	-- Handle toggle button
	toggleButton.MouseButton1Click:Connect(function()
		background.Visible = not background.Visible
	end)

	-- Handle refresh button
	refreshButton.MouseButton1Click:Connect(function()
		updateDashboard(scrollFrame)
	end)

	-- Parent the GUI to the player
	gui.Parent = player.PlayerGui

	return scrollFrame
end

-- Update the dashboard with current timer data
local function updateDashboard(scrollFrame)
	-- Clear existing items
	for _, child in ipairs(scrollFrame:GetChildren()) do
		child:Destroy()
	end

	-- Get all timers
	local allTimers = Timers.GetAllPlayersTimers()

	-- Create layout for the list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame

	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = scrollFrame

	-- Add section for each player
	local hasTimers = false

	for userId, playerTimers in pairs(allTimers) do
		-- Skip players with no timers
		if not next(playerTimers) then
			continue
		end

		hasTimers = true

		-- Get player name
		local playerName = "Unknown"
		local player = Players:GetPlayerByUserId(userId)
		if player then
			playerName = player.Name
		end

		-- Create player header
		local playerHeader = Instance.new("Frame")
		playerHeader.Name = "Player_" .. userId
		playerHeader.Size = UDim2.new(1, 0, 0, 30)
		playerHeader.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		playerHeader.BorderSizePixel = 0
		playerHeader.Parent = scrollFrame

		local playerLabel = Instance.new("TextLabel")
		playerLabel.Name = "PlayerName"
		playerLabel.Size = UDim2.new(1, 0, 1, 0)
		playerLabel.BackgroundTransparency = 1
		playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		playerLabel.TextSize = 16
		playerLabel.Font = Enum.Font.SourceSansBold
		playerLabel.TextXAlignment = Enum.TextXAlignment.Left
		playerLabel.TextYAlignment = Enum.TextYAlignment.Center
		playerLabel.Text = "  " .. playerName .. " (ID: " .. userId .. ")"
		playerLabel.Parent = playerHeader

		-- Add timer entries for this player
		for timerName, timerData in pairs(playerTimers) do
			local timerEntry = Instance.new("Frame")
			timerEntry.Name = "Timer_" .. timerName
			timerEntry.Size = UDim2.new(1, 0, 0, 40)
			timerEntry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			timerEntry.BorderSizePixel = 0
			timerEntry.Parent = scrollFrame

			-- Timer name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "TimerName"
			nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			nameLabel.TextSize = 14
			nameLabel.Font = Enum.Font.SourceSans
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Text = timerName
			nameLabel.Parent = timerEntry

			-- Time remaining
			local timeLabel = Instance.new("TextLabel")
			timeLabel.Name = "TimeRemaining"
			timeLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
			timeLabel.Position = UDim2.new(0, 10, 0.5, 0)
			timeLabel.BackgroundTransparency = 1
			timeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
			timeLabel.TextSize = 12
			timeLabel.Font = Enum.Font.SourceSans
			timeLabel.TextXAlignment = Enum.TextXAlignment.Left

			-- Format the time remaining
			local formattedTime = Utility.FormatTimeDuration(timerData.timeRemaining)
			timeLabel.Text = "Remaining: " .. formattedTime
			timeLabel.Parent = timerEntry

			-- Cancel button
			local cancelButton = Instance.new("TextButton")
			cancelButton.Name = "CancelButton"
			cancelButton.Size = UDim2.new(0.2, 0, 0.7, 0)
			cancelButton.Position = UDim2.new(0.78, 0, 0.15, 0)
			cancelButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
			cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			cancelButton.TextSize = 12
			cancelButton.Font = Enum.Font.SourceSans
			cancelButton.Text = "Cancel"
			cancelButton.BorderSizePixel = 0
			cancelButton.Parent = timerEntry

			-- Store the full name in the button's attributes for later use
			if timerData.fullName then
				cancelButton:SetAttribute("FullTimerName", timerData.fullName)
			end

			-- Handle cancel button click
			cancelButton.MouseButton1Click:Connect(function()
				local fullTimerName = cancelButton:GetAttribute("FullTimerName")
				if fullTimerName then
					-- Cancel using the full timer name
					Timers.CancelTimerByFullName(fullTimerName)
				else
					-- Fallback to the old method
					local timerPlayer = Players:GetPlayerByUserId(userId)
					if timerPlayer then
						Timers.CancelTimer(timerPlayer, timerName)
					end
				end
				updateDashboard(scrollFrame)
			end)
		end
	end

	-- Show a message if no timers are active
	if not hasTimers then
		local noTimersLabel = Instance.new("TextLabel")
		noTimersLabel.Name = "NoTimers"
		noTimersLabel.Size = UDim2.new(1, 0, 0, 30)
		noTimersLabel.BackgroundTransparency = 1
		noTimersLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		noTimersLabel.TextSize = 14
		noTimersLabel.Font = Enum.Font.SourceSansItalic
		noTimersLabel.Text = "No active timers"
		noTimersLabel.Parent = scrollFrame
	end
end

-- Start the dashboard update loop
local function startUpdateLoop()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local dashboard = player.PlayerGui:FindFirstChild("TimerDashboard")
			if dashboard then
				local scrollFrame = dashboard.Background.TimerList
				updateDashboard(scrollFrame)
			end
		end
		wait(UPDATE_INTERVAL)
	end
end

-- When a player joins
Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load
	player.CharacterAdded:Wait()
	wait(1)

	-- Create dashboard for player
	local scrollFrame = createDashboardForPlayer(player)
	updateDashboard(scrollFrame)
end)

-- Start the update loop
spawn(startUpdateLoop)
-- /ServerScriptService/AdminTools/TimerDashboard.lua
