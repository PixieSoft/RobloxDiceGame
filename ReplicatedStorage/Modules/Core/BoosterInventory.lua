-- /ReplicatedStorage/Modules/Core/BoosterInventory.lua
-- ModuleScript that handles populating and managing the booster inventory UI

local BoosterInventory = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local BoosterInfo = nil -- Will be assigned later if we can find a Boosters module
local success, boosters = pcall(function()
	return require(ReplicatedStorage.Modules.Core.Boosters)
end)

if success then
	BoosterInfo = boosters.Items
end

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

-- Private functions

-- Get the proper name and description for a booster
local function GetBoosterDetails(boosterName)
	-- Default values
	local displayName = boosterName
	local description = "No description available"
	local imageId = ""

	-- Try to get info from the Boosters module if available
	if BoosterInfo and BoosterInfo[boosterName] then
		displayName = BoosterInfo[boosterName].name or displayName
		description = BoosterInfo[boosterName].description or description
		imageId = BoosterInfo[boosterName].imageId or ""
	end

	return {
		name = displayName,
		description = description,
		imageId = imageId
	}
end

-- Update a booster slot with the given data
local function UpdateBoosterSlot(boosterSlot, boosterName, count, timeLeft)
	-- Get booster details
	local details = GetBoosterDetails(boosterName)

	-- Update Quantity (Qty) label
	local qtyLabel = boosterSlot:FindFirstChild("Qty")
	if qtyLabel then
		qtyLabel.Text = tostring(count)
	end

	-- Update image if available
	local imageFrame = boosterSlot:FindFirstChild("Image")
	if imageFrame and details.imageId ~= "" then
		imageFrame.Image = details.imageId
	end

	-- If there's an active timer, display it
	if timeLeft then
		-- Format time left (assuming timeLeft is in seconds)
		local mins = math.floor(timeLeft / 60)
		local secs = timeLeft % 60
		local timeString = string.format("%02d:%02d", mins, secs)

		-- Find or create active timer label
		local activeLabel = boosterSlot:FindFirstChild("ActiveLabel")
		if not activeLabel then
			activeLabel = Instance.new("TextLabel")
			activeLabel.Name = "ActiveLabel"
			activeLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
			activeLabel.Position = UDim2.new(0.7, 0, 0, 0)
			activeLabel.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			activeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			activeLabel.TextScaled = true
			activeLabel.Font = Enum.Font.GothamBold
			activeLabel.Parent = boosterSlot

			-- Add rounded corners
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.2, 0)
			corner.Parent = activeLabel
		end

		activeLabel.Text = timeString
		activeLabel.Visible = true
	else
		-- Hide active timer if exists
		local activeLabel = boosterSlot:FindFirstChild("ActiveLabel")
		if activeLabel then
			activeLabel.Visible = false
		end
	end

	-- Set up use button functionality
	local useButton = boosterSlot:FindFirstChild("Use")
	if useButton then
		-- Clean up previous connections
		local oldConnection = useButton:GetAttribute("ClickConnection")
		if oldConnection then
			oldConnection:Disconnect()
		end

		-- Create new connection
		local connection = useButton.Activated:Connect(function()
			-- Find or create the UseBooster RemoteEvent
			local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
			local useBoosterEvent = boosterEvents and boosterEvents:FindFirstChild("UseBooster")

			if useBoosterEvent then
				useBoosterEvent:FireServer(boosterName)
			else
				warn("UseBooster event not found in ReplicatedStorage.BoosterEvents")
			end
		end)

		-- Store connection for cleanup
		useButton:SetAttribute("ClickConnection", connection)
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
	print("Found Main frame")

	-- Find the Content frame within Main
	contentFrame = mainFrame:FindFirstChild("Content")
	if not contentFrame then
		warn("Content frame not found in Main")
		return
	end
	print("Found Content frame")

	-- Find the BoosterInventory frame within Content
	boostersFrame = contentFrame:FindFirstChild("BoosterInventory")
	if not boostersFrame then
		warn("BoosterInventory frame not found in Content")
		return
	end
	print("Found BoosterInventory frame")

	-- Find the Boosters container within BoosterInventory
	boostersContainer = boostersFrame:FindFirstChild("Boosters")
	if not boostersContainer then
		warn("Boosters container not found in BoosterInventory")
		return
	end
	print("Found Boosters container")

	-- Find the Template within Boosters container
	local templateValue = boostersContainer:FindFirstChild("Template")
	if not templateValue or not templateValue:IsA("ObjectValue") then
		warn("Template ObjectValue not found in Boosters container")
		return
	end

	-- Extract the actual template frame from the ObjectValue
	template = templateValue.Value
	if not template or not template:IsA("Frame") then
		warn("Invalid Template frame in ObjectValue")
		return
	end
	print("Found Template:", template.Name)

	-- Make sure Template is invisible
	template.Visible = false

	-- Make sure BoosterEvents exists
	local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
	if not boosterEvents then
		boosterEvents = Instance.new("Folder")
		boosterEvents.Name = "BoosterEvents"
		boosterEvents.Parent = ReplicatedStorage

		-- Create events if they don't exist
		local events = {
			"BoosterActivated",
			"BoosterDeactivated",
			"UseBooster"
		}

		for _, eventName in ipairs(events) do
			if not boosterEvents:FindFirstChild(eventName) then
				local event = Instance.new("RemoteEvent")
				event.Name = eventName
				event.Parent = boosterEvents
			end
		end
	end

	-- Connect to booster events for updates
	local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
	if activatedEvent then
		activatedEvent.OnClientEvent:Connect(function(boosterName, expirationTime)
			-- Refresh inventory to show active status
			BoosterInventory.Refresh()
		end)
	end

	local deactivatedEvent = boosterEvents:FindFirstChild("BoosterDeactivated")
	if deactivatedEvent then
		deactivatedEvent.OnClientEvent:Connect(function(boosterName)
			-- Refresh inventory to remove active status
			BoosterInventory.Refresh()
		end)
	end

	print("BoosterInventory initialization complete")
	return BoosterInventory
