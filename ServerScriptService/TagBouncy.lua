-- Import CollectionService
local CollectionService = game:GetService("CollectionService")
local tagName = "Bouncy"  -- Tag to look for

-- Bounce settings
local bounceForce = 100  -- Adjust the strength of the bounce

-- Function to check if the hit object belongs to a player
local function GetPlayerFromHit(hit)
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		return game.Players:GetPlayerFromCharacter(character)
	end
	return nil
end

-- Function to apply bounce effect to the player
local function ApplyBounce(character)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		-- Add a temporary BodyVelocity to apply upward force
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(0, bounceForce, 0)  -- Apply upward force
		bodyVelocity.MaxForce = Vector3.new(0, bounceForce * 100, 0)  -- Max force only affects upward movement
		bodyVelocity.P = 1250  -- Power of the force
		bodyVelocity.Parent = humanoidRootPart

		-- Remove the BodyVelocity after a short duration to stop the force
		game.Debris:AddItem(bodyVelocity, 0.2)  -- Automatically remove after 0.2 seconds
	end
end

-- Function to connect the bounce effect to tagged objects
local function ConnectBounceEffectToTaggedObjects()
	-- Get all objects tagged with "Bouncy"
	local taggedObjects = CollectionService:GetTagged(tagName)

	-- Loop through all tagged objects and apply the Touched event
	for _, obj in pairs(taggedObjects) do
		if obj:IsA("BasePart") then
			obj.Touched:Connect(function(hit)
				local player = GetPlayerFromHit(hit)
				if player then
					-- Apply bounce effect to the player's character
					ApplyBounce(hit.Parent)
				end
			end)
		end
	end
end

-- Call the function to connect bounce effect to all existing "Bouncy" objects
ConnectBounceEffectToTaggedObjects()

-- Optional: Listen for new objects being tagged as "Bouncy"
CollectionService:GetInstanceAddedSignal(tagName):Connect(function(obj)
	if obj:IsA("BasePart") then
		obj.Touched:Connect(function(hit)
			local player = GetPlayerFromHit(hit)
			if player then
				-- Apply bounce effect to the player's character
				ApplyBounce(hit.Parent)
			end
		end)
	end
end)
