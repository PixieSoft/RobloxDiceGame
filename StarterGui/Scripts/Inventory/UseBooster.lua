-- /StarterGui/Scripts/Inventory/UseBooster.lua
-- LocalScript that handles booster usage from the BoosterInventory UI with a two-step selection process

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Debug flag - set to true to enable verbose debug output
local DEBUG_ENABLED = true

-- Debug print function
local function debugPrint(...)
	if DEBUG_ENABLED then
		print("[UseBooster Debug]", ...)
	end
end

-- Start with immediate debug print to confirm script is executing
debugPrint("Script started - Beginning execution")

-- Get the player
local player = Players.LocalPlayer
debugPrint("Player reference obtained:", player.Name)

-- Function to check if UI elements exist
local function verifyUIElement(element, name)
	if element then
		debugPrint("Found UI element:", name)
		return true
	else
		warn("[UseBooster] Could not find UI element:", name)
		return false
	end
end

-- Wait for the Menu UI to load with debugging
debugPrint("Waiting for Menu UI to load...")
local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
debugPrint("Menu found:", Menu:GetFullName())

-- Try to find Content and BoosterInventory paths with error handling
local Content, BoosterInventory
local success, errorMsg = pcall(function()
	Content = Menu:WaitForChild("Main"):WaitForChild("Content")
	BoosterInventory = Content:WaitForChild("BoosterInventory")
	return true
end)

if not success then
	warn("[UseBooster] Error finding UI path:", errorMsg)
	-- Print full menu hierarchy to help debugging
	local function printHierarchy(instance, level)
		level = level or 0
		local indent = string.rep("  ", level)
		print(indent .. instance.Name, ":", instance.ClassName)
		for _, child in pairs(instance:GetChildren()) do
			printHierarchy(child, level + 1)
		end
	end
	print("Menu hierarchy:")
	printHierarchy(Menu)
	return -- Stop script execution if we can't find the UI
end

debugPrint("Content found:", Content:GetFullName())
debugPrint("BoosterInventory found:", BoosterInventory:GetFullName())

-- Get references to the button groups
local buttonGroup, useAllButton, useButton, assignButton, deleteButton
success, errorMsg = pcall(function()
	buttonGroup = BoosterInventory:WaitForChild("Buttons")
	useAllButton = buttonGroup:WaitForChild("UseAll")
	useButton = buttonGroup:FindFirstChild("Use")
	assignButton = buttonGroup:FindFirstChild("Assign")
	deleteButton = buttonGroup:FindFirstChild("Delete")
end)

if not success then
	warn("[UseBooster] Error finding buttons:", errorMsg)
	return
end

verifyUIElement(buttonGroup, "Buttons container")
verifyUIElement(useAllButton, "UseAll button")
verifyUIElement(useButton, "Use button")
verifyUIElement(assignButton, "Assign button")
verifyUIElement(deleteButton, "Delete button")

-- Get reference to the boosters container
local boostersContainer
success, errorMsg = pcall(function()
	boostersContainer = BoosterInventory:WaitForChild("Boosters")
end)

if not success then
	warn("[UseBooster] Error finding boosters container:", errorMsg)
	return
end

verifyUIElement(boostersContainer, "Boosters container")

-- Debug: List all children in the boosters container
debugPrint("Boosters container children:")
for i, child in ipairs(boostersContainer:GetChildren()) do
	debugPrint("  ", i, child.Name, child.ClassName, "Visible:", child.Visible)
end

-- Make sure BoosterEvents exists
local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
if not boosterEvents then
	debugPrint("Creating BoosterEvents folder in ReplicatedStorage")
	boosterEvents = Instance.new("Folder")
	boosterEvents.Name = "BoosterEvents"
	boosterEvents.Parent = ReplicatedStorage

	-- Create necessary RemoteEvents if they don't exist
	local eventNames = {"UseBooster", "DeleteBooster", "AssignBooster"}
	for _, eventName in ipairs(eventNames) do
		if not boosterEvents:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = boosterEvents
			debugPrint("Created RemoteEvent:", eventName)
		end
	end
