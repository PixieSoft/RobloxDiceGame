-- /ServerScriptService/Modules/Dice/DiceAppearance
-- Handles visual customization of dice

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DiceFrames = require(ReplicatedStorage.Modules.Dice.DiceFrames)
local DiceConstants = require(ServerScriptService.Modules.Dice.DiceConstants)
local UtilityModule = require(ReplicatedStorage.ModuleScripts.UtilityModule)

local DiceAppearance = {}

-- Get constants from DiceConstants
local FaceNames = DiceConstants.FaceNames
local BarElements = DiceConstants.BarElements
local StatDetails = DiceConstants.StatDetails

-- Helper function to determine if a color is dark or light
-- Uses luminance calculation (0.299*R + 0.587*G + 0.114*B)
local function IsColorDark(color)
	-- Convert RGB values to 0-1 range
	local r, g, b = color.R, color.G, color.B

	-- Calculate perceived luminance (weighted RGB)
	local luminance = 0.299 * r + 0.587 * g + 0.114 * b

	-- Return true if color is dark (luminance < 0.5)
	return luminance < 0.5
end

-- Helper function to get contrasting text color (black or white)
local function GetContrastingTextColor(bgColor)
	if IsColorDark(bgColor) then
		return Color3.new(1, 1, 1) -- White text on dark background
	else
		return Color3.new(0, 0, 0) -- Black text on light background
	end
end

-- Updates the bars in a die face with the specified style
local function UpdateFaceBars(face, style)
	for _, barName in ipairs(BarElements) do
		local bar = face:FindFirstChild(barName)
		if bar and bar:IsA("Frame") then
			-- Update the bar color
			bar.BackgroundColor3 = style.barColor

			-- Update border properties if specified
			if style.borderColor then
				bar.BorderColor3 = style.borderColor
			end

			if style.borderWidth then
				bar.BorderSizePixel = style.borderWidth
			end

			-- Find and update the label's text color for contrast
			local label = bar:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				label.TextColor3 = GetContrastingTextColor(style.barColor)
			end
		end
	end
end

-- Updates the corners in a die face with the specified style
local function UpdateFaceCorners(face, style)
	for _, child in ipairs(face:GetChildren()) do
		if child.Name == "Corner" and child:IsA("Frame") then
			-- Only update the corner color, keeping existing size and position
			child.BackgroundColor3 = style.cornerColor
		end
	end
end

-- Sets the image for a specific face of the die
function DiceAppearance.SetDieImage(die, faceName, imageID)
	local face = die:FindFirstChild(faceName)
	if face then
		-- Find the Image instance in the face
		local image = face:FindFirstChild("Image")
		if image and image:IsA("ImageLabel") then
			image.Image = imageID
		end
	end
end

-- Applies a frame style to all faces of the die
function DiceAppearance.ApplyFrameStyle(die, style)
	-- Get the style (either by name or directly)
	local actualStyle
	if type(style) == "string" then
		actualStyle = DiceFrames.GetStyle(style)
	else
		actualStyle = style
	end

	-- Store the style name as an attribute on the die
	die:SetAttribute("FrameStyle", actualStyle.name)

	-- Apply the style to each face
	for _, faceName in ipairs(FaceNames) do
		local face = die:FindFirstChild(faceName)
		if face then
			UpdateFaceBars(face, actualStyle)
			UpdateFaceCorners(face, actualStyle)
		end
	end
end

-- Gets the elemental icon for the die based on its attack element
local function GetElementalIcon(die)
	local attackElement = die:GetAttribute("AttackElement")
	if attackElement and UtilityModule.Elemental_Details[attackElement] then
		return UtilityModule.Elemental_Details[attackElement].Symbol
	end
	return StatDetails.Elemental.Icon -- Default icon
end

-- Updates a specific label in a face
local function UpdateLabel(face, barName, text)
	local bar = face and face:FindFirstChild(barName)
	local label = bar and bar:FindFirstChild("Label")

	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Updates all labels in a face with the same text
