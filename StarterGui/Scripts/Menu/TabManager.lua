-- /StarterGui/Scripts/Menu/TabManager.lua
-- LocalScript that manages the tab system for the Menu interface
-- Adds click handlers to TopTabs buttons and shows corresponding SideTabs frames

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the Menu UI to load
local Menu = playerGui:WaitForChild("Menu")
local Main = Menu:WaitForChild("Main")
local TopTabs = Main:WaitForChild("TopTabs")
local SideTabs = Main:WaitForChild("SideTabs")

-- Optional: Try to load menu structure if available (for extended functionality)
local MenuStructure
pcall(function()
	MenuStructure = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("MenuStructure"))
end)

-- Track the currently active tabs
local activeTopTab = nil
local activeSideTabs = {}

-- Function to hide all SideTabs frames
local function hideAllSideTabs()
	for _, frame in ipairs(SideTabs:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end
end

-- Pre-declare functions to avoid reference issues
local selectTopTab
local selectSideTab
local updateButtonColor

-- Function to update a button's color based on state
updateButtonColor = function(button, tabContainer, isActive)
	local container = button.Parent

	-- Determine which colors to use based on the container (TopTabs or SideTabs)
	local activeColorValue = container:FindFirstChild("ActiveColor")
	local passiveColorValue = container:FindFirstChild("PassiveColor")

	local activeColor = activeColorValue and activeColorValue.Value or Color3.fromRGB(80, 80, 80)
	local passiveColor = passiveColorValue and passiveColorValue.Value or Color3.fromRGB(50, 50, 50)

	-- Set the appropriate color
	if isActive then
		button.BackgroundColor3 = activeColor
	else
		button.BackgroundColor3 = passiveColor
	end
end

-- Function to handle side tab selection
selectSideTab = function(topTabName, sideTabName)
	local topTabFrame = SideTabs:FindFirstChild(topTabName)
	if not topTabFrame or not topTabFrame:IsA("Frame") then return end

	-- Find the content frame associated with this side tab
	local contentName = topTabName .. "_" .. sideTabName
	local contentFrames = Main:FindFirstChild("ContentFrames")

	-- Hide all content frames first if they exist
	if contentFrames then
		for _, frame in ipairs(contentFrames:GetChildren()) do
			if frame:IsA("Frame") then
				frame.Visible = false
			end
		end

		-- Show the corresponding content frame if it exists
		local contentFrame = contentFrames:FindFirstChild(contentName)
		if contentFrame and contentFrame:IsA("Frame") then
			contentFrame.Visible = true
		end
	end

	-- Track the active side tab for this top tab
	activeSideTabs[topTabName] = sideTabName

	-- Update visual state of side tabs
	for _, button in ipairs(topTabFrame:GetChildren()) do
		if button:IsA("TextButton") then
			updateButtonColor(button, topTabFrame, button.Name == sideTabName)
		end
	end
end

-- Function to handle top tab selection
selectTopTab = function(tabName)
	-- Hide all side tabs first
	hideAllSideTabs()

	-- Update the active top tab
	activeTopTab = tabName

	-- Show the corresponding side tab
	local targetSideTab = SideTabs:FindFirstChild(tabName)
	if targetSideTab and targetSideTab:IsA("Frame") then
		targetSideTab.Visible = true

		-- Select the first side tab within this section by default if none is active
		if not activeSideTabs[tabName] then
			local firstSideTabButton
			for _, button in ipairs(targetSideTab:GetChildren()) do
				if button:IsA("TextButton") then
					firstSideTabButton = button
					break
				end
			end

			if firstSideTabButton then
				selectSideTab(tabName, firstSideTabButton.Name)
			end
		else
			-- Use the previously selected side tab
			selectSideTab(tabName, activeSideTabs[tabName])
		end
	else
		warn("No matching SideTab found for: " .. tabName)
	end

	-- Update visual state of top tabs
	for _, button in ipairs(TopTabs:GetChildren()) do
		if button:IsA("TextButton") then
			updateButtonColor(button, TopTabs, button.Name == tabName)
		end
	end
end

-- Set up hover effects and click handlers for all TopTabs buttons
for _, button in ipairs(TopTabs:GetChildren()) do
	if button:IsA("TextButton") then
		-- Click handler
		button.MouseButton1Click:Connect(function()
			selectTopTab(button.Name)
		end)

		-- Hover effects
		button.MouseEnter:Connect(function()
			-- Only change color if this isn't the active tab
			if button.Name ~= activeTopTab then
				local hoverColor = TopTabs:FindFirstChild("HoverColor")
				if hoverColor and hoverColor:IsA("Color3Value") then
					button.BackgroundColor3 = hoverColor.Value
				end
			end
		end)

		button.MouseLeave:Connect(function()
			-- Restore the appropriate color
			updateButtonColor(button, TopTabs, button.Name == activeTopTab)
		end)
	end
end

-- Set up hover effects and click handlers for all SideTabs buttons
for _, topTabFrame in ipairs(SideTabs:GetChildren()) do
	if topTabFrame:IsA("Frame") then
		for _, button in ipairs(topTabFrame:GetChildren()) do
			if button:IsA("TextButton") then
				-- Click handler
				button.MouseButton1Click:Connect(function()
					selectSideTab(topTabFrame.Name, button.Name)
				end)

				-- Hover effects
				button.MouseEnter:Connect(function()
					-- Only change color if this isn't the active tab
					if button.Name ~= activeSideTabs[topTabFrame.Name] then
						local hoverColor = SideTabs:FindFirstChild("HoverColor")
						if hoverColor and hoverColor:IsA("Color3Value") then
							button.BackgroundColor3 = hoverColor.Value
						end
					end
				end)

				button.MouseLeave:Connect(function()
					-- Restore the appropriate color
					updateButtonColor(button, SideTabs, button.Name == activeSideTabs[topTabFrame.Name])
				end)
			end
		end
	end
end

-- Select the default tab when the menu opens
local function selectDefaultTab()
	local defaultTab

	-- If MenuStructure is available, use its default tab
	if MenuStructure then
		defaultTab = MenuStructure.DefaultTopTab
	end

	-- Fallback to first button if no default specified or MenuStructure not available
	if not defaultTab then
		for _, button in ipairs(TopTabs:GetChildren()) do
			if button:IsA("TextButton") then
				defaultTab = button.Name
				break
			end
		end
	end

	-- Select the default tab
	if defaultTab then
		selectTopTab(defaultTab)
	end
end

-- Select default tab when script runs
selectDefaultTab()

-- Listen for when the menu becomes enabled
Menu:GetPropertyChangedSignal("Enabled"):Connect(function()
	if Menu.Enabled then
		-- Reselect default tab when menu is opened
		selectDefaultTab()
	end
end)

print("Tab Manager initialized successfully")
