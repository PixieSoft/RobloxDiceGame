-- /StarterGui/DiceInventory/InventoryManager
-- Controls the dice inventory and dice loading functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DiceUIUtils = require(ReplicatedStorage.Modules.Dice.DiceUIUtils)
local CombatModule = require(ReplicatedStorage.ModuleScripts.CombatModule)

local InventoryManager = {}
InventoryManager.__index = InventoryManager

-- References to GUI elements
InventoryManager.UI = {
	screenGui = nil,
	inventoryFrame = nil,
	scrollingFrame = nil
}

-- State tracking
InventoryManager.State = {
	targetLoadedDie = nil,
	player = Players.LocalPlayer
}

-- Initialize the inventory manager
function InventoryManager.Initialize(screenGui, inventoryFrame, scrollingFrame)
	InventoryManager.UI.screenGui = screenGui
	InventoryManager.UI.inventoryFrame = inventoryFrame
	InventoryManager.UI.scrollingFrame = scrollingFrame

	print("InventoryManager initialized")
end

-- Get player's inventory folder
function InventoryManager.GetInventory()
	local player = InventoryManager.State.player
	if not player then return nil end

	return player:FindFirstChild("DiceInventory")
end

-- Get the actual die object from a LoadedDie
function InventoryManager.GetDieFromLoadedDie(loadedDie)
	local dieRef = loadedDie:FindFirstChild("DieReference")
	if dieRef and dieRef:IsA("ObjectValue") and dieRef.Value then
		return dieRef.Value
	end
	return nil
end

-- Ensure LoadedDie references have ObjectValues
function InventoryManager.EnsureLoadedDieReference(loadedDie)
	local dieReference = loadedDie:FindFirstChild("DieReference")
	if not dieReference or not dieReference:IsA("ObjectValue") then
		if dieReference then dieReference:Destroy() end
		dieReference = Instance.new("ObjectValue")
		dieReference.Name = "DieReference"
		dieReference.Parent = loadedDie
	end
	return dieReference
end

-- Load a die into a combat slot
function InventoryManager.LoadDieIntoSlot(die, loadedDieImage)
	-- Check if there's already a die in this slot
	local existingDie = InventoryManager.GetDieFromLoadedDie(loadedDieImage)
	if existingDie then
		-- Release the existing die first
		existingDie:SetAttribute("IsInCombat", false)
		existingDie:SetAttribute("LoadedInDiceBox", nil)
		print("Released existing die: " .. existingDie.Name)
	end

	-- Set the ObjectValue reference to point to this die
	local dieReference = InventoryManager.EnsureLoadedDieReference(loadedDieImage)
	dieReference.Value = die

	-- Store the die reference as an attribute as well for compatibility
	loadedDieImage:SetAttribute("LoadedDieName", die.Name)

	-- Mark the die as being used in combat
	die:SetAttribute("IsInCombat", true)
	die:SetAttribute("LoadedInDiceBox", loadedDieImage.Parent.Name)

	-- Set the background image if it exists
	local faceImage = die:GetAttribute("FaceImage") or ""
	if faceImage ~= "" then
		loadedDieImage.Image = faceImage
	else
		-- Try to find the image from the front face
		local frontFace = die:FindFirstChild("FrontFace")
		if frontFace then
			local imageLabel = frontFace:FindFirstChild("Image")
			if imageLabel and imageLabel:IsA("ImageLabel") then
				loadedDieImage.Image = imageLabel.Image
			end
		end
	end

	-- Apply the die's frame style to create bars, corners, and labels
	DiceUIUtils.ApplyDieFrameStyle(die, loadedDieImage)

	-- Make sure it's visible
	loadedDieImage.Visible = true

	-- Update the parent DiceBox to indicate it has a loaded die
	loadedDieImage.Parent:SetAttribute("HasLoadedDie", true)

	-- Refresh the inventory display if it's visible to update the labels
	if InventoryManager.UI.inventoryFrame.Visible then
		InventoryManager.PopulateInventory()
	end

	print("Loaded die " .. die.Name .. " into " .. loadedDieImage.Parent.Name)
end

-- Release a die from combat
function InventoryManager.ReleaseDie(loadedDie)
	local die = InventoryManager.GetDieFromLoadedDie(loadedDie)
	if die then
		die:SetAttribute("IsInCombat", false)
		die:SetAttribute("LoadedInDiceBox", nil)
		print("Released die from combat")

		-- Refresh the inventory display if it's visible to update the labels
		if InventoryManager.UI.inventoryFrame.Visible then
			InventoryManager.PopulateInventory()
		end
	end

	-- Clear the LoadedDie reference
	local dieRef = loadedDie:FindFirstChild("DieReference")
	if dieRef and dieRef:IsA("ObjectValue") then
		dieRef.Value = nil
	end

	-- Create an empty die appearance
	DiceUIUtils.CreateEmptyDieAppearance(loadedDie)

	-- Update the parent DiceBox
	loadedDie.Parent:SetAttribute("HasLoadedDie", false)
