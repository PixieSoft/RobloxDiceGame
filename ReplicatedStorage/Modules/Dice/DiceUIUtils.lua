-- /ReplicatedStorage/Modules/Dice/DiceUIUtils
-- Shared utility functions for dice UI rendering

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DiceFrames = require(ReplicatedStorage.Modules.Dice.DiceFrames)
local UtilityModule = require(ReplicatedStorage.ModuleScripts.UtilityModule)

local DiceUIUtils = {}

-- Helper function to determine if a color is dark or light
function DiceUIUtils.IsColorDark(color)
	-- Convert RGB values to 0-1 range
	local r, g, b = color.R, color.G, color.B

	-- Calculate perceived luminance (weighted RGB)
	local luminance = 0.299 * r + 0.587 * g + 0.114 * b

	-- Return true if color is dark (luminance < 0.5)
	return luminance < 0.5
end

-- Helper function to get contrasting text color (black or white)
function DiceUIUtils.GetContrastingTextColor(bgColor)
	if DiceUIUtils.IsColorDark(bgColor) then
		return Color3.new(1, 1, 1) -- White text on dark background
	else
		return Color3.new(0, 0, 0) -- Black text on light background
	end
end

-- Get the elemental symbol for a die
function DiceUIUtils.GetElementalSymbol(elementType)
	if elementType and UtilityModule.Elemental_Details and 
		UtilityModule.Elemental_Details[elementType] then
		return UtilityModule.Elemental_Details[elementType].Symbol
	end
	return "🔥" -- Default fallback
end

-- Apply a frame style to a UI button or frame based on a die
function DiceUIUtils.ApplyDieFrameStyle(die, button)
	-- Get the frameStyle attribute or name - use "Classic" as the default
	local frameStyle = die:GetAttribute("frameStyle") or die:GetAttribute("FrameStyle") or "Classic"

	-- Get the style data
	local style = DiceFrames.GetStyle(frameStyle)

	-- Clear existing frame UI elements (except references and the main image)
	for _, child in ipairs(button:GetChildren()) do
		if not child:IsA("ObjectValue") and child.Name ~= "Image" then
			child:Destroy()
		end
	end

	-- Get the die stats to use in labels
	local stats = {
		Attack = die:GetAttribute("Attack") or 0,
		Defense = die:GetAttribute("Defense") or 0,
		Healing = die:GetAttribute("Healing") or 0,
		Elemental = die:GetAttribute("Elemental") or 0
	}

	-- Set up main background
	button.BackgroundTransparency = 1 -- Make transparent so image shows

	-- Create frame for top bar
	local topBar = Instance.new("Frame")
	topBar.Name = "BarTop"
	topBar.Size = UDim2.new(1, 0, 0.15, 0)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = style.barColor
	topBar.BorderSizePixel = style.borderWidth or 1
	topBar.BorderColor3 = style.borderColor
	topBar.ZIndex = 2
	topBar.Parent = button

	-- Add label to top bar
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "Label"
	topLabel.Size = UDim2.new(1, 0, 1, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = stats.Defense .. " 🛡️"
	topLabel.TextColor3 = DiceUIUtils.GetContrastingTextColor(style.barColor)
	topLabel.Font = Enum.Font.GothamBold
	topLabel.TextSize = 14
	topLabel.ZIndex = 3
	topLabel.Parent = topBar

	-- Create frame for bottom bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BarBottom"
	bottomBar.Size = UDim2.new(1, 0, 0.15, 0)
	bottomBar.Position = UDim2.new(0, 0, 0.85, 0)
	bottomBar.BackgroundColor3 = style.barColor
	bottomBar.BorderSizePixel = style.borderWidth or 1
	bottomBar.BorderColor3 = style.borderColor
	bottomBar.ZIndex = 2
	bottomBar.Parent = button

	-- Add label to bottom bar
	local bottomLabel = Instance.new("TextLabel")
	bottomLabel.Name = "Label"
	bottomLabel.Size = UDim2.new(1, 0, 1, 0)
	bottomLabel.BackgroundTransparency = 1
	bottomLabel.Text = stats.Healing .. " 🩹"
	bottomLabel.TextColor3 = DiceUIUtils.GetContrastingTextColor(style.barColor)
	bottomLabel.Font = Enum.Font.GothamBold
	bottomLabel.TextSize = 14
	bottomLabel.ZIndex = 3
	bottomLabel.Parent = bottomBar

	-- Create frame for left bar
	local leftBar = Instance.new("Frame")
	leftBar.Name = "BarLeft"
	leftBar.Size = UDim2.new(0.15, 0, 1, 0)
	leftBar.Position = UDim2.new(0, 0, 0, 0)
	leftBar.BackgroundColor3 = style.barColor
	leftBar.BorderSizePixel = style.borderWidth or 1
	leftBar.BorderColor3 = style.borderColor
	leftBar.ZIndex = 2
	leftBar.Parent = button

	-- Add label to left bar
	local leftLabel = Instance.new("TextLabel")
	leftLabel.Name = "Label"
	leftLabel.Size = UDim2.new(1, 0, 1, 0)
	leftLabel.BackgroundTransparency = 1
	leftLabel.Text = stats.Attack .. " ⚔️"
	leftLabel.TextColor3 = DiceUIUtils.GetContrastingTextColor(style.barColor)
	leftLabel.Font = Enum.Font.GothamBold
	leftLabel.TextSize = 14
	leftLabel.Rotation = -90
	leftLabel.ZIndex = 3
	leftLabel.Parent = leftBar

	-- Create frame for right bar
	local rightBar = Instance.new("Frame")
	rightBar.Name = "BarRight" 
	rightBar.Size = UDim2.new(0.15, 0, 1, 0)
	rightBar.Position = UDim2.new(0.85, 0, 0, 0)
	rightBar.BackgroundColor3 = style.barColor
	rightBar.BorderSizePixel = style.borderWidth or 1
	rightBar.BorderColor3 = style.borderColor
	rightBar.ZIndex = 2
	rightBar.Parent = button

	-- Get the elemental symbol
	local elementalSymbol = DiceUIUtils.GetElementalSymbol(die:GetAttribute("AttackElement"))

	-- Add label to right bar
	local rightLabel = Instance.new("TextLabel")
	rightLabel.Name = "Label"
	rightLabel.Size = UDim2.new(1, 0, 1, 0)
	rightLabel.BackgroundTransparency = 1
	rightLabel.Text = stats.Elemental .. " " .. elementalSymbol
	rightLabel.TextColor3 = DiceUIUtils.GetContrastingTextColor(style.barColor)
	rightLabel.Font = Enum.Font.GothamBold
	rightLabel.TextSize = 14
	rightLabel.Rotation = 90
	rightLabel.ZIndex = 3
	rightLabel.Parent = rightBar

	-- Create corners
	local cornerPositions = {
		{0, 0},     -- Top-left
		{0.85, 0},  -- Top-right
		{0, 0.85},  -- Bottom-left
		{0.85, 0.85}  -- Bottom-right
	}

	for _, pos in ipairs(cornerPositions) do
		local corner = Instance.new("Frame")
		corner.Name = "Corner"
		corner.Size = UDim2.new(0.15, 0, 0.15, 0)
		corner.Position = UDim2.new(pos[1], 0, pos[2], 0)
		corner.BackgroundColor3 = style.cornerColor
		corner.BorderSizePixel = style.borderWidth or 1
		corner.BorderColor3 = style.borderColor
		corner.ZIndex = 2

		-- Add UICorner to make it rounded
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.3, 0)
		uiCorner.Parent = corner

		corner.Parent = button
	end
