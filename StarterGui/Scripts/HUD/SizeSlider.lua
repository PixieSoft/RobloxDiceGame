-- /StarterGui/Scripts/HUD/SizeSlider.lua
-- LocalScript that creates a slider bar to control character scaling from 0.25 to 10

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HUD = playerGui:WaitForChild("HUD")
local RightHUD = HUD:WaitForChild("RightHUD")

-- Constants
local MIN_SCALE = 0.25
local MAX_SCALE = 10
local STEP_SIZE = 0.25

-- Create or get remote event for scaling
local scaleRemoteEvent = ReplicatedStorage:FindFirstChild("ScaleCharacterEvent")
if not scaleRemoteEvent then
	scaleRemoteEvent = Instance.new("RemoteEvent")
	scaleRemoteEvent.Name = "ScaleCharacterEvent"
	scaleRemoteEvent.Parent = ReplicatedStorage
end

-- Helper function to get current character scale using Model:GetScale() API
local function GetScale(character)
	if not character then return 1 end

	-- Use the Model:GetScale() API
	local success, scale = pcall(function()
		return character:GetScale()
	end)

	-- If successful, return the scale
	if success and scale then
		return scale
	end

	-- Default to 1 if we couldn't get the scale
	return 1
end

-- Function to scale the character to specified value
local function ScaleTo(scale)
	-- Clamp the scale value to our min/max range
	scale = math.clamp(scale, MIN_SCALE, MAX_SCALE)

	-- Round to nearest step
	scale = math.floor(scale / STEP_SIZE + 0.5) * STEP_SIZE

	-- Fire remote event to server
	scaleRemoteEvent:FireServer(scale)

	return scale
end

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
titleLabel.Text = "Character Size"
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

-- Variables to track slider state
local isDragging = false
local currentScale = 1

-- Function to update slider UI based on scale value
local function UpdateSliderUI(scale)
	-- Calculate slider position (0 to 1)
	local normalizedValue = (scale - MIN_SCALE) / (MAX_SCALE - MIN_SCALE)
	normalizedValue = math.clamp(normalizedValue, 0, 1)

	-- Update slider fill
	sliderFill.Size = UDim2.new(normalizedValue, 0, 1, 0)

	-- Update knob position
	sliderKnob.Position = UDim2.new(normalizedValue, -8, 0.5, -8)

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
	local character = player.Character
	if character then
		local scale = GetScale(character)
		UpdateSliderUI(scale)
	end
end

-- Monitor character changes
player.CharacterAdded:Connect(function(character)
	-- Wait a moment for the character to fully load
	task.wait(1)

	-- Initialize with current scale
	local scale = GetScale(character)
	UpdateSliderUI(scale)

	-- Poll for scale changes
	task.spawn(function()
		while character and character.Parent do
			task.wait(0.5) -- Check every half second
			local currentScale = GetScale(character)
			if currentScale ~= nil then
				UpdateSliderUI(currentScale)
			end
		end
	end)
end)

-- Initialize if character already exists
if player.Character then
	task.spawn(InitSlider)
end

print("Size Slider initialized with range " .. MIN_SCALE .. " to " .. MAX_SCALE)
