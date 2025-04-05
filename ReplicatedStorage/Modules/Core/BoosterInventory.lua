-- /ReplicatedStorage/Modules/Core/BoosterInventory.lua
-- ModuleScript that handles populating and managing the booster inventory UI

local BoosterInventory = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local BoosterInfo = nil -- Will be assigned later if we can find a Boosters module
local success, boosters = pcall(function()
	return require(game:GetService("ServerScriptService").Modules.Core.Boosters)
end)

if success then
	BoosterInfo = boosters.Boosters
end

-- Constants
local SLOT_HEIGHT = 100 -- Height of each booster slot
local SLOT_PADDING = 10 -- Padding between slots

-- Cache
local player = Players.LocalPlayer
local mainUI = nil -- Will be set in Initialize

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

-- Create or update a booster slot with the given data
local function UpdateBoosterSlot(boosterSlot, boosterName, count, timeLeft)
	-- Get booster details
	local details = GetBoosterDetails(boosterName)

	-- Update name label
	local nameLabel = boosterSlot:FindFirstChild("QtyLabel")
	if nameLabel then
		nameLabel.Text = details.name .. " x" .. count
	end

	-- Update image if available
	local imageButton = boosterSlot:FindFirstChild("ImageButton")
	if imageButton and details.imageId ~= "" then
		imageButton.Image = details.imageId
	end

	-- Add tooltip with description if needed
	-- This is optional and depends on if you want tooltips
	boosterSlot.ToolTip = details.description

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
function BoosterInventory.Initialize(mainUIReference)
	mainUI = mainUIReference

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

	return BoosterInventory
end

-- Populate the booster inventory with slots
function BoosterInventory.Populate()
	if not mainUI then
		warn("BoosterInventory not initialized properly. Call Initialize first.")
		return
	end

	-- Find the Boosters container
	local content = mainUI:FindFirstChild("Content")
	if not content then
		warn("Content frame not found in mainUI")
		return
	end

	local boostersFrame = content:FindFirstChild("Boosters")
	if not boostersFrame then
		warn("Boosters frame not found in Content")
		return
	end

	-- Find the template using the ObjectValue reference
	local templateRef = boostersFrame:FindFirstChild("Template")
	if not templateRef or not templateRef:IsA("ObjectValue") or not templateRef.Value then
		warn("Template reference not found or invalid")
		return
	end

	local template = templateRef.Value
	if not template then
		warn("Template not found")
		return
	end

	-- Make sure template is invisible
	template.Visible = false

	-- Clear existing booster slots (except the template)
	for _, child in ipairs(boostersFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= template and child:GetAttribute("IsTemplate") ~= true then
			child:Destroy()
		end
	end

	-- Get player's boosters from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("leaderstats not found for player")
		return
	end

	local boostersFolder = leaderstats:FindFirstChild("Boosters")
	if not boostersFolder then
		warn("Boosters folder not found in leaderstats")
		return
	end

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
	for _, child in ipairs(boostersFolder:GetChildren()) do
		if not child.Name:match("_Active$") then
			boosters[child.Name] = child.Value
		end
	end

	-- Get UIGridLayout for positioning
	local gridLayout = boostersFrame:FindFirstChild("UIGridLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Name = "UIGridLayout"
		gridLayout.CellSize = UDim2.new(0.5, -5, 0, SLOT_HEIGHT)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.SortOrder = Enum.SortOrder.Name
		gridLayout.Parent = boostersFrame
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
		newSlot.Parent = boostersFrame
		count = count + 1
	end

	-- Update canvas size if using a ScrollingFrame
	if boostersFrame:IsA("ScrollingFrame") then
		local rows = math.ceil(count / 2) -- Assuming 2 columns in grid
		boostersFrame.CanvasSize = UDim2.new(0, 0, 0, rows * (SLOT_HEIGHT + SLOT_PADDING))
	end

	return count
end

-- Refresh the booster inventory (repopulate)
function BoosterInventory.Refresh()
	return BoosterInventory.Populate()
end

-- Clean up connections when module is unloaded
function BoosterInventory.Cleanup()
	-- Find all booster slots and disconnect their events
	if mainUI then
		local content = mainUI:FindFirstChild("Content")
		if content then
			local boostersFrame = content:FindFirstChild("Boosters")
			if boostersFrame then
				for _, slot in ipairs(boostersFrame:GetChildren()) do
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
	end
end

return BoosterInventory
