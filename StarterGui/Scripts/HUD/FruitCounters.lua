local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local Constants = require(Modules:WaitForChild("ConstantsModule"))
local Stat = require(ReplicatedStorage.Stat)
local Short = require(ReplicatedStorage.Short)

-- Get reference to our Interface and nested elements
local Interface = script.Parent
local HUD = Interface:WaitForChild("HUD")
local Counters = HUD:WaitForChild("Counters")

-- Function to dynamically update text size
local function updateTextSize(label)
	-- Disable TextScaled and TextWrapped
	label.TextScaled = false
	label.TextWrapped = false

	-- Get the frame dimensions
	local frameWidth = label.AbsoluteSize.X
	local frameHeight = label.AbsoluteSize.Y

	-- Start with a base size and adjust until text fits
	local size = 10
	label.TextSize = size

	while size < 100 do -- Upper limit to prevent infinite loops
		label.TextSize = size
		local textWidth = label.TextBounds.X
		local textHeight = label.TextBounds.Y

		if textWidth > frameWidth or textHeight > frameHeight then
			-- Text is too big, go back one size
			label.TextSize = size - 1
			break
		end

		size = size + 1
	end
end

local function initialize()
	local player = game.Players.LocalPlayer
	print("Starting initialization for player:", player.Name)

	if not Stat.WaitForLoad(player) then 
		print("Failed to load player stats")
		return 
	end
	print("Stats loaded successfully")

	for _, fruitType in ipairs(Constants.Fruit.Types) do
		local frame = Counters:FindFirstChild(fruitType .. "Frame")
		if not frame then
			print("Couldn't find frame for:", fruitType)
			continue
		end

		local label = frame:FindFirstChild(fruitType .. "Label")
		if not label then
			print("Couldn't find label for:", fruitType, "in frame")
			continue
		end
		print("Found label for:", fruitType)

		local fruitStat = Stat.Get(player, fruitType)
		if fruitStat then
			print("Initial value for", fruitType, ":", fruitStat.Value)

			-- Set initial value and size
			label.Text = Short.toSuffix(fruitStat.Value)
			updateTextSize(label)

			-- Update label whenever the stat changes
			fruitStat.Changed:Connect(function(newValue)
				print("Value changed for", fruitType, "to:", newValue)
				label.Text = Short.toSuffix(newValue)
				updateTextSize(label)
			end)

			-- Update text size when the frame size changes
			label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				updateTextSize(label)
			end)
		else
			print("Could not get stat for:", fruitType)
		end
	end
end

initialize()
