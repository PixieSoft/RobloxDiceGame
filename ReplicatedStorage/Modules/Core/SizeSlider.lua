-- /ReplicatedStorage/Modules/UI/SizeSlider.lua
-- ModuleScript that creates and manages a character size slider UI component

local SizeSlider = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- References
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
local player = Players.LocalPlayer

-- Configuration
SizeSlider.DetentValues = {0.25, 0.5, 0.75, 1, 2, 4, 8}
SizeSlider.DefaultSizeIndex = 4 -- Index for size 1 (normal)

-- Variables
local isDragging = false
local currentSizeIndex = SizeSlider.DefaultSizeIndex
local pendingSizeIndex = nil
local sliderUI = nil
local handle = nil
local handleOriginalPosition = nil
local trackWidth = nil
local detentPositions = {}

-- Helper function to calculate positions for each detent on the slider track
local function calculateDetentPositions()
	if not sliderUI or not handle then return end

	local totalWidth = sliderUI.AbsoluteSize.X
	local numDetents = #SizeSlider.DetentValues
	trackWidth = totalWidth - handle.AbsoluteSize.X

	-- Calculate position for each detent
	detentPositions = {}
	for i = 1, numDetents do
		local proportion = (i - 1) / (numDetents - 1)
		local position = proportion * trackWidth
		detentPositions[i] = position
	end

	return detentPositions
end

-- Set the slider handle position based on size index
local function setHandlePosition(sizeIndex)
	if not handle or not detentPositions or #detentPositions == 0 then return end

	local position = detentPositions[sizeIndex] or 0
	handle.Position = UDim2.new(0, position, handleOriginalPosition.Y.Scale, handleOriginalPosition.Y.Offset)
end

-- Apply the character scale based on the current size index
local function applyCharacterScale()
	if not player then return end

	local sizeValue = SizeSlider.DetentValues[currentSizeIndex]
	ScaleCharacter.SetScale(player, sizeValue)

	-- Update slider value text if it exists
	if sliderUI and sliderUI:FindFirstChild("ValueText") then
		sliderUI.ValueText.Text = tostring(sizeValue) .. "x"
	end
end

-- Find the closest detent index to a given X position
local function findClosestDetentIndex(xPosition)
	if not detentPositions or #detentPositions == 0 then return currentSizeIndex end

	local closestIndex = 1
	local closestDistance = math.huge

	for i, position in ipairs(detentPositions) do
		local distance = math.abs(position - xPosition)
		if distance < closestDistance then
			closestDistance = distance
			closestIndex = i
		end
	end

	return closestIndex
end

-- Create detent indicators on the track
local function createDetentIndicators()
	if not sliderUI then return end

	-- First remove any existing indicators
	for _, child in ipairs(sliderUI:GetChildren()) do
		if child.Name == "DetentIndicator" then
			child:Destroy()
		end
	end

	-- Create indicators for each detent
	for i, position in ipairs(detentPositions) do
		local indicator = Instance.new("Frame")
		indicator.Name = "DetentIndicator"
		indicator.Size = UDim2.new(0, 2, 0, 16)
		indicator.Position = UDim2.new(0, position + (handle.AbsoluteSize.X / 2) - 1, 0.5, -8)

		-- Make the default position (1.0 scale, index 4) light blue, others remain white
		if i == SizeSlider.DefaultSizeIndex then -- Index 4 corresponds to size 1.0
			indicator.BackgroundColor3 = Color3.fromRGB(85, 170, 255) -- Light blue color
			indicator.Size = UDim2.new(0, 3, 0, 18) -- Slightly larger for emphasis
		else
			indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Light gray for other detents
		end

		indicator.BorderSizePixel = 0
		indicator.BackgroundTransparency = 0.3
		indicator.ZIndex = 1
		indicator.Parent = sliderUI
	end
end

