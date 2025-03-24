-- /ReplicatedStorage/Modules/Dice/DiceFrames
-- Client-accessible version of DiceFrames

local DiceFrames = {}

-- Collection of predefined frame styles
DiceFrames.Styles = {
	-- Classic purple dice frame style
	Classic = {
		name = "Classic",
		barColor = Color3.fromRGB(138, 43, 226), -- Bright purple
		cornerColor = Color3.fromRGB(45, 27, 62), -- Dark purple
		borderColor = Color3.fromRGB(255, 255, 255), -- White
		borderWidth = 1
	},

	-- Red fire-themed style
	Fire = {
		name = "Fire",
		barColor = Color3.fromRGB(220, 20, 20), -- Bright red
		cornerColor = Color3.fromRGB(120, 20, 10), -- Dark red
		borderColor = Color3.fromRGB(255, 165, 0), -- Orange
		borderWidth = 1
	},

	-- Blue water-themed style
	Water = {
		name = "Water",
		barColor = Color3.fromRGB(30, 144, 255), -- Dodger blue
		cornerColor = Color3.fromRGB(0, 48, 73), -- Dark blue
		borderColor = Color3.fromRGB(173, 216, 230), -- Light blue
		borderWidth = 1
	},

	-- Green nature-themed style
	Nature = {
		name = "Nature",
		barColor = Color3.fromRGB(34, 139, 34), -- Forest green
		cornerColor = Color3.fromRGB(20, 83, 20), -- Dark green
		borderColor = Color3.fromRGB(144, 238, 144), -- Light green
		borderWidth = 1
	},

	-- Golden luxury style
	Gold = {
		name = "Gold",
		barColor = Color3.fromRGB(255, 215, 0), -- Gold
		cornerColor = Color3.fromRGB(184, 134, 11), -- Dark goldenrod
		borderColor = Color3.fromRGB(255, 255, 224), -- Light yellow
		borderWidth = 2
	},

	-- Silver metallic style
	Silver = {
		name = "Silver",
		barColor = Color3.fromRGB(192, 192, 192), -- Silver
		cornerColor = Color3.fromRGB(105, 105, 105), -- Dim gray
		borderColor = Color3.fromRGB(220, 220, 220), -- Gainsboro
		borderWidth = 2
	},

	-- Dark shadow style
	Shadow = {
		name = "Shadow",
		barColor = Color3.fromRGB(47, 47, 47), -- Dark gray
		cornerColor = Color3.fromRGB(20, 20, 20), -- Nearly black
		borderColor = Color3.fromRGB(70, 70, 70), -- Medium gray
		borderWidth = 1
	},

	-- Light ethereal style
	Light = {
		name = "Light",
		barColor = Color3.fromRGB(255, 255, 240), -- Ivory
		cornerColor = Color3.fromRGB(240, 230, 140), -- Khaki
		borderColor = Color3.fromRGB(255, 250, 205), -- Lemon chiffon
		borderWidth = 1
	}
}

-- Get a style by name, or return Classic style if not found
function DiceFrames.GetStyle(styleName)
	if type(styleName) ~= "string" then
		return DiceFrames.Styles.Classic
	end

	for name, style in pairs(DiceFrames.Styles) do
		if name == styleName then
			return style
		end
	end

	-- Return Classic style as default
	return DiceFrames.Styles.Classic
end

return DiceFrames
