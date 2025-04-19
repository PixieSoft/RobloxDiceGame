-- /StarterGui/Scripts/HUD/SizeToggleButton.lua
-- LocalScript that connects to the existing SizeToggle button to allow players to toggle their character size

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stat = require(ReplicatedStorage.Stat)

local Player = Players.LocalPlayer
local Interface = Player:WaitForChild("PlayerGui"):WaitForChild("HUD")
local RightHUD = Interface:WaitForChild("RightHUD")
local SizeToggleButton = RightHUD:WaitForChild("SizeToggle")

-- Shared toggle function for both button and keyboard
local function HandleToggle(button, toggleEvent)
	if not toggleEvent then return end

	-- Visual feedback if button exists
	if button then
		button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		toggleEvent:FireServer("toggle")  -- Use the parameter format
		task.wait(0.5)
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	else
		toggleEvent:FireServer("toggle")  -- Use the parameter format
	end
end

-- Wait for player data to load
if not Stat.WaitForLoad(Player) then return end

-- Get or create the remote event
local toggleEvent = ReplicatedStorage:FindFirstChild("TogglePlayerSize")
if not toggleEvent then
	-- If the event doesn't exist, we'll wait for it (it should be created by the PlayerSize module)
	toggleEvent = ReplicatedStorage:WaitForChild("TogglePlayerSize", 5)

	if not toggleEvent then
		warn("TogglePlayerSize RemoteEvent not found after 5 seconds")
		return
	end
end

-- Set up button behavior with debounce
local debounce = false
SizeToggleButton.MouseButton1Click:Connect(function()
	if debounce then return end
	debounce = true
	HandleToggle(SizeToggleButton, toggleEvent)
	debounce = false
end)

-- Keyboard input handler for the 'C' key shortcut
local keyDebounce = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.C then
		if keyDebounce then return end
		keyDebounce = true
		HandleToggle(SizeToggleButton, toggleEvent)
		keyDebounce = false
	end
end)

-- Hover effects
SizeToggleButton.MouseEnter:Connect(function()
	SizeToggleButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
end)

SizeToggleButton.MouseLeave:Connect(function()
	SizeToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)

print("Size toggle system initialized with existing button")
