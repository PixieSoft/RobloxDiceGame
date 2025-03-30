-- /StarterGui/DiceInventory/DiceInventoryUI
-- Main script that creates and manages the inventory UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Require our modules
local success, InventoryManager = pcall(function()
	return require(script.Parent:WaitForChild("InventoryManager"))
end)

if not success then
	warn("Failed to require InventoryManager: " .. InventoryManager)
	-- Create a temporary stub module to prevent errors
	InventoryManager = {
		Initialize = function() end,
		PopulateInventory = function() end,
		EnsureLoadedDieReference = function() return Instance.new("ObjectValue") end,
		SetTargetLoadedDie = function() end,
		ReleaseDie = function() end,
		StartCombat = function() return false, "Module failed to load" end,
		State = {targetLoadedDie = nil}
	}
end

-- Print statement to confirm script execution
print("DiceInventoryUI script started")

-- Create the UI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DiceInventoryUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create Inventory Button (always visible)
local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Size = UDim2.new(0, 150, 0, 50)
inventoryButton.Position = UDim2.new(1, -170, 1, -70)
inventoryButton.Text = "Inventory"
inventoryButton.TextSize = 24
inventoryButton.Font = Enum.Font.GothamBold
inventoryButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
inventoryButton.BorderSizePixel = 2
inventoryButton.Parent = screenGui

-- Create Fight Button (always visible)
local fightButton = Instance.new("TextButton")
fightButton.Name = "FightButton"
fightButton.Size = UDim2.new(0, 150, 0, 50)
fightButton.Position = UDim2.new(1, -170, 1, -130)
fightButton.Text = "Fight"
fightButton.TextSize = 24
fightButton.Font = Enum.Font.GothamBold
fightButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
fightButton.BorderSizePixel = 2
fightButton.Parent = screenGui

-- Create Inventory Frame (hidden by default)
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
inventoryFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
inventoryFrame.BackgroundTransparency = 0.2
inventoryFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
inventoryFrame.BorderSizePixel = 2
inventoryFrame.Visible = false
inventoryFrame.Parent = screenGui

-- Create title for inventory frame
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "Dice Inventory"
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.Parent = inventoryFrame

-- Create close button for inventory frame
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.Text = "X"
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.Parent = inventoryFrame

-- Create Scrollable Frame for inventory items
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "ScrollingFrame"
scrollingFrame.Size = UDim2.new(1, 0, 1, -30)
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Will be adjusted dynamically
scrollingFrame.ScrollBarThickness = 10
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.Parent = inventoryFrame

-- Create a loading message (will be hidden when everything is ready)
local loadingMessage = Instance.new("TextLabel")
loadingMessage.Name = "LoadingMessage"
loadingMessage.Size = UDim2.new(0, 300, 0, 50)
loadingMessage.Position = UDim2.new(0.5, -150, 0.5, -25)
loadingMessage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
loadingMessage.BackgroundTransparency = 0.5
loadingMessage.BorderSizePixel = 2
loadingMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingMessage.Text = "Loading combat interface..."
loadingMessage.TextSize = 20
loadingMessage.Parent = screenGui

print("DiceInventoryUI basic elements created")

-- Initialize the inventory manager with our UI elements
InventoryManager.Initialize(screenGui, inventoryFrame, scrollingFrame)

-- Reference to Interface elements (will be populated after they load)
local Interface, Combat, DiceBoxPlayer, DiceBoxEnemy
local playerLoadedDie, enemyLoadedDie

