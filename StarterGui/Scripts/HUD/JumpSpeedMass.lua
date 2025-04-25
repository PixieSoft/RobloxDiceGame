-- /StarterGui/Scripts/HUD/JumpSpeedMass.lua
-- LocalScript that creates a dynamic GUI for viewing and modifying character stats

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HUD = playerGui:WaitForChild("HUD")
local RightHUD = HUD:WaitForChild("RightHUD")

-- Constants
local UPDATE_INTERVAL = 0.1
local MASS_UPDATE_INTERVAL = 3 -- Update mass every 3 seconds

-- Create main container frame
local statsFrame = Instance.new("Frame")
statsFrame.Name = "CharacterStatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0.2, 0) -- Full width, 20% height
statsFrame.Position = UDim2.new(0, 0, 0, 0) -- Positioned at the very top of RightHUD
statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statsFrame.BackgroundTransparency = 0.2
statsFrame.BorderSizePixel = 0
statsFrame.ZIndex = 10 -- Ensure it stays on top
statsFrame.Parent = RightHUD

-- Add title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.BackgroundTransparency = 0.2
titleLabel.BorderSizePixel = 0
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Character Stats"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Parent = statsFrame

-- Add rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = statsFrame

-- Function to calculate total mass of a character
local function getTotalMass(character)
	if not character then return 0 end

	local totalMass = 0
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			totalMass = totalMass + part.Mass
		end
	end
	return totalMass
end

-- Configuration for the stats we want to track
local statConfigs = {
	{
		name = "WalkSpeed",
		displayName = "Speed",
		default = 16,
		min = 1,
		max = 100
	},
	{
		name = "JumpHeight", 
		displayName = "Height",
		default = 7.2,
		min = 0,
		max = 50
	},
	{
		name = "JumpPower",
		displayName = "Power",
		default = 50,
		min = 0,
		max = 250
	},
	{
		name = "TotalMass", -- This isn't a real property, we handle it specially
		displayName = "Mass",
		default = 1,
		min = 0.1,
		max = 100
	}
}

-- Create a container for the stat rows
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, 0, 0.75, 0)
statsContainer.Position = UDim2.new(0, 0, 0.25, 0)
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
	nameLabel.Size = UDim2.new(0.25, 0, 1, 0)
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
	valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.25, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.Text = tostring(config.default)
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.Parent = row

	-- Input box for new value
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.Size = UDim2.new(0.20, 0, 0.6, 0) -- Reduced to half the original size
	inputBox.Position = UDim2.new(0.40, 5, 0.2, 0)
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

	-- Add rounded corners to input box
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = inputBox

	-- Save button
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0.15, -10, 0.6, 0)
	saveButton.Position = UDim2.new(0.85, 0, 0.2, 0)
	saveButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
	saveButton.BackgroundTransparency = 0.3
	saveButton.BorderSizePixel = 0
	saveButton.Font = Enum.Font.GothamBold
	saveButton.Text = "Save"
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.TextSize = 12
	saveButton.AutoButtonColor = true
	saveButton.Parent = row

	-- Add rounded corners to save button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 4)
	buttonCorner.Parent = saveButton

	-- Store references to update later
	statRows[config.name] = {
		valueLabel = valueLabel,
		inputBox = inputBox,
		saveButton = saveButton,
		config = config
	}

	-- Handle save button click
	saveButton.MouseButton1Click:Connect(function()
		local success, value = pcall(function()
			return tonumber(inputBox.Text)
		end)

		if success and value then
			-- Check bounds
			value = math.clamp(value, config.min, config.max)

			-- Apply new value to character
			local character = player.Character
			if character then
				if config.name == "TotalMass" then
					-- Special handling for mass - adjust all parts
					local currentTotalMass = getTotalMass(character)
					if currentTotalMass > 0 then
						-- Calculate scale factor to adjust masses
						local scaleFactor = value / currentTotalMass

						-- Apply to all parts
						for _, part in pairs(character:GetDescendants()) do
							if part:IsA("BasePart") then
								-- Scale each part's mass by the same factor
								part.Mass = part.Mass * scaleFactor
							end
						end

						-- Update the display immediately
						statRows["TotalMass"].valueLabel.Text = string.format("%.1f", value)
					end
				else
					-- Regular humanoid property
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid[config.name] = value
					end
				end

				-- Clear input box
				inputBox.Text = ""

				-- Flash the button green to indicate success
				local originalColor = saveButton.BackgroundColor3
				saveButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

				-- Create tween to return to original color
				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local tween = TweenService:Create(saveButton, tweenInfo, {
					BackgroundColor3 = originalColor
				})
				tween:Play()
			end
		else
			-- Flash the button red to indicate error
			local originalColor = saveButton.BackgroundColor3
			saveButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

			-- Create tween to return to original color
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(saveButton, tweenInfo, {
				BackgroundColor3 = originalColor
			})
			tween:Play()

			-- Clear input box
			inputBox.Text = ""
		end
	end)
end

-- Functions to update displayed values
local function updateHumanoidStats()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Update only real humanoid properties
	for statName, row in pairs(statRows) do
		if statName ~= "TotalMass" then -- Skip the mass property
			local currentValue = humanoid[statName]
			if currentValue ~= nil then
				row.valueLabel.Text = string.format("%.1f", currentValue)
			end
		end
	end
end

-- Separate function for mass updates
local function updateMassDisplay()
	local character = player.Character
	if not character then return end

	local massRow = statRows["TotalMass"]
	if massRow then
		local currentMass = getTotalMass(character)
		massRow.valueLabel.Text = string.format("%.1f", currentMass)
	end
end

-- Set up event connections for player
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Set up property change detection for humanoid stats
	for statName, row in pairs(statRows) do
		-- Skip TotalMass as it's not a real property
		if statName ~= "TotalMass" then
			humanoid:GetPropertyChangedSignal(statName):Connect(function()
				local currentValue = humanoid[statName]
				if currentValue ~= nil then
					row.valueLabel.Text = string.format("%.1f", currentValue)
				end
			end)
		end
	end

	-- Initial update
	updateHumanoidStats()
	updateMassDisplay()
end)

-- Initial update if character already exists
if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Set up property change detection for humanoid stats
		for statName, row in pairs(statRows) do
			-- Skip TotalMass as it's not a real property
			if statName ~= "TotalMass" then
				humanoid:GetPropertyChangedSignal(statName):Connect(function()
					local currentValue = humanoid[statName]
					if currentValue ~= nil then
						row.valueLabel.Text = string.format("%.1f", currentValue)
					end
				end)
			end
		end

		-- Initial update
		updateHumanoidStats()
		updateMassDisplay()
	end
end

-- Set up periodic humanoid stats update
RunService.Heartbeat:Connect(function()
	if tick() % UPDATE_INTERVAL < 0.01 then
		updateHumanoidStats()
	end
end)

-- Set up separate mass update timer (every 3 seconds)
local massUpdateConnection = RunService.Heartbeat:Connect(function()
	if tick() % MASS_UPDATE_INTERVAL < 0.01 then
		updateMassDisplay()
	end
end)

-- Toggle visibility function
local function toggleVisibility()
	statsFrame.Visible = not statsFrame.Visible
end

-- Expose toggle function via _G for other scripts
_G.ToggleStatsGUI = toggleVisibility

-- Make GUI initially visible
statsFrame.Visible = true

-- Clean up connections when script is destroyed
script.AncestryChanged:Connect(function(_, newParent)
	if newParent == nil then
		if massUpdateConnection then
			massUpdateConnection:Disconnect()
		end
	end
end)

print("Character Stats GUI initialized")