-- Initialize the slider UI
function SizeSlider.Initialize(sliderFrame)
	sliderUI = sliderFrame

	-- Create the slider track
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, 4)
	track.Position = UDim2.new(0, 0, 0.5, -2)
	track.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	track.BorderSizePixel = 0
	track.Parent = sliderUI

	-- Create the slider handle
	handle = Instance.new("TextButton")
	handle.Name = "Handle"
	handle.Size = UDim2.new(0, 20, 0, 20)
	handle.Position = UDim2.new(0, 0, 0.5, -10)
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BorderColor3 = Color3.fromRGB(40, 40, 40)
	handle.BorderSizePixel = 1
	handle.AutoButtonColor = false
	handle.Text = ""
	handle.Parent = sliderUI

	-- Store original handle position
	handleOriginalPosition = handle.Position

	-- Create a text label to show the current value
	local valueText = Instance.new("TextLabel")
	valueText.Name = "ValueText"
	valueText.Size = UDim2.new(0, 50, 0, 20)
	valueText.Position = UDim2.new(0.5, -25, 0.5, -30)
	valueText.BackgroundTransparency = 1
	valueText.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueText.TextSize = 14
	valueText.Font = Enum.Font.SourceSansBold
	valueText.Text = "1x"
	valueText.Parent = sliderUI

	-- Calculate detent positions
	calculateDetentPositions()

	-- Create detent indicators
	createDetentIndicators()

	-- Set initial handle position
	setHandlePosition(currentSizeIndex)

	-- Input handling
	handle.MouseButton1Down:Connect(function()
		isDragging = true
		-- Do not apply the scale yet, just store the original index to revert if needed
		pendingSizeIndex = currentSizeIndex
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
			isDragging = false
			-- Apply the scale change only when mouse button is released
			if pendingSizeIndex and pendingSizeIndex ~= currentSizeIndex then
				currentSizeIndex = pendingSizeIndex
				applyCharacterScale()
			end
			pendingSizeIndex = nil
		end
	end)

	-- Update handle position while dragging
	RunService.RenderStepped:Connect(function()
		if isDragging then
			local mousePos = UserInputService:GetMouseLocation()
			local framePos = sliderUI.AbsolutePosition
			local relativeX = mousePos.X - framePos.X - (handle.AbsoluteSize.X / 2)

			-- Clamp to slider bounds
			relativeX = math.clamp(relativeX, 0, trackWidth)

			-- Find the closest detent
			pendingSizeIndex = findClosestDetentIndex(relativeX)

			-- Update handle position
			setHandlePosition(pendingSizeIndex)

			-- Update value text (preview only)
			if sliderUI and sliderUI:FindFirstChild("ValueText") then
				sliderUI.ValueText.Text = tostring(SizeSlider.DetentValues[pendingSizeIndex]) .. "x"
			end
		end
	end)

	-- On window resize, recalculate positions
	sliderUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		calculateDetentPositions()
		createDetentIndicators()
		setHandlePosition(currentSizeIndex)
	end)

	-- Apply initial scale
	applyCharacterScale()

	return SizeSlider
end

-- Set size programmatically
function SizeSlider.SetSize(sizeValue)
	-- Find the index of the closest size value
	local closestIndex = 1
	local closestDistance = math.huge

	for i, value in ipairs(SizeSlider.DetentValues) do
		local distance = math.abs(value - sizeValue)
		if distance < closestDistance then
			closestDistance = distance
			closestIndex = i
		end
	end

	currentSizeIndex = closestIndex
	setHandlePosition(currentSizeIndex)
	applyCharacterScale()
end

-- Show/hide the slider
function SizeSlider.SetVisible(visible)
	if sliderUI then
		sliderUI.Visible = visible
	end
end

-- For testing - auto-initialize when the module is required
-- This will need to be removed later when we implement show/hide functionality
if RunService:IsClient() then
	local function initializeWhenReady()
		local player = Players.LocalPlayer
		if not player then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			player = Players.LocalPlayer
		end

		local playerGui = player:WaitForChild("PlayerGui")
		local hud = playerGui:WaitForChild("HUD")
		local bottomHUD = hud:WaitForChild("BottomHUD")
		local sizeSlider = bottomHUD:WaitForChild("SizeSlider")

		SizeSlider.Initialize(sizeSlider)
	end

	task.spawn(initializeWhenReady)
end

return SizeSlider
-- /ReplicatedStorage/Modules/UI/SizeSlider.lua
