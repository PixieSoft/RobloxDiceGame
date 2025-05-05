-- /ReplicatedStorage/Modules/Core/BoosterInventory.lua
-- ModuleScript that handles populating and managing the booster inventory UI

local BoosterInventory = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)
local Stat = require(ReplicatedStorage.Stat)
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Debug settings
local debugSystem = "BoosterInventory"

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

-- Info panel references
local infoPanel = nil -- Reference to the UsageInfo frame
local infoDescLabel = nil -- Reference to the description label
local infoEffectLabel = nil -- Reference to the effect label

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

-- Update the UsageInfo panel with information about the selected booster
local function UpdateUsageInfo(boosterName, spendingAmount)
	-- Check if info panel references exist
	if not infoPanel or not infoDescLabel or not infoEffectLabel then
		return
	end

	-- Get the booster info from the Boosters module
	local boosterInfo = Boosters.Items[boosterName]
	if not boosterInfo then
		infoDescLabel.Text = "No information available"
		infoEffectLabel.Text = ""
		return
	end

	-- Update description label with "BoosterName: Description" format
	local boosterDisplayName = boosterInfo.name or boosterName
	infoDescLabel.Text = boosterDisplayName .. ": " .. (boosterInfo.description or "No description available")

	-- Use the booster's calculateEffect function if available, otherwise use fallback
	local effectText = ""
	if boosterInfo.calculateEffect then
		-- Use the booster's custom effect calculator
		effectText = boosterInfo.calculateEffect(spendingAmount)
	else
		-- Fallback for boosters without a calculator
		if spendingAmount <= 0 then
			effectText = "Select quantity to use"
		else
			local plural = spendingAmount > 1 and "s" or ""

			if boosterInfo.duration then
				local totalDuration = boosterInfo.duration * spendingAmount
				local minutes = math.floor(totalDuration / 60)
				local seconds = totalDuration % 60

				if minutes > 0 then
					effectText = "Effect: " .. spendingAmount .. " " .. (boosterInfo.name or boosterName) .. plural .. " for " ..
						minutes .. "m " .. seconds .. "s"
				else
					effectText = "Effect: " .. spendingAmount .. " " .. (boosterInfo.name or boosterName) .. plural .. " for " ..
						seconds .. "s"
				end
			else
				effectText = "Effect: Use " .. spendingAmount .. " " .. (boosterInfo.name or boosterName) .. plural
			end
		end
	end

	infoEffectLabel.Text = effectText
end

-- Update a booster slot with the given data
local function UpdateBoosterSlot(boosterSlot, boosterName, count, spendingValue)
	-- Get the booster info from the Boosters module
	local boosterInfo = Boosters.Items[boosterName]
	if not boosterInfo then
		Utility.Log(debugSystem, "warn", "Booster info not found for: " .. boosterName)
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

					-- Update the info panel
					UpdateUsageInfo(boosterName, newSpending)
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

					-- Update the info panel
					UpdateUsageInfo(boosterName, newSpending)
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

				-- Update the info panel
				UpdateUsageInfo(boosterName, 0)
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

				-- Update the info panel
				UpdateUsageInfo(boosterName, count)
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
						-- Get the spending amount (explicitly convert to number)
						local spendingAmount = tonumber(spendingLabel.Text) or 0

						-- Fire event to server to use the booster with the explicit amount
						-- Do NOT update the UI here - let the server stat changes trigger the update
						Utility.Log(debugSystem, "info", "Sending UseBooster event with name: " .. boosterName .. " and quantity: " .. spendingAmount)
						useBoosterEvent:FireServer(boosterName, spendingAmount)

						-- Reset spending value to 0 after sending the event
						spendingLabel.Text = "0"

						-- Update the info panel
						UpdateUsageInfo(boosterName, 0)
					else
						Utility.Log(debugSystem, "warn", "UseBooster event not found in BoosterEvents")
					end
				else
					Utility.Log(debugSystem, "warn", "BoosterEvents folder not found in ReplicatedStorage")
				end
			end)

			-- Store connection in the metadata table
			buttonConnections[useBtn] = connection
		end
	end

	-- Initialize info panel with this booster's info if it's the first one
	if boosterSlot:GetAttribute("IsFirstBooster") or 
		(boosterSlot:GetAttribute("BoosterName") == boosterName and spendingValue > 0) then
		UpdateUsageInfo(boosterName, spendingValue)
	end

	return boosterSlot