end else
	debugPrint("Found existing BoosterEvents folder")
end

-- Get reference to the RemoteEvents
local useBoosterEvent, deleteBoosterEvent, assignBoosterEvent

success, errorMsg = pcall(function()
	useBoosterEvent = boosterEvents:WaitForChild("UseBooster")
	deleteBoosterEvent = boosterEvents:FindFirstChild("DeleteBooster") or Instance.new("RemoteEvent", boosterEvents)
	deleteBoosterEvent.Name = "DeleteBooster"
	assignBoosterEvent = boosterEvents:FindFirstChild("AssignBooster") or Instance.new("RemoteEvent", boosterEvents)
	assignBoosterEvent.Name = "AssignBooster"
end)

if not success then
	warn("[UseBooster] Error setting up RemoteEvents:", errorMsg)
	return
end

debugPrint("RemoteEvents ready")

-- Selection mode tracking
local selectionMode = {
	active = false,
	action = nil, -- "UseAll", "Use", "Assign", "Delete"
	highlightedSlots = {},
	glowEffects = {}
}

-- Color configurations for different actions
local actionColors = {
	UseAll = Color3.fromRGB(0, 180, 0),   -- Green
	Use = Color3.fromRGB(0, 120, 255),    -- Blue
	Assign = Color3.fromRGB(255, 165, 0), -- Orange
	Delete = Color3.fromRGB(255, 50, 50)  -- Red
}

-- Helper function to get current booster count from leaderstats
local function getBoosterCount(boosterName)
	debugPrint("Getting count for booster:", boosterName)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		debugPrint("No leaderstats found")
		return 0 
	end

	local boostersFolder = leaderstats:FindFirstChild("Boosters")
	if not boostersFolder then 
		debugPrint("No Boosters folder found in leaderstats")
		return 0 
	end

	local boosterValue = boostersFolder:FindFirstChild(boosterName)
	if not boosterValue then 
		debugPrint("No value found for booster:", boosterName)
		return 0 
	end

	debugPrint("Count for", boosterName, ":", boosterValue.Value)
	return boosterValue.Value
end

-- Helper function to show a notification
local function showNotification(message, color)
	debugPrint("Showing notification:", message)
	color = color or Color3.fromRGB(40, 40, 40)

	local notification = Instance.new("TextLabel")
	notification.Name = "BoosterNotification"
	notification.Size = UDim2.new(0, 300, 0, 50)
	notification.Position = UDim2.new(0.5, -150, 0.5, -25)
	notification.AnchorPoint = Vector2.new(0.5, 0.5)
	notification.BackgroundColor3 = color
	notification.BorderSizePixel = 2
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.Text = message
	notification.TextSize = 16
	notification.TextWrapped = true
	notification.Parent = Menu

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Remove notification after 2 seconds
	game:GetService("Debris"):AddItem(notification, 2)

	return notification
end

-- Function to enter selection mode
local function enterSelectionMode(action)
	debugPrint("Entering selection mode:", action)

	-- Exit any existing selection mode first
	if selectionMode.active then
		debugPrint("Exiting previous selection mode first")
		exitSelectionMode()
	end

	selectionMode.active = true
	selectionMode.action = action
	debugPrint("Selection mode active:", selectionMode.active, "Action:", selectionMode.action)

	-- Count visible booster slots for debugging
	local visibleSlotCount = 0

	-- Highlight all booster slots
	local color = actionColors[action] or Color3.fromRGB(0, 180, 0)

	for _, boosterSlot in ipairs(boostersContainer:GetChildren()) do
		if boosterSlot:IsA("Frame") and boosterSlot.Name:match("^BoosterSlot_") and boosterSlot.Visible then
			debugPrint("Highlighting slot:", boosterSlot.Name)
			visibleSlotCount = visibleSlotCount + 1

			-- Store original BackgroundColor3 for restoration later
			local originalColor = boosterSlot.BackgroundColor3
			debugPrint("Original color:", originalColor.R, originalColor.G, originalColor.B)
			selectionMode.highlightedSlots[boosterSlot] = originalColor

			-- Change background to highlight color
			boosterSlot.BackgroundColor3 = color
			debugPrint("Applied highlight color")

			-- Add glow effect
			local glow = Instance.new("UIStroke")
			glow.Name = "SelectionGlow"
			glow.Color = color
			glow.Thickness = 3
			glow.Transparency = 0
			glow.Parent = boosterSlot

			table.insert(selectionMode.glowEffects, glow)
			debugPrint("Added glow effect")
		end
	end

	debugPrint("Highlighted", visibleSlotCount, "booster slots")

	showNotification("Choose a booster to " .. action, color)