end

-- Populate the inventory UI with dice
function InventoryManager.PopulateInventory()
	local scrollingFrame = InventoryManager.UI.scrollingFrame
	scrollingFrame:ClearAllChildren()

	local diceInventory = InventoryManager.GetInventory()
	if not diceInventory then
		print("DiceInventory folder not found")
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, -20, 0, 40)
		noItemsLabel.Position = UDim2.new(0, 10, 0, 10)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No dice in inventory. Collect dice from spawners!"
		noItemsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		noItemsLabel.Font = Enum.Font.GothamBold
		noItemsLabel.TextSize = 18
		noItemsLabel.Parent = scrollingFrame
		return
	end

	local yOffset = 10
	local diceCount = 0

	for _, die in ipairs(diceInventory:GetChildren()) do
		-- Include all dice, but track if they're in combat
		local isInCombat = die:GetAttribute("IsInCombat") == true
		local loadedLocation = die:GetAttribute("LoadedInDiceBox")

		-- Create a frame for this die
		local dieFrame = Instance.new("TextButton")
		dieFrame.Size = UDim2.new(1, -20, 0, 100)
		dieFrame.Position = UDim2.new(0, 10, 0, yOffset)
		dieFrame.BackgroundTransparency = 0.2
		dieFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		dieFrame.BorderSizePixel = 1
		dieFrame.Text = ""
		dieFrame.Parent = scrollingFrame

		-- Die Information Labels
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, 200, 0, 20)
		nameLabel.Position = UDim2.new(0, 100, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = die.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 18
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = dieFrame

		local specialLabel = Instance.new("TextLabel")
		specialLabel.Size = UDim2.new(0, 200, 0, 20)
		specialLabel.Position = UDim2.new(0, 100, 0, 30)
		specialLabel.BackgroundTransparency = 1
		specialLabel.Text = "Special: " .. (die:GetAttribute("Special") or "None")
		specialLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		specialLabel.Font = Enum.Font.Gotham
		specialLabel.TextSize = 16
		specialLabel.TextXAlignment = Enum.TextXAlignment.Left
		specialLabel.Parent = dieFrame

		-- Add "Loaded" indicator if the die is in combat
		if isInCombat then
			local loadedIndicator = Instance.new("Frame")
			loadedIndicator.Size = UDim2.new(0, 120, 0, 40)
			loadedIndicator.Position = UDim2.new(1, -130, 0.5, -20)

			-- Set color based on whether it's loaded in the player or enemy slot
			if loadedLocation and string.find(loadedLocation, "Player") then
				loadedIndicator.BackgroundColor3 = Color3.fromRGB(0, 100, 255) -- Blue for player
			elseif loadedLocation and string.find(loadedLocation, "Enemy") then
				loadedIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red for enemy
			else
				loadedIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray for unknown
			end

			loadedIndicator.BorderSizePixel = 2
			loadedIndicator.Parent = dieFrame

			-- Determine the label text based on location
			local labelText = "Loaded"
			if loadedLocation then
				if string.find(loadedLocation, "Player") then
					labelText = "Loaded Player"
				elseif string.find(loadedLocation, "Enemy") then
					labelText = "Loaded Enemy"
				end
			end

			local loadedLabel = Instance.new("TextLabel")
			loadedLabel.Size = UDim2.new(1, 0, 1, 0)
			loadedLabel.Position = UDim2.new(0, 0, 0, 0)
			loadedLabel.BackgroundTransparency = 1
			loadedLabel.Text = labelText
			loadedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			loadedLabel.Font = Enum.Font.GothamBold
			loadedLabel.TextSize = 16
			loadedLabel.Parent = loadedIndicator
		end

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0, 300, 0, 40)
		statsLabel.Position = UDim2.new(0, 100, 0, 50)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = string.format(
			"ATK: %d  DEF: %d  HEAL: %d  ELE: %d",
			die:GetAttribute("Attack") or 0,
			die:GetAttribute("Defense") or 0,
			die:GetAttribute("Healing") or 0,
			die:GetAttribute("Elemental") or 0
		)
		statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		statsLabel.Font = Enum.Font.Gotham
		statsLabel.TextSize = 16
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = dieFrame

		-- Create die preview with proper frame styling
		local previewContainer = Instance.new("ImageButton")
		previewContainer.Size = UDim2.new(0, 80, 0, 80)
		previewContainer.Position = UDim2.new(0, 10, 0, 10)
		previewContainer.BackgroundTransparency = 1
		previewContainer.Parent = dieFrame

		-- Set the preview image
		local faceImage = die:GetAttribute("FaceImage") or ""
		if faceImage ~= "" then
			previewContainer.Image = faceImage
		else
			-- Try to find the image from the front face
			local frontFace = die:FindFirstChild("FrontFace")
			if frontFace then
				local imageLabel = frontFace:FindFirstChild("Image")
				if imageLabel and imageLabel:IsA("ImageLabel") then
					previewContainer.Image = imageLabel.Image
				end
			end
		end

		-- Apply the die's frame style to the preview
		DiceUIUtils.ApplyDieFrameStyle(die, previewContainer)

		-- Add click functionality to both the frame and the preview
		-- Only allow selection if the die isn't already in combat
		-- or if we're specifically trying to replace the die that's already loaded
		dieFrame.MouseButton1Click:Connect(function()
			local canBeSelected = not isInCombat
				or (InventoryManager.State.targetLoadedDie 
					and loadedLocation == InventoryManager.State.targetLoadedDie.Parent.Name)

			if InventoryManager.State.targetLoadedDie and canBeSelected then
				InventoryManager.LoadDieIntoSlot(die, InventoryManager.State.targetLoadedDie)
				InventoryManager.UI.inventoryFrame.Visible = false
				InventoryManager.State.targetLoadedDie = nil
			elseif isInCombat then
				-- Show a notification that this die is already loaded
				local notification = Instance.new("TextLabel")
				notification.Size = UDim2.new(0, 300, 0, 50)
				notification.Position = UDim2.new(0.5, -150, 0.1, 0)
				notification.Text = "This die is already loaded in " .. (loadedLocation or "combat")
				notification.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
				notification.TextColor3 = Color3.fromRGB(255, 255, 255)
				notification.TextSize = 16
				notification.Parent = InventoryManager.UI.screenGui

				game:GetService("Debris"):AddItem(notification, 2) -- Remove after 2 seconds
			end
		end)

		previewContainer.MouseButton1Click:Connect(function()
			local canBeSelected = not isInCombat
				or (InventoryManager.State.targetLoadedDie 
					and loadedLocation == InventoryManager.State.targetLoadedDie.Parent.Name)

			if InventoryManager.State.targetLoadedDie and canBeSelected then
				InventoryManager.LoadDieIntoSlot(die, InventoryManager.State.targetLoadedDie)
				InventoryManager.UI.inventoryFrame.Visible = false
				InventoryManager.State.targetLoadedDie = nil
			elseif isInCombat then
				-- Show a notification that this die is already loaded
				local notification = Instance.new("TextLabel")
				notification.Size = UDim2.new(0, 300, 0, 50)
				notification.Position = UDim2.new(0.5, -150, 0.1, 0)
				notification.Text = "This die is already loaded in " .. (loadedLocation or "combat")
				notification.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
				notification.TextColor3 = Color3.fromRGB(255, 255, 255)
				notification.TextSize = 16
				notification.Parent = InventoryManager.UI.screenGui

				game:GetService("Debris"):AddItem(notification, 2) -- Remove after 2 seconds
			end
		end)

		yOffset = yOffset + 110
		diceCount = diceCount + 1
	end

	if diceCount == 0 then
		-- No dice found, add a message
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(1, -20, 0, 40)
		noItemsLabel.Position = UDim2.new(0, 10, 0, 10)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No dice in inventory. Collect dice from spawners!"
		noItemsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		noItemsLabel.Font = Enum.Font.GothamBold
		noItemsLabel.TextSize = 18
		noItemsLabel.Parent = scrollingFrame
	end

	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(yOffset, 200))
	print("Populated inventory with " .. diceCount .. " dice")
