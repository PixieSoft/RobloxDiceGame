-- /ReplicatedStorage/ModuleScripts/DiceModule

local DiceModule = {}

-- ModuleScript References
local ReplicatedStorage = game.ReplicatedStorage
local ServerScriptService = game.ServerScriptService
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local UtilityModule = require(Modules.UtilityModule)
local SpecialModule = require(Modules.SpecialActionsModule)
local DieFaces = require(ReplicatedStorage.Assets.Dice.DieFaces)

-- Frame Styles Configuration
DiceModule.FrameStyles = {
	Classic = {
		colors = {
			primary = Color3.fromRGB(45, 27, 62),    -- Dark purple
			accent = Color3.fromRGB(138, 43, 226),   -- Bright purple
			flourish = Color3.fromRGB(255, 255, 255) -- White
		},
		frameWidth = 2.5/16,
	}
}

-- Basic Stat Face Image IDs (preserved from original)
DiceModule.ImageID_Die_Stat_Faces = {
	Attack  = "rbxassetid://71038885344837",
	Defense = "rbxassetid://85271743638542",
	Healing = "rbxassetid://129069969078184",
}

-- Set default combat values based on tier (preserved from original)
DiceModule.CombatStatsByTier = {
	[1] = { HP = 10, MaxHP = 10, TempHP = 0, AC = 0, Rounds = 10 },
	[2] = { HP = 100, MaxHP = 100, TempHP = 0, AC = 0, Rounds = 100 },
	[3] = { HP = 1000, MaxHP = 1000, TempHP = 0, AC = 0, Rounds = 1000 },
	[4] = { HP = 10000, MaxHP = 10000, TempHP = 0, AC = 0, Rounds = 10000 }
}

-- Helper function to create frame elements
local function CreateFrameElement(parent, style)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = style.colors.primary
	frame.BorderSizePixel = 0
	frame.ZIndex = 2
	frame.Parent = parent
	return frame
end

-- Helper function to create corner decoration
local function CreateCornerDecoration(parent, style, position)
	local corner = Instance.new("Frame")
	corner.Size = UDim2.new(0.15, 0, 0.15, 0)
	corner.BackgroundColor3 = style.colors.accent
	corner.BorderSizePixel = 0
	corner.ZIndex = 2

	-- Position the corner based on parameter
	if position == "TopLeft" then
		corner.Position = UDim2.new(0, 0, 0, 0)
	elseif position == "TopRight" then
		corner.Position = UDim2.new(0.85, 0, 0, 0)
	elseif position == "BottomLeft" then
		corner.Position = UDim2.new(0, 0, 0.85, 0)
	elseif position == "BottomRight" then
		corner.Position = UDim2.new(0.85, 0, 0.85, 0)
	end

	corner.Parent = parent

	-- Add UICorner for rounded edges
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.25, 0)
	uiCorner.Parent = corner

	return corner
end

-- Helper function to create frame
local function CreateFrame(surfaceGui, style)
	local frameContainer = Instance.new("Frame")
	frameContainer.Size = UDim2.new(1, 0, 1, 0)
	frameContainer.BackgroundTransparency = 1
	frameContainer.ZIndex = 2
	frameContainer.Parent = surfaceGui

	-- Create frame borders
	local topBorder = CreateFrameElement(frameContainer, style)
	topBorder.Size = UDim2.new(1, 0, style.frameWidth, 0)
	topBorder.Position = UDim2.new(0, 0, 0, 0)

	local bottomBorder = CreateFrameElement(frameContainer, style)
	bottomBorder.Size = UDim2.new(1, 0, style.frameWidth, 0)
	bottomBorder.Position = UDim2.new(0, 0, 1 - style.frameWidth, 0)

	local leftBorder = CreateFrameElement(frameContainer, style)
	leftBorder.Size = UDim2.new(style.frameWidth, 0, 1, 0)
	leftBorder.Position = UDim2.new(0, 0, 0, 0)

	local rightBorder = CreateFrameElement(frameContainer, style)
	rightBorder.Size = UDim2.new(style.frameWidth, 0, 1, 0)
	rightBorder.Position = UDim2.new(1 - style.frameWidth, 0, 0, 0)

	-- Add corner decorations
	CreateCornerDecoration(frameContainer, style, "TopLeft")
	CreateCornerDecoration(frameContainer, style, "TopRight")
	CreateCornerDecoration(frameContainer, style, "BottomLeft")
	CreateCornerDecoration(frameContainer, style, "BottomRight")

	return frameContainer
end

