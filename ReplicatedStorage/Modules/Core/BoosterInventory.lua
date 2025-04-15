-- /ReplicatedStorage/Modules/Core/BoosterInventory.lua
-- ModuleScript that handles populating and managing the booster inventory UI

local BoosterInventory = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)
local Stat = require(ReplicatedStorage.Stat)

-- Constants
local SLOT_HEIGHT = 100 -- Height of each booster slot
local SLOT_PADDING = 10 -- Padding between slots

-- Cache
local player = Players.LocalPlayer
local mainUI = nil -- Will be set in Initialize
local contentFrame = nil -- Reference to the Content frame
local boostersFrame = nil -- Reference to the BoosterInventory frame
local boostersContainer = nil -- Reference to the Boosters container inside BoosterInventory
local template = nil -- Reference to the Template

-- Use a metadata table to store button connections instead of attributes
local buttonConnections = {}

-- Helper function to clean up connections for a button
local function cleanupButtonConnection(button)
	if buttonConnections[button] then
		buttonConnections[button]:Disconnect()
		buttonConnections[button] = nil
	end
end

-- Private functions

-- Update a booster slot with the given data
local function UpdateBoosterSlot(boosterSlot, boosterName, count, spendingValue)
	-- Get the booster info from the Boosters module
	local boosterInfo = Boosters.Items[boosterName]
	if not boosterInfo then
		warn("Booster info not found for: " .. boosterName)
		return boosterSlot
	end

	-- Update name and description if they exist
	local nameLabel = boosterSlot:FindFirstChild("Name")
	if nameLabel then
		nameLabel.Text = boosterInfo.name or boosterName
	end

	local descLabel = boosterSlot:FindFirstChild("Description")
	if descLabel then
		descLabel.Text = boosterInfo.description or ""
	end

	-- Update image if available
	local imageFrame = boosterSlot:FindFirstChild("Image")
	if imageFrame and boosterInfo.imageId then
		imageFrame.Image = boosterInfo.imageId
	end

	-- Set count display (total - spending)
	local countLabel = boosterSlot:FindFirstChild("Count")
	if countLabel then
		countLabel.Text = tostring(count - spendingValue)
	end

	-- Set spending value
	local spendingLabel = boosterSlot:FindFirstChild("Controls"):FindFirstChild("Spending")
	if spendingLabel then
		spendingLabel.Text = tostring(spendingValue)
	end

	-- Set up control buttons
	local controls = boosterSlot:FindFirstChild("Controls")
	if controls then
		-- MinusOne button
		local minusOneBtn = controls:FindFirstChild("MinusOne")
		if minusOneBtn then
			-- Clean up previous connection
			cleanupButtonConnection(minusOneBtn)

			-- New connection
			local connection = minusOneBtn.MouseButton1Click:Connect(function()
				-- Get current spending
				local currentSpending = tonumber(spendingLabel.Text) or 0
				if currentSpending > 0 then
					-- Decrease spending by 1
					local newSpending = currentSpending - 1
					spendingLabel.Text = tostring(newSpending)

					-- Update count display
					if countLabel then
						countLabel.Text = tostring(count - newSpending)
					end
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[minusOneBtn] = connection
		end

		-- PlusOne button
		local plusOneBtn = controls:FindFirstChild("PlusOne")
		if plusOneBtn then
			-- Clean up previous connection
			cleanupButtonConnection(plusOneBtn)

			-- New connection
			local connection = plusOneBtn.MouseButton1Click:Connect(function()
				-- Get current spending
				local currentSpending = tonumber(spendingLabel.Text) or 0
				if currentSpending < count then
					-- Increase spending by 1
					local newSpending = currentSpending + 1
					spendingLabel.Text = tostring(newSpending)

					-- Update count display
					if countLabel then
						countLabel.Text = tostring(count - newSpending)
					end
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[plusOneBtn] = connection
		end

		-- MinusAll button
		local minusAllBtn = controls:FindFirstChild("MinusAll")
		if minusAllBtn then
			-- Clean up previous connection
			cleanupButtonConnection(minusAllBtn)

			-- New connection
			local connection = minusAllBtn.MouseButton1Click:Connect(function()
				-- Set spending to 0
				spendingLabel.Text = "0"

				-- Update count display
				if countLabel then
					countLabel.Text = tostring(count)
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[minusAllBtn] = connection
		end

		-- PlusAll button
		local plusAllBtn = controls:FindFirstChild("PlusAll")
		if plusAllBtn then
			-- Clean up previous connection
			cleanupButtonConnection(plusAllBtn)

			-- New connection
			local connection = plusAllBtn.MouseButton1Click:Connect(function()
				-- Set spending to total count
				spendingLabel.Text = tostring(count)

				-- Update count display
				if countLabel then
					countLabel.Text = "0"
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[plusAllBtn] = connection
		end

		-- Use button
		local useBtn = controls:FindFirstChild("Use")
		if useBtn then
			-- Clean up previous connection
			cleanupButtonConnection(useBtn)

			-- New connection
			local connection = useBtn.MouseButton1Click:Connect(function()
				-- Get current spending
				local currentSpending = tonumber(spendingLabel.Text) or 0
				if currentSpending <= 0 then return end

				-- Call the booster's onActivate function if it exists and we're on the server
				local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
				if boosterEvents then
					local useBoosterEvent = boosterEvents:FindFirstChild("UseBooster")
					if useBoosterEvent then
						-- THE FIX: Explicitly convert the spending text to a number
						local spendingAmount = tonumber(spendingLabel.Text) or 0

						-- Fire event to server to use the booster with the explicit amount
						print("Sending UseBooster event with name:", boosterName, "and quantity:", spendingAmount)
						useBoosterEvent:FireServer(boosterName, spendingAmount)

						-- Update the spending value to min(previousSpending, newTotal)
						local newTotal = count - currentSpending
						local newSpending = math.min(currentSpending, newTotal)
						spendingLabel.Text = tostring(newSpending)

						-- Update count display
						if countLabel then
							countLabel.Text = newTotal
						end
					else
						warn("UseBooster event not found in BoosterEvents")
					end
				else
					warn("BoosterEvents folder not found in ReplicatedStorage")
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[useBtn] = connection
		end
	end

	return boosterSlot
end

-- Public functions

-- Initialize the module with references to UI elements
function BoosterInventory.Initialize(menuUI)
	print("BoosterInventory.Initialize called with UI:", menuUI.Name)

	mainUI = menuUI

	-- Find the Main frame within Menu
	local mainFrame = menuUI:FindFirstChild("Main")
	if not mainFrame then
		warn("Main frame not found in Menu")
		return
	end

	-- Find the Content frame within Main
	contentFrame = mainFrame:FindFirstChild("Content")
	if not contentFrame then
		warn("Content frame not found in Main")
		return
	end

	-- Find the BoosterInventory frame within Content
	boostersFrame = contentFrame:FindFirstChild("BoosterInventory")
	if not boostersFrame then
		warn("BoosterInventory frame not found in Content")
		return
	end

	-- Find the Boosters container within BoosterInventory
	boostersContainer = boostersFrame:FindFirstChild("Boosters")
	if not boostersContainer then
		warn("Boosters container not found in BoosterInventory")
		return
	end

	-- Find the Template within Boosters container (it might be stored in an ObjectValue)
	local templateValue = boostersContainer:FindFirstChild("Template")
	if templateValue and templateValue:IsA("ObjectValue") then
		template = templateValue.Value
	else
		-- Try to find the template directly
		template = boostersContainer:FindFirstChild("BoosterTemplate")
		if not template then
			warn("Template not found in Boosters container")
			return
		end
	end

	-- Make sure Template is invisible
	template.Visible = false

	-- Set up the event to refresh UI when booster counts change
	local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
	if boosterEvents then
		local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
		if activatedEvent then
			activatedEvent.OnClientEvent:Connect(function(boosterName, expirationTime)
				BoosterInventory.Refresh()
			end)
		end

		local deactivatedEvent = boosterEvents:FindFirstChild("BoosterDeactivated")
		if deactivatedEvent then
			deactivatedEvent.OnClientEvent:Connect(function(boosterName)
				BoosterInventory.Refresh()
			end)
		end
	end

	print("BoosterInventory initialization complete")
	return BoosterInventory
end

-- Populate the inventory with booster slots
function BoosterInventory.Populate()
	if not player or not mainUI or not boostersContainer or not template then
		warn("BoosterInventory not properly initialized. Call Initialize first.")
		return 0
	end

	-- Clean up existing connections before removing slots
	for button, connection in pairs(buttonConnections) do
		if button and connection then
			connection:Disconnect()
		end
	end
	buttonConnections = {}

	-- Clear existing booster slots (except the template)
	for _, child in ipairs(boostersContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= template and child:GetAttribute("IsTemplate") ~= true then
			child:Destroy()
		end
	end

	-- Get player's boosters from Stat module (source of truth)
	local boosterCounts = {}
	local spendingValues = {}
	local count = 0

	-- Iterate through all defined boosters in the Boosters module
	for boosterName in pairs(Boosters.Items) do
		local boosterStat = Stat.Get(player, boosterName)
		if boosterStat and boosterStat.Value > 0 then
			boosterCounts[boosterName] = boosterStat.Value
			spendingValues[boosterName] = 0
			count = count + 1
		end
	end

	-- Get or create a UIGridLayout to organize the slots
	local gridLayout = boostersContainer:FindFirstChild("BoosterLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Name = "BoosterLayout"
		gridLayout.CellSize = UDim2.new(0.5, -5, 0, SLOT_HEIGHT)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.SortOrder = Enum.SortOrder.Name
		gridLayout.Parent = boostersContainer
	end

	-- Create slots for each booster with count > 0
	for boosterName, boosterCount in pairs(boosterCounts) do
		-- Clone the template
		local newSlot = template:Clone()
		newSlot.Name = "BoosterSlot_" .. boosterName
		newSlot.Visible = true
		newSlot:SetAttribute("IsTemplate", false)
		newSlot:SetAttribute("BoosterName", boosterName)

		-- Update the slot with booster info
		UpdateBoosterSlot(newSlot, boosterName, boosterCount, spendingValues[boosterName])

		-- Parent to the container
		newSlot.Parent = boostersContainer
	end

	-- Update canvas size if using a ScrollingFrame
	if boostersContainer:IsA("ScrollingFrame") then
		local rows = math.ceil(count / 2) -- Assuming 2 columns in grid
		boostersContainer.CanvasSize = UDim2.new(0, 0, 0, rows * (SLOT_HEIGHT + SLOT_PADDING))
	end

	return count
end

-- Refresh the booster inventory
function BoosterInventory.Refresh()
	return BoosterInventory.Populate()
end

-- Cleanup function to disconnect events
function BoosterInventory.Cleanup()
	-- Clean up all stored connections
	--for button, connection in pairs(buttonConnections) do
	--	if button and connection then
	--		connection:Disconnect()
	--	end
	--end
	buttonConnections = {}
end

return BoosterInventory
