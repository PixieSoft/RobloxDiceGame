-- /StarterPlayerScripts/SizeSliderTest.lua
-- LocalScript that initializes the size slider for testing purposes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for player to load
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

-- Wait for PlayerGui and the UI elements to load
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("HUD")
local bottomHUD = hud:WaitForChild("BottomHUD")
local sizeSlider = bottomHUD:WaitForChild("SizeSlider")

-- Load the size slider module
local SizeSlider = require(ReplicatedStorage.Modules.Core.SizeSlider)

-- Initialize the slider
SizeSlider.Initialize(sizeSlider)

-- Make sure it's visible
SizeSlider.SetVisible(true)

-- Optional: Get the player's current scale and set the slider to match
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
local currentScale = ScaleCharacter.GetScale(player)
if currentScale then
	SizeSlider.SetSize(currentScale)
end

print("Size slider initialized and ready to use!")
-- /StarterPlayerScripts/SizeSliderTest.lua