-- Helper function to get the appropriate symbol or image based on elemental type (preserved from original)
function DiceModule.GetElementalDetails(element, detailType)
	if UtilityModule.Elemental_Details[element] then
		return UtilityModule.Elemental_Details[element][detailType] or "❓"
	end
	return "❓"  -- Returns a question mark if element not found
end

-- Function to get a random image ID for a given elemental type (preserved from original)
function DiceModule.GetRandomFaceImageID(die)
	local element = die:GetAttribute("AttackElement")
	local elementalType = DieFaces["ImageID_Dragons_" .. element] or DieFaces.ImageID_Dragons_Rainbow
	return elementalType[math.random(1, #elementalType)]
end

-- Modified function to add text and images to a specific face of the die
function DiceModule.AddFace(die, text, face)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceGui" .. face.Name
	surfaceGui.Adornee = die
	surfaceGui.Face = face
	surfaceGui.AlwaysOnTop = true
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = die

	-- Add background color matching frame
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)
	background.BackgroundColor3 = DiceModule.FrameStyles.Classic.colors.primary
	background.BorderSizePixel = 0
	background.ZIndex = 0  -- Put it behind everything
	background.Parent = surfaceGui

	-- Create background image
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.Position = UDim2.new(0, 0, 0, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ClipsDescendants = true
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.ZIndex = 1

	-- Set the image based on face type (preserved from original)
	if face == Enum.NormalId.Front then
		local faceImage = DiceModule.GetRandomFaceImageID(die)
		imageLabel.Image = faceImage
		die:SetAttribute("FaceImage", faceImage)
	elseif face == Enum.NormalId.Right then
		imageLabel.Image = DiceModule.ImageID_Die_Stat_Faces.Attack
	elseif face == Enum.NormalId.Left then
		imageLabel.Image = DiceModule.GetElementalDetails(die:GetAttribute("AttackElement"), "Image")
	elseif face == Enum.NormalId.Top then
		imageLabel.Image = DiceModule.ImageID_Die_Stat_Faces.Defense
	elseif face == Enum.NormalId.Bottom then
		imageLabel.Image = DiceModule.ImageID_Die_Stat_Faces.Healing
	elseif face == Enum.NormalId.Back then
		imageLabel.Image = "rbxassetid://0"
	end

	imageLabel.Parent = surfaceGui

	-- Add frame if enabled
	if die:GetAttribute("FrameEnabled") ~= false then
		local frame = CreateFrame(surfaceGui, DiceModule.FrameStyles.Classic)
	end

	-- Create text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Text = text or "N/A"
	textLabel.Size = UDim2.new(1, 0, 0.15, 0)  -- A slimmer label for text at the top
	textLabel.AnchorPoint = Vector2.new(0.5, 0)  -- Set the anchor to the middle of the X-axis
	textLabel.Position = UDim2.new(0.5, 0, 0, 0)  -- Centered horizontally, at the top vertically
	textLabel.BackgroundTransparency = 1  -- Ensure there is no background for the label
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.ZIndex = 3  -- Ensure it's above the frame and image label
	textLabel.Parent = surfaceGui
end

-- Function to add text labels for Attack, Defense, Healing, and Elemental on the front face
function DiceModule.AddFrontFaceLabels(die)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "FrontFaceLabelsGui"
	surfaceGui.Adornee = die
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = die

	-- Create Attack label (positioned towards the left side)
	local attackLabel = Instance.new("TextLabel")
	attackLabel.Text = tostring(die:GetAttribute("Attack")) .. " ⚔️"
	attackLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	attackLabel.AnchorPoint = Vector2.new(0, 0.5)
	attackLabel.Position = UDim2.new(0, 0, 0.5, 0)
	attackLabel.BackgroundTransparency = 1
	attackLabel.TextScaled = true
	attackLabel.TextColor3 = Color3.new(1, 1, 1)
	attackLabel.Font = Enum.Font.FredokaOne
	attackLabel.Rotation = -90  -- Rotate to align with the left edge
	attackLabel.ZIndex = 3
	attackLabel.Parent = surfaceGui

	-- Create Defense label (positioned towards the top side)
	local defenseLabel = Instance.new("TextLabel")
	defenseLabel.Text = tostring(die:GetAttribute("Defense")) .. " 🛡️"
	defenseLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	defenseLabel.AnchorPoint = Vector2.new(0.5, 0)
	defenseLabel.Position = UDim2.new(0.5, 0, 0, 0)
	defenseLabel.BackgroundTransparency = 1
	defenseLabel.TextScaled = true
	defenseLabel.TextColor3 = Color3.new(1, 1, 1)
	defenseLabel.Font = Enum.Font.FredokaOne
	defenseLabel.ZIndex = 3
	defenseLabel.Parent = surfaceGui

	-- Create Healing label (positioned towards the bottom side)
	local healingLabel = Instance.new("TextLabel")
	healingLabel.Text = tostring(die:GetAttribute("Healing")) .. " 🩹"
	healingLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	healingLabel.AnchorPoint = Vector2.new(0.5, 1)
	healingLabel.Position = UDim2.new(0.5, 0, 1, 0)
	healingLabel.BackgroundTransparency = 1
	healingLabel.TextScaled = true
	healingLabel.TextColor3 = Color3.new(1, 1, 1)
	healingLabel.Font = Enum.Font.FredokaOne
	healingLabel.ZIndex = 3
	healingLabel.Parent = surfaceGui

	-- Create Elemental label (positioned towards the right side)
	local elementalLabel = Instance.new("TextLabel")
	elementalLabel.Text = tostring(die:GetAttribute("Elemental")) .. " " .. UtilityModule.GetElementalDetails(die:GetAttribute("AttackElement"), "Symbol")
	elementalLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	elementalLabel.AnchorPoint = Vector2.new(1, 0.5)
	elementalLabel.Position = UDim2.new(1, 0, 0.5, 0)
	elementalLabel.BackgroundTransparency = 1
	elementalLabel.TextScaled = true
	elementalLabel.TextColor3 = Color3.new(1, 1, 1)
	elementalLabel.Font = Enum.Font.FredokaOne
	elementalLabel.Rotation = 90  -- Rotate to align with the right edge
	elementalLabel.ZIndex = 3
	elementalLabel.Parent = surfaceGui
end

-- Function to calculate Tier and Hitpoints (preserved from original)
function DiceModule.GetTierScore(die)
	local tierScore = die.Attack + die.Defense + die.Healing + die.Elemental
	if tierScore <= 9 then
		return 1
	elseif tierScore <= 99 then
		return 2
	elseif tierScore <= 999 then
		return 3
	else
		return 4
	end
end

-- Generate data for a new die (preserved from original)
function DiceModule.GenerateDieData()
	local dieData = {}
	repeat
		dieData.Attack = math.random(1, 96)
		dieData.Defense = math.random(1, 96)
		dieData.Healing = math.random(1, 96)
		dieData.Elemental = math.random(1, 96)
	until (dieData.Attack + dieData.Defense + dieData.Healing + dieData.Elemental) < 100

	dieData.Name = "Die" .. "_" .. math.random(100,999)
	dieData.Tier = 2
	dieData.Resistance = 10
	dieData.AttackElement = UtilityModule.GetRandomElement()
	dieData.ResistElement = UtilityModule.GetRandomElement()

	-- Set default frame attributes
	dieData.FrameEnabled = true

	local specialActions = SpecialModule.SpecialActions
	local specialKeys = {}
	for key in pairs(specialActions) do
		table.insert(specialKeys, key)
	end
	dieData.Special = specialKeys[math.random(#specialKeys)]

	return dieData
end

-- Function to create a die in the world (preserved from original)
function DiceModule.CreateDieInWorld(dieData, position)
	local diePart = Instance.new("Part")
	diePart.Name = dieData.Name or "Unnamed Die"
	diePart.Size = Vector3.new(2, 2, 2)
	diePart.Position = position
	diePart.Anchored = true
	diePart.CanCollide = true
	diePart.Parent = workspace

	-- Set attributes based on dieData
	for key, value in pairs(dieData) do
		diePart:SetAttribute(key, value)
	end

	-- Add text and symbols to each side of the die
	DiceModule.AddFace(diePart, "", Enum.NormalId.Front)
	DiceModule.AddFace(diePart, tostring(dieData.Attack) .. " ⚔️", Enum.NormalId.Right)
	DiceModule.AddFace(diePart, tostring(dieData.Elemental) .. " " .. UtilityModule.GetElementalDetails(dieData.AttackElement, "Symbol"), Enum.NormalId.Left)
	DiceModule.AddFace(diePart, tostring(dieData.Defense) .. " 🛡️", Enum.NormalId.Top)
	DiceModule.AddFace(diePart, tostring(dieData.Healing) .. " 🩹", Enum.NormalId.Bottom)
	DiceModule.AddFace(diePart, dieData.Special, Enum.NormalId.Back)

	-- Add front face labels using the new function
	DiceModule.AddFrontFaceLabels(diePart)

	return diePart
end

return DiceModule
