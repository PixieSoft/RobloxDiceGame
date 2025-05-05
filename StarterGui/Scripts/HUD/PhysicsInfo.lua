-- /StarterGui/Scripts/HUD/PhysicsInfo.lua
-- LocalScript that creates a dynamic GUI for viewing and modifying character physics properties

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug settings
local debugSystem = "Physics" -- System name for debug logs

-- Import modules
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HUD = playerGui:WaitForChild("HUD")
local RightHUD = HUD:WaitForChild("RightHUD")

-- Constants
local UPDATE_INTERVAL = 0.1
local MASS_DENSITY_UPDATE_INTERVAL = 1 -- Update mass and density every 1 second

-- Create main container frame
local statsFrame = Instance.new("Frame")
statsFrame.Name = "CharacterStatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0.25, 0) -- Full width, 25% height to accommodate new row
statsFrame.Position = UDim2.new(0, 0, 0, 0) -- Positioned at the very top of RightHUD
statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statsFrame.BackgroundTransparency = 0.2
statsFrame.BorderSizePixel = 0
statsFrame.ZIndex = 10 -- Ensure it stays on top
statsFrame.Parent = RightHUD

-- Add title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.BackgroundTransparency = 0.2
titleLabel.BorderSizePixel = 0
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Physics"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Parent = statsFrame

-- Add rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = statsFrame

-- Function to safely get the total mass of a character
local function getTotalMass(character)
	if not character then return 0 end

	local totalMass = 0
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local success, mass = pcall(function() return part.Mass end)
			if success and mass then
				totalMass = totalMass + mass
			end
		end
	end
	return totalMass
end

-- Function to calculate the total volume of character parts
local function getTotalVolume(character)
	if not character then return 0 end

	local totalVolume = 0
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local success, size = pcall(function() return part.Size end)
			if success and size then
				totalVolume = totalVolume + (size.X * size.Y * size.Z)
			end
		end
	end
	return totalVolume
end

-- Function to calculate the effective density based on mass and volume
local function calculateDensity(character)
	local mass = getTotalMass(character)
	local volume = getTotalVolume(character)

	-- Prevent division by zero
	if volume <= 0 then return 0 end

	return mass / volume
end

-- Configuration for the stats we want to track
local statConfigs = {
	{
		name = "WalkSpeed",
		displayName = "Speed",
		default = 16,
		min = 1,
		max = 10000,
		editable = true
	},
	{
		name = "JumpHeight", 
		displayName = "Height",
		default = 7.2,
		min = 0,
		max = 10000,
		editable = true
	},
	{
		name = "JumpPower",
		displayName = "Power",
		default = 50,
		min = 0,
		max = 10000,
		editable = true
	},
	{
		name = "TotalMass", -- This isn't a real property, we handle it specially
		displayName = "Mass",
		default = 1,
		min = 0.1,
		max = 10000,
		editable = false
	},
	{
		name = "Density", -- This is the sum of all densities
		displayName = "Density",
		default = 1,
		min = 0.1,
		max = 10000,
		editable = false
	}
}

-- Create a container for the stat rows
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, 0, 0.8, 0)
statsContainer.Position = UDim2.new(0, 0, 0.2, 0)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = statsFrame

-- Create rows for each stat
local statRows = {}
for i, config in ipairs(statConfigs) do
	local row = Instance.new("Frame")
	row.Name = config.name .. "Row"
	row.Size = UDim2.new(1, 0, 1/#statConfigs, 0)
	row.Position = UDim2.new(0, 0, (i-1)/#statConfigs, 0)
	row.BackgroundTransparency = 1
	row.Parent = statsContainer

	-- Label for stat name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.3, 0, 1, 0) -- Increased size for more spacing
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = config.displayName .. ":"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = row

	-- Display current value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.2, 0, 1, 0) -- Increased size for more spacing
	valueLabel.Position = UDim2.new(0.3, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.Text = tostring(config.default)
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.Parent = row

	-- Only add input box for editable stats
	if config.editable then
		-- Input box for new value
		local inputBox = Instance.new("TextBox")
		inputBox.Name = "InputBox"
		inputBox.Size = UDim2.new(0.25, 0, 0.6, 0)
		inputBox.Position = UDim2.new(0.75, -10, 0.2, 0) -- Right-justified
		inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		inputBox.BackgroundTransparency = 0.5
		inputBox.BorderSizePixel = 0
		inputBox.Font = Enum.Font.Gotham
		inputBox.PlaceholderText = "New Value"
		inputBox.Text = ""
		inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		inputBox.TextSize = 12
		inputBox.ClearTextOnFocus = true
		inputBox.Parent = row
		inputBox.TextXAlignment = Enum.TextXAlignment.Right -- Right-align text

		-- Add rounded corners to input box
		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 4)
		boxCorner.Parent = inputBox

		-- Store references to update later
		statRows[config.name] = {
			valueLabel = valueLabel,
			inputBox = inputBox,
			config = config
		}

		-- Handle input box focus lost and enter key press
		inputBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then -- Only process if Enter was pressed
				local success, value = pcall(function()
					return tonumber(inputBox.Text)
				end)

				if success and value then
					-- Check bounds
					value = math.clamp(value, config.min, config.max)

					-- Apply new value to character
					local character = player.Character
					if character then
						-- Regular humanoid property
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid[config.name] = value
							Utility.Log(debugSystem, "info", "Updated " .. config.name .. " to " .. value)
						end
					end

					-- Clear input box
					inputBox.Text = ""

					-- Flash the input box to indicate success
					local originalColor = inputBox.BackgroundColor3
					inputBox.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

					-- Create tween to return to original color
					local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local tween = TweenService:Create(inputBox, tweenInfo, {
						BackgroundColor3 = originalColor
					})
					tween:Play()
				else
					-- Flash the input box to indicate error
					local originalColor = inputBox.BackgroundColor3
					inputBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

					-- Create tween to return to original color
					local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local tween = TweenService:Create(inputBox, tweenInfo, {
						BackgroundColor3 = originalColor
					})
					tween:Play()

					-- Clear input box
					inputBox.Text = ""
					Utility.Log(debugSystem, "warn", "Invalid input for " .. config.name .. ": " .. tostring(inputBox.Text))
				end
			end
		end)
	else
		-- For non-editable stats (Mass and Density), just store references to valueLabel
		statRows[config.name] = {
			valueLabel = valueLabel,
			config = config
		}

		-- Add a "read-only" indicator
		local readOnlyLabel = Instance.new("TextLabel")
		readOnlyLabel.Name = "ReadOnlyLabel"
		readOnlyLabel.Size = UDim2.new(0.35, 0, 0.6, 0)
		readOnlyLabel.Position = UDim2.new(0.65, -10, 0.2, 0) -- Right-justified
		readOnlyLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		readOnlyLabel.BackgroundTransparency = 0.7
		readOnlyLabel.BorderSizePixel = 0
		readOnlyLabel.Font = Enum.Font.Gotham
		readOnlyLabel.Text = "(Read-only)"
		readOnlyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		readOnlyLabel.TextSize = 11
		readOnlyLabel.TextXAlignment = Enum.TextXAlignment.Center
		readOnlyLabel.Parent = row

		-- Add rounded corners to read-only label
		local labelCorner = Instance.new("UICorner")
		labelCorner.CornerRadius = UDim.new(0, 4)
		labelCorner.Parent = readOnlyLabel
	end