end

-- Create a clean/empty appearance for a die slot
function DiceUIUtils.CreateEmptyDieAppearance(button)
	-- Clear existing UI elements (except references)
	for _, child in ipairs(button:GetChildren()) do
		if not child:IsA("ObjectValue") then
			child:Destroy()
		end
	end

	-- Set up empty appearance
	button.Image = ""
	button.BackgroundTransparency = 0
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

	-- Create frame for top bar
	local topBar = Instance.new("Frame")
	topBar.Name = "BarTop"
	topBar.Size = UDim2.new(1, 0, 0.15, 0)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	topBar.BorderSizePixel = 1
	topBar.Parent = button

	-- Create frame for bottom bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BarBottom"
	bottomBar.Size = UDim2.new(1, 0, 0.15, 0)
	bottomBar.Position = UDim2.new(0, 0, 0.85, 0)
	bottomBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	bottomBar.BorderSizePixel = 1
	bottomBar.Parent = button

	-- Create frame for left bar
	local leftBar = Instance.new("Frame")
	leftBar.Name = "BarLeft"
	leftBar.Size = UDim2.new(0.15, 0, 1, 0)
	leftBar.Position = UDim2.new(0, 0, 0, 0)
	leftBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	leftBar.BorderSizePixel = 1
	leftBar.Parent = button

	-- Create frame for right bar
	local rightBar = Instance.new("Frame")
	rightBar.Name = "BarRight"
	rightBar.Size = UDim2.new(0.15, 0, 1, 0)
	rightBar.Position = UDim2.new(0.85, 0, 0, 0)
	rightBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	rightBar.BorderSizePixel = 1
	rightBar.Parent = button

	-- Create corners
	local cornerPositions = {
		{0, 0},     -- Top-left
		{0.85, 0},  -- Top-right
		{0, 0.85},  -- Bottom-left
		{0.85, 0.85}  -- Bottom-right
	}

	for _, pos in ipairs(cornerPositions) do
		local corner = Instance.new("Frame")
		corner.Name = "Corner"
		corner.Size = UDim2.new(0.15, 0, 0.15, 0)
		corner.Position = UDim2.new(pos[1], 0, pos[2], 0)
		corner.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		corner.BorderSizePixel = 1

		-- Add UICorner to make it rounded
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.3, 0)
		uiCorner.Parent = corner

		corner.Parent = button
	end
end

return DiceUIUtils