-- Wait for the Interface to load (may be created by another script)
task.spawn(function()
	local attempts = 0
	local maxAttempts = 10

	while attempts < maxAttempts do
		attempts = attempts + 1
		print("Looking for combat interface (attempt " .. attempts .. "/" .. maxAttempts .. ")")

		-- Try to find the interface elements
		Interface = playerGui:FindFirstChild("Interface")
		if Interface then
			Combat = Interface:FindFirstChild("Combat")
			if Combat then
				DiceBoxPlayer = Combat:FindFirstChild("DiceBoxPlayer")
				DiceBoxEnemy = Combat:FindFirstChild("DiceBoxEnemy")

				if DiceBoxPlayer and DiceBoxEnemy then
					playerLoadedDie = DiceBoxPlayer:FindFirstChild("LoadedDie")
					enemyLoadedDie = DiceBoxEnemy:FindFirstChild("LoadedDie")

					if playerLoadedDie and enemyLoadedDie then
						-- All references found
						print("Found all combat UI elements")
						loadingMessage.Visible = false

						-- Set up references for dice
						InventoryManager.EnsureLoadedDieReference(playerLoadedDie)
						InventoryManager.EnsureLoadedDieReference(enemyLoadedDie)

						-- Connect LoadedDie clicks
						playerLoadedDie.MouseButton1Click:Connect(function()
							print("Player LoadedDie clicked")
							InventoryManager.SetTargetLoadedDie(playerLoadedDie)
						end)

						enemyLoadedDie.MouseButton1Click:Connect(function()
							print("Enemy LoadedDie clicked")
							InventoryManager.SetTargetLoadedDie(enemyLoadedDie)
						end)

						-- Also connect DiceBox buttons if they exist
						local playerDiceButton = DiceBoxPlayer:FindFirstChild("Dice")
						local enemyDiceButton = DiceBoxEnemy:FindFirstChild("Dice")

						if playerDiceButton then
							playerDiceButton.MouseButton1Click:Connect(function()
								print("Player Dice button clicked")
								InventoryManager.SetTargetLoadedDie(playerLoadedDie)
							end)
						end

						if enemyDiceButton then
							enemyDiceButton.MouseButton1Click:Connect(function()
								print("Enemy Dice button clicked")
								InventoryManager.SetTargetLoadedDie(enemyLoadedDie)
							end)
						end

						-- Connect right-click to release
						playerLoadedDie.MouseButton2Click:Connect(function()
							print("Player LoadedDie right-clicked")
							InventoryManager.ReleaseDie(playerLoadedDie)
						end)

						enemyLoadedDie.MouseButton2Click:Connect(function()
							print("Enemy LoadedDie right-clicked")
							InventoryManager.ReleaseDie(enemyLoadedDie)
						end)

						print("DiceInventoryUI setup complete")
						break
					end
				end
			end
		end

		-- If we reach here, some elements are still missing
		if attempts == maxAttempts then
			-- Show error message instead of loading
			loadingMessage.Text = "Combat UI not found. Are all scripts running?"
			loadingMessage.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			print("Failed to find combat UI elements after " .. maxAttempts .. " attempts")
		else
			-- Wait and try again
			task.wait(1)
		end
	end
end)

-- Set up button click handlers
inventoryButton.MouseButton1Click:Connect(function()
	print("Inventory button clicked")
	inventoryFrame.Visible = not inventoryFrame.Visible
	if inventoryFrame.Visible then
		InventoryManager.PopulateInventory()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	print("Inventory close button clicked")
	inventoryFrame.Visible = false
	InventoryManager.State.targetLoadedDie = nil
end)

fightButton.MouseButton1Click:Connect(function()
	print("Fight button clicked")
	-- Check if we have references to the LoadedDie elements
	if not playerLoadedDie or not enemyLoadedDie then
		print("Combat UI elements not fully loaded yet")
		return
	end

	-- Start combat between the two dice
	local success, errorMessage = InventoryManager.StartCombat(playerLoadedDie, enemyLoadedDie)

	if not success and errorMessage then
		-- Create a visual notification for the error
		local notification = Instance.new("TextLabel")
		notification.Size = UDim2.new(0, 300, 0, 50)
		notification.Position = UDim2.new(0.5, -150, 0.1, 0)
		notification.Text = errorMessage
		notification.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		notification.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification.TextSize = 20
		notification.Parent = screenGui

		game:GetService("Debris"):AddItem(notification, 3) -- Remove after 3 seconds
	end
end)

print("DiceInventoryUI initialization complete")
