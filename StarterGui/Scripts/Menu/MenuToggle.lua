-- /StarterGui/Scripts/Menu/MenuToggle.lua
-- LocalScript that handles toggling menu visibility via the Enabled property

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI elements to load
local Menu = playerGui:WaitForChild("Menu")
local HUD = playerGui:WaitForChild("HUD")
local menuButton = HUD:WaitForChild("RightHUD"):WaitForChild("MenuButton")
local closeButton = Menu:WaitForChild("Background"):WaitForChild("CloseButton")

-- Initialize the Menu to be hidden on startup
Menu.Enabled = false

-- Function to toggle menu visibility
local function toggleMenu()
	Menu.Enabled = not Menu.Enabled
end

-- Connect the toggle function to menu button
menuButton.MouseButton1Click:Connect(toggleMenu)

-- Connect the toggle function to close button
closeButton.MouseButton1Click:Connect(function()
	Menu.Enabled = false
end)

-- Connect the toggle function to M key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Only handle input if not already processed by another script
	if not gameProcessed then
		-- Check if the input is M key
		if input.KeyCode == Enum.KeyCode.M then
			toggleMenu()
		end
	end
end)

print("Menu toggle system initialized")
