-- /StarterGui/Scripts/HUD/SizeToggleButton.lua
-- LocalScript that adds a button to toggle player size using the PlayerSize module

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stat = require(ReplicatedStorage.Stat)

local Player = Players.LocalPlayer
local Interface = Player:WaitForChild("PlayerGui"):WaitForChild("Interface")
local HUD = Interface:WaitForChild("HUD")

-- Shared toggle function for both button and keyboard
local function HandleToggle(button, toggleEvent)
	if not toggleEvent then return end

	-- Visual feedback if button exists
	if button then
		button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		toggleEvent:FireServer("toggle")  -- Updated to use the parameter format
		task.wait(0.5)
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	else
		toggleEvent:FireServer("toggle")  -- Updated to use the parameter format
	end
end

local function CreateToggleButton()
	-- Wait for player data to load
	if not Stat.WaitForLoad(Player) then return end

	-- Check if button frame already exists in the HUD
	local existingFrame = HUD:FindFirstChild("SizeToggleFrame")
	if existingFrame then return end

	-- Create main container frame
	local frame = Instance.new("Frame")
	frame.Name = "SizeToggleFrame"
	frame.Size = UDim2.new(0, 150, 0, 50)
	frame.Position = UDim2.new(0.85, 0, 0.85, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = HUD

	-- Create button
	local button = Instance.new("TextButton")
	button.Name = "Main"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = "Toggle Size (C)"
	button.TextColor3 = Color3.fromRGB(0, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 22
	button.Parent = frame

	-- Add visual effects
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0.2, 0)
	UICorner.Parent = button

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Name = "UIStroke"
	UIStroke.Color = Color3.fromRGB(0, 0, 0)
	UIStroke.Thickness = 1
	UIStroke.Parent = button

	-- Set up button behavior with additional safety
	local debounce = false
	local toggleEvent = ReplicatedStorage:WaitForChild("TogglePlayerSize", 5)

	if not toggleEvent then
		warn("TogglePlayerSize RemoteEvent not found after 5 seconds")
		return
	end

	-- Button click handler
	button.MouseButton1Click:Connect(function()
		if debounce then return end
		debounce = true
		HandleToggle(button, toggleEvent)
		debounce = false
	end)

	-- Keyboard input handler
	local keyDebounce = false
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.C then
			if keyDebounce then return end
			keyDebounce = true
			HandleToggle(button, toggleEvent)
			keyDebounce = false
		end
	end)

	-- Hover effects
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

CreateToggleButton()
