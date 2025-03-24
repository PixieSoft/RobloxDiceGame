-- /ReplicatedStorage/Modules/Combat/CombatGui

local CombatGui = {}

-- Constants for face mapping
local FACE_MAP = {
	[1] = "HealingFace",
	[2] = "AttackFace", 
	[3] = "DefenseFace",
	[4] = "ElementalFace",
	[5] = "FrontFace",
	[6] = "SpecialFace"
}

-- Function to clone a face from a die and create a 2D representation
function CombatGui.CreateFaceDisplay(die, faceName, diceFrame)
	-- Get the face from the die
	local originalFace = die:FindFirstChild(faceName)
	if not originalFace then
		warn("Face not found: ", faceName)
		return diceFrame
	end

	-- Clear any existing face display content but keep the frame itself
	for _, child in ipairs(diceFrame:GetChildren()) do
		-- Don't remove ObjectValue references
		if not child:IsA("ObjectValue") then
			child:Destroy()
		end
	end

	-- Maintain UIAspectRatioConstraint
	local aspectConstraint = diceFrame:FindFirstChild("UIAspectRatioConstraint")
	if not aspectConstraint then
		aspectConstraint = Instance.new("UIAspectRatioConstraint")
		aspectConstraint.AspectRatio = 1
		aspectConstraint.Parent = diceFrame
	end

	-- Clone and position the face image
	local faceImage = originalFace:FindFirstChild("Image")
	if faceImage then
		local imageClone = faceImage:Clone()
		imageClone.Size = UDim2.new(1, 0, 1, 0)
		imageClone.Position = UDim2.new(0, 0, 0, 0)
		imageClone.ZIndex = 20 -- Match your z-index structure
		imageClone.Parent = diceFrame
	end

	-- Clone the bars and their labels
	local bars = {"BarTop", "BarBottom", "BarLeft", "BarRight"}
	for _, barName in ipairs(bars) do
		local originalBar = originalFace:FindFirstChild(barName)
		if originalBar then
			local barClone = originalBar:Clone()
			barClone.ZIndex = 21 -- One above the image

			-- Ensure label is visible
			local label = barClone:FindFirstChild("Label")
			if label then
				label.ZIndex = 22 -- One above the bars
			end

			barClone.Parent = diceFrame
		end
	end

	-- Clone the corners
	local corners = originalFace:GetChildren()
	for _, child in ipairs(corners) do
		if child.Name == "Corner" then
			local cornerClone = child:Clone()
			cornerClone.ZIndex = 21 -- Same as bars
			cornerClone.Parent = diceFrame
		end
	end

	return diceFrame
end

-- Function to handle the flip animation
-- Updated to preserve the diceFrame instead of destroying it
function CombatGui.FlipToFace(diceFrame, newFaceName, die, duration)
	duration = duration or 0.5

	if not diceFrame then
		warn("No diceFrame provided to FlipToFace")
		return nil
	end

	-- Store original properties
	local originalZIndex = diceFrame.ZIndex
	local originalParent = diceFrame.Parent

	-- Create temporary frame for transition animation
	local tempFrame = Instance.new("Frame")
	tempFrame.Name = "TempDice"
	tempFrame.Size = diceFrame.Size
	tempFrame.Position = diceFrame.Position
	tempFrame.BackgroundTransparency = 1
	tempFrame.ZIndex = originalZIndex
	tempFrame.Rotation = 90
	tempFrame.Parent = originalParent

	-- Hide the old frame for the transition
	diceFrame.Visible = false

	-- Set up new face in temporary frame
	CombatGui.CreateFaceDisplay(die, newFaceName, tempFrame)

	-- Animate old frame rotating out (but we don't destroy it)
	local tweenInfo = TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	-- Animate new face rotating in
	local tween2 = game:GetService("TweenService"):Create(tempFrame, tweenInfo, {
		Rotation = 0
	})

	-- Play the animation
	tempFrame.Visible = true
	tween2:Play()

	-- When animation completes, update the original frame and remove temp
	tween2.Completed:Connect(function()
		-- Update the original frame with the new face
		CombatGui.CreateFaceDisplay(die, newFaceName, diceFrame)

		-- Make the original frame visible again
		diceFrame.Visible = true

		-- Remove the temporary frame
		tempFrame:Destroy()
	end)

	return diceFrame
end

-- Function to perform a dice roll animation
-- Updated to preserve the diceFrame
function CombatGui.AnimateRoll(die, diceFrame, finalRoll, rollDuration)
	rollDuration = rollDuration or 2
	local numRolls = 10 -- Number of face changes during animation
	local delayBetweenRolls = rollDuration / numRolls

	-- Let's ensure the diceFrame exists
	if not diceFrame then
		warn("No diceFrame provided to AnimateRoll")
		return
	end

	-- Chain multiple face changes
	for i = 1, numRolls - 1 do
		task.delay(delayBetweenRolls * i, function()
			if diceFrame and diceFrame.Parent then  -- Check it still exists
				local randomFace = FACE_MAP[math.random(1, 6)]
				CombatGui.FlipToFace(diceFrame, randomFace, die, delayBetweenRolls)
			end
		end)
	end

	-- Final roll to the actual result
	task.delay(rollDuration - delayBetweenRolls, function()
		if diceFrame and diceFrame.Parent then  -- Check it still exists
			CombatGui.FlipToFace(diceFrame, FACE_MAP[finalRoll], die, delayBetweenRolls)
		end
	end)
end

return CombatGui
