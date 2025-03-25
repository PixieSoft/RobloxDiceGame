-- Import CollectionService
local CollectionService = game:GetService("CollectionService")
local tagName = "Grow"  -- Tag to look for

-- Load the CharacterResizer module
local CharacterResize = require(game.ServerScriptService.CharacterResize)

-- Set the size and duration
newSize  = "big"
duration = 5

-- Function to check if the hit object belongs to a player
local function GetPlayerFromHit(hit)
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		return game.Players:GetPlayerFromCharacter(character)
	end
	return nil
end

-- Function to connect the bounce effect to tagged objects
local function ConnectEffectToTaggedObjects()
	-- Get all objects tagged with "Bouncy"
	local taggedObjects = CollectionService:GetTagged(tagName)

	-- Loop through all tagged objects and apply the Touched event
	for _, obj in pairs(taggedObjects) do
		if obj:IsA("BasePart") then
			obj.Touched:Connect(function(hit)
				local player = GetPlayerFromHit(hit)
				if player then
					-- Apply size to the player's character
					CharacterResize.ResizeCharacter(hit.Parent, newSize, duration)
				end
			end)
		end
	end
end

-- Call the function to connect bounce effect to all existing "Bouncy" objects
ConnectEffectToTaggedObjects()

-- Optional: Listen for new objects being tagged as "Bouncy"
CollectionService:GetInstanceAddedSignal(tagName):Connect(function(obj)
	if obj:IsA("BasePart") then
		obj.Touched:Connect(function(hit)
			local player = GetPlayerFromHit(hit)
			if player then
				-- Apply bounce effect to the player's character
				ApplyShrink(hit.Parent)
			end
		end)
	end
end)
