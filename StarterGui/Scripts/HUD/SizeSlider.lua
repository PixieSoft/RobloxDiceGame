-- /StarterGui/Scripts/HUD/SizeSlider.lua
-- LocalScript that creates a slider bar to control character scaling from 0.25 to 10

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Import the ScaleCharacter module and Stat module
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
local Stat = require(ReplicatedStorage.Stat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HUD = playerGui:WaitForChild("HUD")
local RightHUD = HUD:WaitForChild("RightHUD")

-- Constants - use the limits from the ScaleCharacter module
local MIN_SCALE = ScaleCharacter.MIN_SCALE
local MAX_SCALE = ScaleCharacter.MAX_SCALE
local STEP_SIZE = 0.25

-- Create the slider container
local sliderContainer = Instance.new("Frame")
sliderContainer.Name = "SizeSliderContainer"
sliderContainer.Size = UDim2.new(1, 0, 0, 70)
sliderContainer.Position = UDim2.new(0, 0, 0, 0)
sliderContainer.BackgroundTransparency = 1
sliderContainer.LayoutOrder = 20
sliderContainer.Parent = RightHUD

-- Add label for the slider
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 0.5
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleLabel.BorderSizePixel = 0
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Normal" -- Default preset name
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Parent = sliderContainer

-- Add rounded corners to the title
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 4)
titleCorner.Parent = titleLabel

-- Create slider background
local sliderBG = Instance.new("Frame")
sliderBG.Name = "SliderBG"
sliderBG.Size = UDim2.new(0.9, 0, 0, 8)
sliderBG.Position = UDim2.new(0.05, 0, 0.5, 0)
sliderBG.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderBG.BorderSizePixel = 0
sliderBG.Parent = sliderContainer

-- Add rounded corners to the slider background
local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 4)
bgCorner.Parent = sliderBG

-- Create slider fill (progress bar)
local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0.1, 0, 1, 0)
sliderFill.Position = UDim2.new(0, 0, 0, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBG

-- Add rounded corners to the slider fill
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = sliderFill

-- Create slider knob
local sliderKnob = Instance.new("Frame")
sliderKnob.Name = "SliderKnob"
sliderKnob.Size = UDim2.new(0, 16, 0, 16)
sliderKnob.Position = UDim2.new(0.1, -8, 0.5, -8)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 2
sliderKnob.Parent = sliderBG

-- Add rounded corners to the knob (make it circular)
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

-- Create value display label
local valueLabel = Instance.new("TextLabel")
valueLabel.Name = "ValueLabel"
valueLabel.Size = UDim2.new(0, 60, 0, 20)
valueLabel.Position = UDim2.new(1, -65, 0, 25)
valueLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
valueLabel.BackgroundTransparency = 0.5
valueLabel.BorderSizePixel = 0
valueLabel.Font = Enum.Font.GothamBold
valueLabel.Text = "1.00x"
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
valueLabel.TextSize = 12
valueLabel.Parent = sliderContainer

-- Add rounded corners to the value label
local valueCorner = Instance.new("UICorner")
valueCorner.CornerRadius = UDim.new(0, 4)
valueCorner.Parent = valueLabel

-- Add preset buttons layout at the bottom
local presetsContainer = Instance.new("Frame")
presetsContainer.Name = "PresetsContainer"
presetsContainer.Size = UDim2.new(1, 0, 0, 22)
presetsContainer.Position = UDim2.new(0, 0, 0.75, 0)
presetsContainer.BackgroundTransparency = 1
presetsContainer.Parent = sliderContainer

-- Create a UIListLayout for the preset buttons
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = presetsContainer

-- Preset buttons configuration
local presets = {
	{ name = "Small", value = "small" },
	{ name = "Normal", value = "normal" },
	{ name = "Large", value = "large" },
	{ name = "Huge", value = "huge" },
	{ name = "Giant", value = "giant" }
}

-- Create preset buttons
for i, preset in ipairs(presets) do
	local presetButton = Instance.new("TextButton")
	presetButton.Name = preset.name .. "Button"
	presetButton.Size = UDim2.new(0, 50, 0, 20)
	presetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	presetButton.BackgroundTransparency = 0.3
	presetButton.BorderSizePixel = 0
	presetButton.Font = Enum.Font.Gotham
	presetButton.Text = preset.name
	presetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	presetButton.TextSize = 12
	presetButton.LayoutOrder = i
	presetButton.Parent = presetsContainer

	-- Add rounded corners to the button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 4)
	buttonCorner.Parent = presetButton

	-- Button click event
	presetButton.MouseButton1Click:Connect(function()
		-- Use the SetScale method from ScaleCharacter module
		ScaleCharacter.SetScale(player, preset.value)

		-- Wait a moment for the data to update
		task.wait(0.1)

		-- Get the scale value from player data
		local scaleValueStat = Stat.Get(player, "ScaleValue")
		if scaleValueStat and scaleValueStat.Value ~= 0 then
			UpdateSliderUI(scaleValueStat.Value)
		else
			-- Fallback to preset value if stat not updated yet
			local scaleValue = ScaleCharacter.Presets[preset.value]
			if scaleValue then
				UpdateSliderUI(scaleValue)
			end
		end

		-- Highlight this button and reset others
		for _, child in pairs(presetsContainer:GetChildren()) do
			if child:IsA("TextButton") then
				if child == presetButton then
					-- Highlight the active preset button
					child.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					-- Reset other buttons
					child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end)

	-- Hover effects
	presetButton.MouseEnter:Connect(function()
		presetButton.BackgroundTransparency = 0.1
	end)

	presetButton.MouseLeave:Connect(function()
		presetButton.BackgroundTransparency = 0.3
	end)