end

-- Functions to update displayed values
local function updateHumanoidStats()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Update only real humanoid properties
	for statName, row in pairs(statRows) do
		if statName ~= "TotalMass" and statName ~= "Density" then -- Skip the mass and density properties
			local success, value = pcall(function() return humanoid[statName] end)
			if success and value ~= nil then
				row.valueLabel.Text = string.format("%.1f", value)
			end
		end
	end
end

-- Function to update mass and density displays
local function updateMassAndDensity()
	local character = player.Character
	if not character then return end

	local massRow = statRows["TotalMass"]
	local densityRow = statRows["Density"]

	if massRow then
		local currentMass = getTotalMass(character)
		massRow.valueLabel.Text = string.format("%.1f", currentMass)
	end

	if densityRow then
		local currentDensity = calculateDensity(character)
		densityRow.valueLabel.Text = string.format("%.3f", currentDensity)
	end
end

-- Set up event connections for player
player.CharacterAdded:Connect(function(character)
	Utility.Log(debugSystem, "info", "Character spawned, setting up property tracking")
	
	-- Wait for the humanoid to be added
	local humanoid = character:WaitForChild("Humanoid")

	-- Set up property change detection for humanoid stats
	for statName, row in pairs(statRows) do
		-- Skip TotalMass and Density as they're not real properties
		if statName ~= "TotalMass" and statName ~= "Density" then
			humanoid:GetPropertyChangedSignal(statName):Connect(function()
				local success, value = pcall(function() return humanoid[statName] end)
				if success and value ~= nil then
					row.valueLabel.Text = string.format("%.1f", value)
					Utility.Log(debugSystem, "info", "Property changed: " .. statName .. " = " .. value)
				end
			end)
		end
	end

	-- Initial update
	updateHumanoidStats()
	updateMassAndDensity()
end)

-- Initial update if character already exists
if player.Character then
	Utility.Log(debugSystem, "info", "Setting up property tracking for existing character")
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Set up property change detection for humanoid stats
		for statName, row in pairs(statRows) do
			-- Skip TotalMass and Density as they're not real properties
			if statName ~= "TotalMass" and statName ~= "Density" then
				humanoid:GetPropertyChangedSignal(statName):Connect(function()
					local success, value = pcall(function() return humanoid[statName] end)
					if success and value ~= nil then
						row.valueLabel.Text = string.format("%.1f", value)
						Utility.Log(debugSystem, "info", "Property changed: " .. statName .. " = " .. value)
					end
				end)
			end
		end

		-- Initial update
		updateHumanoidStats()
		updateMassAndDensity()
	end
end

-- Set up periodic humanoid stats update
RunService.Heartbeat:Connect(function()
	if tick() % UPDATE_INTERVAL < 0.01 then
		updateHumanoidStats()
	end
end)

-- Set up separate mass and density update timer (every 1 second)
local massUpdateConnection = RunService.Heartbeat:Connect(function()
	if tick() % MASS_DENSITY_UPDATE_INTERVAL < 0.01 then
		updateMassAndDensity()
	end
end)

-- Toggle visibility function
local function toggleVisibility()
	statsFrame.Visible = not statsFrame.Visible
	Utility.Log(debugSystem, "info", "Toggled physics GUI visibility to " .. tostring(statsFrame.Visible))
end

-- Expose toggle function via _G for other scripts
_G.TogglePhysicsGUI = toggleVisibility

-- Make GUI initially visible
statsFrame.Visible = true

-- Clean up connections when script is destroyed
script.AncestryChanged:Connect(function(_, newParent)
	if newParent == nil then
		Utility.Log(debugSystem, "info", "Cleaning up physics GUI connections")
		if massUpdateConnection then
			massUpdateConnection:Disconnect()
		end
	end
end)

Utility.Log(debugSystem, "info", "Physics Info GUI initialized with mass and density display")