end

-- Public functions

-- Initialize the module with references to UI elements
function BoosterInventory.Initialize(menuUI)
	Utility.Log(debugSystem, "info", "BoosterInventory.Initialize called with UI: " .. menuUI.Name)

	mainUI = menuUI

	-- Find the Main frame within Menu
	local mainFrame = menuUI:FindFirstChild("Main")
	if not mainFrame then
		Utility.Log(debugSystem, "warn", "Main frame not found in Menu")
		return
	end

	-- Find the Content frame within Main
	contentFrame = mainFrame:FindFirstChild("Content")
	if not contentFrame then
		Utility.Log(debugSystem, "warn", "Content frame not found in Main")
		return
	end

	-- Find the BoosterInventory frame within Content
	boostersFrame = contentFrame:FindFirstChild("BoosterInventory")
	if not boostersFrame then
		Utility.Log(debugSystem, "warn", "BoosterInventory frame not found in Content")
		return
	end

	-- Find the Boosters container within BoosterInventory
	boostersContainer = boostersFrame:FindFirstChild("Boosters")
	if not boostersContainer then
		Utility.Log(debugSystem, "warn", "Boosters container not found in BoosterInventory")
		return
	end

	-- Find the UsageInfo panel
	infoPanel = boostersFrame:FindFirstChild("UsageInfo")
	if infoPanel then
		infoDescLabel = infoPanel:FindFirstChild("DescLabel")
		infoEffectLabel = infoPanel:FindFirstChild("EffectLabel")

		if not infoDescLabel then
			Utility.Log(debugSystem, "warn", "DescLabel not found in UsageInfo")
		end

		if not infoEffectLabel then
			Utility.Log(debugSystem, "warn", "EffectLabel not found in UsageInfo")
		end
	else
		Utility.Log(debugSystem, "warn", "UsageInfo panel not found in BoosterInventory")
	end

	-- Find the Template within Boosters container (it might be stored in an ObjectValue)
	local templateValue = boostersContainer:FindFirstChild("Template")
	if templateValue and templateValue:IsA("ObjectValue") then
		template = templateValue.Value
	else
		-- Try to find the template directly
		template = boostersContainer:FindFirstChild("BoosterTemplate")
		if not template then
			Utility.Log(debugSystem, "warn", "Template not found in Boosters container")
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

	Utility.Log(debugSystem, "info", "BoosterInventory initialization complete")
	return BoosterInventory
end

-- Populate the inventory with booster slots
function BoosterInventory.Populate()
	if not player or not mainUI or not boostersContainer or not template then
		Utility.Log(debugSystem, "warn", "BoosterInventory not properly initialized. Call Initialize first.")
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
	local firstBooster = true
	for boosterName, boosterCount in pairs(boosterCounts) do
		-- Clone the template
		local newSlot = template:Clone()
		newSlot.Name = "BoosterSlot_" .. boosterName
		newSlot.Visible = true
		newSlot:SetAttribute("IsTemplate", false)
		newSlot:SetAttribute("BoosterName", boosterName)

		-- Mark the first booster to update the info panel
		if firstBooster then
			newSlot:SetAttribute("IsFirstBooster", true)
			firstBooster = false
		else
			newSlot:SetAttribute("IsFirstBooster", false)
		end

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

	-- If no boosters were populated, clear the info panel
	if count == 0 and infoDescLabel and infoEffectLabel then
		infoDescLabel.Text = "No boosters available"
		infoEffectLabel.Text = ""
	end

	return count
end

-- Expose the UpdateUsageInfo function to allow external scripts to update the info panel
function BoosterInventory.UpdateInfoPanel(boosterName, spendingAmount)
	UpdateUsageInfo(boosterName, spendingAmount)
end

-- Refresh the booster inventory
function BoosterInventory.Refresh()
	return BoosterInventory.Populate()
end

-- ForceRefresh function (added to fix the nil error)
function BoosterInventory.ForceRefresh()
	Utility.Log(debugSystem, "info", "ForceRefresh called - performing full refresh")
	return BoosterInventory.Populate()
end

-- Cleanup function to disconnect events
function BoosterInventory.Cleanup()
	-- Clean up all stored connections
	for button, connection in pairs(buttonConnections) do
		if button and connection then
			connection:Disconnect()
		end
	end
	buttonConnections = {}
end

return BoosterInventory