end

-- Function to exit selection mode
local function exitSelectionMode()
	debugPrint("Exiting selection mode")
	if not selectionMode.active then 
		debugPrint("Not in selection mode, nothing to exit")
		return 
	end

	-- Restore original colors
	local restoredCount = 0
	for boosterSlot, originalColor in pairs(selectionMode.highlightedSlots) do
		if boosterSlot and boosterSlot.Parent then
			debugPrint("Restoring original color for:", boosterSlot.Name)
			boosterSlot.BackgroundColor3 = originalColor
			restoredCount = restoredCount + 1
		end
	end
	debugPrint("Restored", restoredCount, "slot colors")

	-- Remove glow effects
	local removedCount = 0
	for _, glow in ipairs(selectionMode.glowEffects) do
		if glow and glow.Parent then
			glow:Destroy()
			removedCount = removedCount + 1
		end
	end
	debugPrint("Removed", removedCount, "glow effects")

	-- Reset selection mode
	selectionMode.active = false
	selectionMode.action = nil
	selectionMode.highlightedSlots = {}
	selectionMode.glowEffects = {}
	debugPrint("Selection mode reset")
end

-- Function to handle booster selection based on current action
local function handleBoosterSelection(boosterSlot)
	debugPrint("Handling booster selection:", boosterSlot.Name)
	if not selectionMode.active then 
		debugPrint("Not in selection mode, ignoring selection")
		return 
	end

	-- Extract booster name from the slot name
	local boosterName = boosterSlot.Name:gsub("BoosterSlot_", "")
	debugPrint("Extracted booster name:", boosterName)

	local count = getBoosterCount(boosterName)
	debugPrint("Booster count:", count)

	-- Skip if no boosters of this type
	if count <= 0 then
		debugPrint("No boosters to use, showing notification")
		showNotification("No " .. boosterName .. " boosters to use!", Color3.fromRGB(180, 0, 0))
		exitSelectionMode()
		return
	end

	-- Handle different actions
	if selectionMode.action == "UseAll" then
		debugPrint("Executing UseAll action for", count, boosterName, "boosters")
		-- Use all boosters of this type
		useBoosterEvent:FireServer(boosterName, count)
		showNotification("Used all " .. count .. " " .. boosterName .. " boosters!", actionColors.UseAll)

	elseif selectionMode.action == "Use" then
		debugPrint("Executing Use action for 1", boosterName, "booster")
		-- Use just one booster
		useBoosterEvent:FireServer(boosterName, 1)
		showNotification("Used 1 " .. boosterName .. " booster!", actionColors.Use)

	elseif selectionMode.action == "Assign" then
		debugPrint("Executing Assign action for", boosterName)
		-- Assign booster to quick slot (placeholder)
		assignBoosterEvent:FireServer(boosterName)
		showNotification("Assigned " .. boosterName .. " to quick slot!", actionColors.Assign)

	elseif selectionMode.action == "Delete" then
		debugPrint("Executing Delete action for", count, boosterName, "boosters")
		-- Delete booster (placeholder)
		deleteBoosterEvent:FireServer(boosterName, count)
		showNotification("Deleted " .. count .. " " .. boosterName .. " boosters!", actionColors.Delete)
	end

	-- Exit selection mode
	exitSelectionMode()
end

-- Connect action buttons
debugPrint("Setting up button connections")