end

-- Populate the booster inventory with slots
function BoosterInventory.Populate()
	print("BoosterInventory.Populate called")

	if not mainUI then
		warn("BoosterInventory not initialized properly. Call Initialize first.")
		return 0
	end

	if not boostersContainer then
		warn("Boosters container not found. Make sure initialization was successful.")
		return 0
	end

	if not template then
		warn("Template not found. Make sure initialization was successful.")
		return 0
	end

	print("Found boostersContainer:", boostersContainer.Name)
	print("Template ready for cloning")

	-- Clear existing booster slots (except the template)
	for _, child in ipairs(boostersContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= template and child:GetAttribute("IsTemplate") ~= true then
			child:Destroy()
		end
	end

	-- Get player's boosters from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("leaderstats not found for player")
		return 0
	end

	local boostersFolder = leaderstats:FindFirstChild("Boosters")
	if not boostersFolder then
		warn("Boosters folder not found in leaderstats")
		return 0
	end

	print("Found leaderstats.Boosters folder")

	-- Get active boosters (if any)
	local activeBoosters = {}
	for _, child in ipairs(boostersFolder:GetChildren()) do
		if child.Name:match("_Active$") then
			local baseName = child.Name:gsub("_Active$", "")
			activeBoosters[baseName] = child.Value -- Store time left
		end
	end

	-- Group boosters by name (excluding active indicators)
	local boosters = {}
	local boosterCount = 0
	for _, child in ipairs(boostersFolder:GetChildren()) do
		if not child.Name:match("_Active$") then
			boosters[child.Name] = child.Value
			boosterCount = boosterCount + 1
		end
	end

	print("Found", boosterCount, "boosters in leaderstats")

	-- Get UIGridLayout for positioning or create if it doesn't exist
	local gridLayout = boostersContainer:FindFirstChild("BoosterLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Name = "BoosterLayout"
		gridLayout.CellSize = UDim2.new(0.5, -5, 0, SLOT_HEIGHT)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.SortOrder = Enum.SortOrder.Name
		gridLayout.Parent = boostersContainer
	end

	-- Create slots for each booster
	local count = 0
	for boosterName, boosterCount in pairs(boosters) do
		-- Skip if count is 0
		if boosterCount <= 0 then
			continue
		end

		-- Clone the template
		local newSlot = template:Clone()
		newSlot.Name = "BoosterSlot_" .. boosterName
		newSlot.Visible = true
		newSlot:SetAttribute("IsTemplate", false)

		-- Get time left if active
		local timeLeft = activeBoosters[boosterName]

		-- Update the slot with booster info
		UpdateBoosterSlot(newSlot, boosterName, boosterCount, timeLeft)

		-- Parent to the container
		newSlot.Parent = boostersContainer
		count = count + 1

		print("Created slot for", boosterName, "with count", boosterCount)
	end

	-- Update canvas size if using a ScrollingFrame
	if boostersContainer:IsA("ScrollingFrame") then
		local rows = math.ceil(count / 2) -- Assuming 2 columns in grid
		boostersContainer.CanvasSize = UDim2.new(0, 0, 0, rows * (SLOT_HEIGHT + SLOT_PADDING))
	end

	print("Populated inventory with", count, "booster slots")
	return count
end

-- Refresh the booster inventory (repopulate)
function BoosterInventory.Refresh()
	print("BoosterInventory.Refresh called")
	return BoosterInventory.Populate()
end

-- Clean up connections when module is unloaded
function BoosterInventory.Cleanup()
	-- Find all booster slots and disconnect their events
	if boostersContainer then
		for _, slot in ipairs(boostersContainer:GetChildren()) do
			if slot.Name:match("^BoosterSlot") then
				local useButton = slot:FindFirstChild("Use")
				if useButton then
					local connection = useButton:GetAttribute("ClickConnection")
					if connection then
						connection:Disconnect()
					end
				end
			end
		end
	end
end

return BoosterInventory