local function UpdateAllLabels(face, text)
	for _, barName in ipairs(BarElements) do
		UpdateLabel(face, barName, text)
	end
end

-- Updates the stat labels on a die face
function DiceAppearance.UpdateDieStatLabels(die)
	-- Get stat values
	local attackValue = die:GetAttribute("Attack") or 0
	local defenseValue = die:GetAttribute("Defense") or 0
	local healingValue = die:GetAttribute("Healing") or 0
	local elementalValue = die:GetAttribute("Elemental") or 0

	-- Get the elemental icon
	local elementalIcon = GetElementalIcon(die)

	-- Format stat texts
	local attackText = attackValue .. " " .. StatDetails.Attack.Icon
	local defenseText = defenseValue .. " " .. StatDetails.Defense.Icon
	local healingText = healingValue .. " " .. StatDetails.Healing.Icon
	local elementalText = elementalValue .. " " .. elementalIcon

	-- Update FrontFace (shows all stats on their respective sides)
	local frontFace = die:FindFirstChild("FrontFace")
	if frontFace then
		UpdateLabel(frontFace, StatDetails.Attack.Side, attackText)
		UpdateLabel(frontFace, StatDetails.Defense.Side, defenseText)
		UpdateLabel(frontFace, StatDetails.Healing.Side, healingText)
		UpdateLabel(frontFace, StatDetails.Elemental.Side, elementalText)
	end

	-- Update AttackFace (shows attack stat on all sides)
	local attackFace = die:FindFirstChild("AttackFace")
	if attackFace then
		UpdateAllLabels(attackFace, attackText)
	end

	-- Update DefenseFace (shows defense stat on all sides)
	local defenseFace = die:FindFirstChild("DefenseFace")
	if defenseFace then
		UpdateAllLabels(defenseFace, defenseText)
	end

	-- Update HealingFace (shows healing stat on all sides)
	local healingFace = die:FindFirstChild("HealingFace")
	if healingFace then
		UpdateAllLabels(healingFace, healingText)
	end

	-- Update ElementalFace (shows elemental stat on all sides)
	local elementalFace = die:FindFirstChild("ElementalFace")
	if elementalFace then
		UpdateAllLabels(elementalFace, elementalText)
	end

	-- Update SpecialFace (shows the special ability name)
	local specialFace = die:FindFirstChild("SpecialFace")
	local specialAbility = die:GetAttribute("Special") or "None"
	if specialFace then
		UpdateAllLabels(specialFace, specialAbility)
	end
end

-- Sets up event handlers to update die appearance when stats change
function DiceAppearance.SetupStatChangeHandler(die)
	-- List of attributes that should trigger appearance updates
	local statAttributes = {"Attack", "Defense", "Healing", "Elemental", "AttackElement", "Special"}

	-- Set up connections for each attribute
	for _, statName in ipairs(statAttributes) do
		die:GetAttributeChangedSignal(statName):Connect(function()
			DiceAppearance.UpdateDieStatLabels(die)
		end)
	end

	-- Initial update
	DiceAppearance.UpdateDieStatLabels(die)
end

-- Configures a die with images and frame style
function DiceAppearance.ConfigureDie(die, config)
	-- Apply frame style
	local styleName = config.frameStyle or "Classic"
	DiceAppearance.ApplyFrameStyle(die, styleName)

	-- Set face images where specified
	if config.frontImage then
		DiceAppearance.SetDieImage(die, "FrontFace", config.frontImage)
	end

	if config.elementalImage then
		DiceAppearance.SetDieImage(die, "ElementalFace", config.elementalImage)
	end

	if config.specialImage then
		DiceAppearance.SetDieImage(die, "SpecialFace", config.specialImage)
	end

	-- Set up stat change handler
	DiceAppearance.SetupStatChangeHandler(die)
end

return DiceAppearance