useAllButton.MouseButton1Click:Connect(function()
	debugPrint("UseAll button clicked")
	enterSelectionMode("UseAll")
end)

if useButton then
	useButton.MouseButton1Click:Connect(function()
		debugPrint("Use button clicked")
		enterSelectionMode("Use")
	end)
end

if assignButton then
	assignButton.MouseButton1Click:Connect(function()
		debugPrint("Assign button clicked")
		enterSelectionMode("Assign")
	end)
end

if deleteButton then
	deleteButton.MouseButton1Click:Connect(function()
		debugPrint("Delete button clicked")
		enterSelectionMode("Delete")
	end)
end

-- Set up functionality for booster slots
local function setupBoosterSlotInteractions(boosterSlot)
	if not boosterSlot:IsA("Frame") or not boosterSlot.Name:match("^BoosterSlot_") then
		return
	end

	debugPrint("Setting up interactions for booster slot:", boosterSlot.Name)

	-- Click handler
	boosterSlot.InputBegan:Connect(function(input)
		debugPrint("Input began on", boosterSlot.Name, "Input type:", input.UserInputType.Name)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			debugPrint("Mouse button 1 detected on", boosterSlot.Name)
			if selectionMode.active then
				debugPrint("Selection mode is active, handling selection")
				handleBoosterSelection(boosterSlot)
			else
				debugPrint("Selection mode not active, ignoring click")
			end
		end
	end)

	-- Set up hover effects (only active when not in selection mode)
	boosterSlot.MouseEnter:Connect(function()
		debugPrint("Mouse entered", boosterSlot.Name, "Selection mode:", selectionMode.active)
		if not selectionMode.active then
			-- Store current color for restoration
			local currentColor = boosterSlot.BackgroundColor3
			debugPrint("Storing color:", currentColor.R, currentColor.G, currentColor.B)
			boosterSlot:SetAttribute("PreviousColor", string.format("%f,%f,%f", 
				currentColor.R, currentColor.G, currentColor.B))

			-- Highlight effect on hover
			boosterSlot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			debugPrint("Applied hover highlight")
		end
	end)

	boosterSlot.MouseLeave:Connect(function()
		debugPrint("Mouse left", boosterSlot.Name, "Selection mode:", selectionMode.active)
		if not selectionMode.active then
			-- Restore color if we're not in selection mode
			local previousColorStr = boosterSlot:GetAttribute("PreviousColor")
			if previousColorStr then
				local r, g, b = previousColorStr:match("([^,]+),([^,]+),([^,]+)")
				if r and g and b then
					boosterSlot.BackgroundColor3 = Color3.new(tonumber(r), tonumber(g), tonumber(b))
					debugPrint("Restored color from attribute")
				else
					-- Fallback default color
					boosterSlot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					debugPrint("Used fallback color (parse failed)")
				end
			else
				-- Fallback default color
				boosterSlot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				debugPrint("Used fallback color (no previous color)")
			end
		end
	end)
end

-- Set up existing booster slots
debugPrint("Setting up existing booster slots")
local setupCount = 0
for _, child in ipairs(boostersContainer:GetChildren()) do
	if child:IsA("Frame") and child.Name:match("^BoosterSlot_") then
		setupBoosterSlotInteractions(child)
		setupCount = setupCount + 1
	end
end
debugPrint("Set up", setupCount, "existing booster slots")

-- Set up monitoring for new booster slots
boostersContainer.ChildAdded:Connect(function(child)
	debugPrint("New child added to boosters container:", child.Name)
	setupBoosterSlotInteractions(child)
end)

-- Cancel selection mode on right click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		debugPrint("Right mouse button detected, selection mode:", selectionMode.active)
		if selectionMode.active then
			debugPrint("Canceling selection mode via right-click")
			exitSelectionMode()
			showNotification("Selection canceled", Color3.fromRGB(100, 100, 100))
		end
	end
end)

-- Note on server-side event handler change needed:
debugPrint("Note: Server-side UseBooster event handler needs updating to handle count parameter")

print("UseBooster script loaded with debugging - Two-step selection process implemented")
