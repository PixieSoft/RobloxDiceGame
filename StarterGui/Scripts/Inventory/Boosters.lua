-- /StarterGui/Inventory/Boosters.lua
-- LocalScript that initializes and manages the booster inventory UI
-- This script connects to the BoosterInventory module to populate the UI with booster slots

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the player
local player = Players.LocalPlayer

-- First, let's make sure we have the module loaded
local BoosterInventory
local success, result = pcall(function()
	-- Updated path - now looking in ReplicatedStorage instead of ServerScriptService
	return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("BoosterInventory"))
end)

if not success then
	warn("Failed to load BoosterInventory module: " .. tostring(result))
	return
end
BoosterInventory = result

-- Wait for player data to load
local leaderstats
local function waitForPlayerData()
	-- Wait for leaderstats to load
	leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("Leaderstats not found after 10 seconds")
		return false
	end

	-- Wait for boosters folder to load
	local boostersFolder = leaderstats:WaitForChild("Boosters", 5)
	if not boostersFolder then
		warn("Boosters folder not found in leaderstats")
		return false
	end

	return true
end

-- Wait for UI to load
local mainUI = script.Parent
local content = mainUI:WaitForChild("Content")
local boosterContainer = content:WaitForChild("Boosters")

-- Make sure booster container starts hidden
boosterContainer.Visible = false

-- Initialize the module once the UI is loaded
BoosterInventory.Initialize(mainUI)

-- Function to show the inventory
local function ShowInventory()
	if not boosterContainer.Visible then
		-- Make sure player data is loaded before showing
		if not leaderstats and not waitForPlayerData() then
			warn("Cannot show inventory - player data not loaded")
			return
		end

		-- Show and populate
		boosterContainer.Visible = true
		BoosterInventory.Refresh()
	end
end

-- Function to hide the inventory
local function HideInventory()
	boosterContainer.Visible = false
end

-- Function to toggle the inventory
local function ToggleInventory()
	if boosterContainer.Visible then
		HideInventory()
	else
		ShowInventory()
	end
end

-- Find the inventory button in the corner of the screen
local function findInventoryButton()
	-- Try to find the inventory button in a few common places

	-- Method 1: Try to find in a dedicated UI
	for _, screenGui in pairs(player.PlayerGui:GetChildren()) do
		if screenGui:IsA("ScreenGui") then
			-- Look for a button named "Inventory" or similar
			for _, button in pairs(screenGui:GetDescendants()) do
				if (button:IsA("TextButton") or button:IsA("ImageButton")) and 
					(button.Name:lower():find("inventory") or 
						(button:IsA("TextButton") and button.Text:lower():find("inventory"))) then
					return button
				end
			end
		end
	end

	-- Method 2: Create a button if none is found
	local screenGui = player.PlayerGui:FindFirstChild("InventoryButtonGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "InventoryButtonGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = player.PlayerGui

		local button = Instance.new("TextButton")
		button.Name = "InventoryButton"
		button.Text = "Inventory"
		button.Size = UDim2.new(0, 100, 0, 40)
		button.Position = UDim2.new(1, -110, 1, -50) -- Bottom right corner
		button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.Parent = screenGui

		-- Add rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		return button
	end

	return nil
end

-- Wait a short time for everything to load, then connect to button
task.delay(1, function()
	-- First check if player data is loaded
	if not leaderstats then
		if not waitForPlayerData() then
			warn("Player data failed to load")
		end
	end

	-- Find or create the inventory button
	local inventoryButton = findInventoryButton()
	if inventoryButton then
		inventoryButton.MouseButton1Click:Connect(ToggleInventory)
	else
		warn("Could not find or create inventory button")
	end
end)

-- Listen for booster updates from server
local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
if boosterEvents then
	local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated") 
	if activatedEvent then
		activatedEvent.OnClientEvent:Connect(function()
			if boosterContainer.Visible then
				BoosterInventory.Refresh()
			end
		end)
	end
end

-- Auto-connect new boosters when added
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		leaderstats = child
		child.ChildAdded:Connect(function(statsChild)
			if statsChild.Name == "Boosters" then
				-- Connect to changes
				statsChild.ChildAdded:Connect(function()
					if boosterContainer.Visible then
						BoosterInventory.Refresh()
					end
				end)

				statsChild.ChildRemoved:Connect(function()
					if boosterContainer.Visible then
						BoosterInventory.Refresh()
					end
				end)
			end
		end)
	end
end)
