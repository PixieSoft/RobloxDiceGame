-- ModuleScript: CharacterResizer
local CharacterResize = {}

-- Function to resize a player's character
function CharacterResize.ResizeCharacter(character, size, duration)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local originalStats = {}

	local newSize
	local newSpeed
	local newJump
	local newFriction

	-- Set size variables
	if tostring(size):lower() == "big" then
		-- Make character big
		newSize  = 3.0
		newSpeed = 3.0
		newJump  = 3.0
		--newFriction = PhysicalProperties.new(15.0, 0.3, 0.5)
	else
		-- Make character small
		newSize  = 0.33
		newSpeed = 0.33
		newJump  = 0.33
		--newFriction = PhysicalProperties.new(15.0, 2.0, 1.0)
	end

	-- Skip if already resized
	if not character:GetAttribute("Resized") then
		if humanoid then
			-- Handle R6 characters
			if humanoid.RigType == Enum.HumanoidRigType.R6 then
				local bodyParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

				-- Save the original sizes and resize each body part
				for _, partName in pairs(bodyParts) do
					local part = character:FindFirstChild(partName)
					if part then
						originalStats[partName] = part.Size
						originalStats[partName .. "Friction"] = part.CustomPhysicalProperties -- Save original friction
						part.Size = part.Size * newSize
						part.CustomPhysicalProperties = newFriction  -- Adjust friction based on size
					end
				end

				-- Handle R15 characters
			elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
				originalStats.BodyDepthScale = humanoid.BodyDepthScale.Value
				originalStats.BodyHeightScale = humanoid.BodyHeightScale.Value
				originalStats.BodyWidthScale = humanoid.BodyWidthScale.Value
				originalStats.HeadScale = humanoid.HeadScale.Value

				humanoid.BodyDepthScale.Value = humanoid.BodyDepthScale.Value * newSize
				humanoid.BodyHeightScale.Value = humanoid.BodyHeightScale.Value * newSize
				humanoid.BodyWidthScale.Value = humanoid.BodyWidthScale.Value * newSize
				humanoid.HeadScale.Value = humanoid.HeadScale.Value * newSize

				-- Apply new friction to parts
				for _, part in pairs(character:GetChildren()) do
					if part:IsA("BasePart") then
						part.CustomPhysicalProperties = newFriction
					end
				end
			end

			-- Save the original JumpPower and WalkSpeed values then set new values
			originalStats["JumpHeight"] = humanoid.JumpHeight
			originalStats["JumpPower"] = humanoid.JumpPower
			originalStats["WalkSpeed"] = humanoid.WalkSpeed
			humanoid.JumpHeight = humanoid.JumpHeight * newJump
			humanoid.JumpPower = humanoid.JumpPower * newJump
			humanoid.WalkSpeed = humanoid.WalkSpeed * newSpeed
			
			-- Set the resized flag to true
			character:SetAttribute("Resized", true)
		end

		-- Revert sizes after the duration
		task.delay(duration, function()
			if humanoid then
				-- Revert R6 sizes
				if humanoid.RigType == Enum.HumanoidRigType.R6 then
					for _, partName in pairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
						local part = character:FindFirstChild(partName)
						if part and originalStats[partName] then
							part.Size = originalStats[partName]
							part.CustomPhysicalProperties = originalStats[partName .. "Friction"]  -- Revert friction
						end
					end

					-- Revert R15 sizes
				elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
					humanoid.BodyDepthScale.Value = originalStats.BodyDepthScale
					humanoid.BodyHeightScale.Value = originalStats.BodyHeightScale
					humanoid.BodyWidthScale.Value = originalStats.BodyWidthScale
					humanoid.HeadScale.Value = originalStats.HeadScale
				end

				-- Revert JumpPower and WalkSpeed
				humanoid.JumpHeight = originalStats["JumpHeight"]
				humanoid.JumpPower = originalStats["JumpPower"]
				humanoid.WalkSpeed = originalStats["WalkSpeed"]
				
				-- Clear resized flag
				character:SetAttribute("Resized", false)
			end
		end)
	end
end

return CharacterResize