end

-- Variables to track slider state
local isDragging = false
local currentScale = 1

-- Function to get capitalized preset name and scale value
local function getScaleDisplayInfo()
	-- Wait for player data to load
	if not Stat.WaitForLoad(player) then return "Normal", 1 end

	-- Get the scale name from player's data
	local scaleNameStat = Stat.Get(player, "ScaleName")
	local scaleValueStat = Stat.Get(player, "ScaleValue")

	local presetName = "Normal" -- Default name
	local scaleValue = 1 -- Default value

	if scaleNameStat and scaleNameStat.Value ~= "" then
		local rawName = scaleNameStat.Value
		presetName = rawName:sub(1, 1):upper() .. rawName:sub(2)
	end

	if scaleValueStat and scaleValueStat.Value ~= 0 then
		scaleValue = scaleValueStat.Value
	end

	return presetName, scaleValue
end

-- Function to update slider UI based on scale value
function UpdateSliderUI(scale)
	-- Calculate slider position (0 to 1)
	local normalizedValue = (scale - MIN_SCALE) / (MAX_SCALE - MIN_SCALE)
	normalizedValue = math.clamp(normalizedValue, 0, 1)

	-- Update slider fill
	sliderFill.Size = UDim2.new(normalizedValue, 0, 1, 0)

	-- Update knob position
	sliderKnob.Position = UDim2.new(normalizedValue, -8, 0.5, -8)

	-- Get the preset name and scale value from player data
	local presetName, scaleValue = getScaleDisplayInfo()

	-- Update title label with the preset name and scale value
	titleLabel.Text = presetName .. " (" .. string.format("%.2f", scaleValue) .. ")"

	-- Update value label
	valueLabel.Text = string.format("%.2fx", scale)

	-- Store the current scale
	currentScale = scale
end

-- Function to convert slider position to scale value
local function PositionToScale(xPosition)
	-- Calculate percentage along slider
	local sliderPosition = math.clamp((xPosition - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)

	-- Convert to scale value
	local scale = MIN_SCALE + sliderPosition * (MAX_SCALE - MIN_SCALE)

	-- Round to nearest step
	scale = math.floor(scale / STEP_SIZE + 0.5) * STEP_SIZE

	return scale
end

-- Function to scale the character to specified value
local function ScaleTo(scale)
	-- Clamp the scale value to our min/max range
	scale = math.clamp(scale, MIN_SCALE, MAX_SCALE)

	-- Round to nearest step
	scale = math.floor(scale / STEP_SIZE + 0.5) * STEP_SIZE

	-- Use the ScaleCharacter module to apply the scale
	ScaleCharacter.SetScale(player, scale)

	-- Wait a moment for the data to update
	task.wait(0.1)

	-- Update UI based on the latest data from Stat
	UpdateSliderUI(scale)

	return scale
end

-- Event handling
sliderBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		-- Start dragging
		isDragging = true

		-- Calculate and set the new scale
		local newScale = PositionToScale(input.Position.X)
		UpdateSliderUI(newScale)
		ScaleTo(newScale)
	end
end)

sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		-- Start dragging
		isDragging = true
	end
end)

sliderContainer.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch) then
		-- Stop dragging
		isDragging = false
	end
end)

-- Handle dragging
RunService.RenderStepped:Connect(function()
	if isDragging then
		local mousePos = game:GetService("UserInputService"):GetMouseLocation()

		-- Calculate and set the new scale
		local newScale = PositionToScale(mousePos.X)
		UpdateSliderUI(newScale)
		ScaleTo(newScale)
	end
end)

-- Initialize slider with current character scale
local function InitSlider()
	-- Wait for player data to load
	if not Stat.WaitForLoad(player) then return end

	-- Get the scale value from player's data
	local scaleValueStat = Stat.Get(player, "ScaleValue")
	local scaleNameStat = Stat.Get(player, "ScaleName")

	local scaleValue = 1 -- Default value
	local presetName = "normal" -- Default name

	if scaleValueStat and scaleValueStat.Value ~= 0 then
		scaleValue = scaleValueStat.Value
	end

	if scaleNameStat and scaleNameStat.Value ~= "" then
		presetName = scaleNameStat.Value
	end

	-- Update UI with the scale value
	UpdateSliderUI(scaleValue)

	-- Highlight the preset button that matches the current preset
	if presetName then
		for _, child in pairs(presetsContainer:GetChildren()) do
			if child:IsA("TextButton") then
				local buttonPresetName = child.Name:gsub("Button", ""):lower()
				if buttonPresetName == presetName then
					-- Highlight the active preset button
					child.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					-- Reset other buttons
					child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
end

-- Monitor character changes
player.CharacterAdded:Connect(function(character)
	-- Wait a moment for the character to fully load
	task.wait(1)

	-- Initialize with current scale from player data
	InitSlider()

	-- Poll for scale changes
	task.spawn(function()
		while character and character.Parent do
			task.wait(0.5) -- Check every half second

			-- Get current scale from player data
			if Stat.WaitForLoad(player) then
				local scaleValueStat = Stat.Get(player, "ScaleValue")
				if scaleValueStat and scaleValueStat.Value ~= 0 and scaleValueStat.Value ~= currentScale then
					UpdateSliderUI(scaleValueStat.Value)
				end
			end
		end
	end)
end)

-- Initialize if character already exists
if player.Character then
	task.spawn(InitSlider)
end

print("Size Slider initialized using ScaleCharacter module with range " .. MIN_SCALE .. " to " .. MAX_SCALE)
-- /StarterGui/Scripts/HUD/SizeSlider.lua