end

-- Set the target die slot for loading
function InventoryManager.SetTargetLoadedDie(loadedDie)
	InventoryManager.State.targetLoadedDie = loadedDie
	InventoryManager.UI.inventoryFrame.Visible = true
	InventoryManager.PopulateInventory()
end

-- Start combat between two dice
-- Start combat between two dice
function InventoryManager.StartCombat(playerLoadedDie, enemyLoadedDie)
	-- Get the actual die objects
	local playerDie = InventoryManager.GetDieFromLoadedDie(playerLoadedDie)
	local enemyDie = InventoryManager.GetDieFromLoadedDie(enemyLoadedDie)

	if playerDie and enemyDie then
		print("Starting combat between " .. playerDie.Name .. " and " .. enemyDie.Name)

		-- Pre-combat cleanup - make sure dice aren't already flagged
		if playerDie:GetAttribute("IsInCombat") then
			playerDie:SetAttribute("IsInCombat", false)
		end

		if enemyDie:GetAttribute("IsInCombat") then
			enemyDie:SetAttribute("IsInCombat", false)
		end

		-- Now start the combat
		CombatModule.BeginCombat(playerDie, enemyDie)
		return true
	else
		-- Provide feedback about missing dice
		local message = "Please select dice for "
		if not playerDie and not enemyDie then
			message = message .. "both player and enemy!"
		elseif not playerDie then
			message = message .. "the player!"
		else
			message = message .. "the enemy!"
		end
		print(message)

		-- Return false to indicate combat couldn't start
		return false, message
	end
end

return InventoryManager
