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
local Content = Main:WaitForChild("Content")

-- Track the currently active tabs
local activeTopTab = nil
local activeSideTabs = {}

-- Function to hide all content frames
local function hideAllContentFrames()
	for _, frame in ipairs(Content:GetChildren()) do
		if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
			frame.Visible = false
		end
	end
end

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
	-- Determine which container to look for colors in - either SideTabs or TopTabs
	local colorContainer

	if tabContainer == "TopTabs" then
		colorContainer = TopTabs
	else
		colorContainer = SideTabs -- Look for colors in the main SideTabs container
	end

	-- Get color values from the appropriate container
	local activeColorValue = colorContainer:FindFirstChild("ActiveColor")
	local passiveColorValue = colorContainer:FindFirstChild("PassiveColor")

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
	-- Find the side tab frame
	local topTabFrame = SideTabs:FindFirstChild(topTabName)
	if not topTabFrame or not topTabFrame:IsA("Frame") then return end

	-- Find the side tab button
	local sideTabButton = topTabFrame:FindFirstChild(sideTabName)
	if not sideTabButton then return end

	-- Look for ObjectValue reference named Content
	local contentReference = sideTabButton:FindFirstChild("Content")
	if contentReference and contentReference:IsA("ObjectValue") and contentReference.Value then
		-- Hide all content frames first
		hideAllContentFrames()

		-- Show the referenced content frame
		local contentFrame = contentReference.Value
		if contentFrame and (contentFrame:IsA("Frame") or contentFrame:IsA("ScrollingFrame")) then
			contentFrame.Visible = true
		end
	else
		print("Warning: No Content reference found for side tab:", sideTabName)
	end

	-- Track the active side tab for this top tab
	activeSideTabs[topTabName] = sideTabName

	-- Update visual state of side tabs
	for _, button in ipairs(topTabFrame:GetChildren()) do
		if button:IsA("TextButton") then
			updateButtonColor(button, "SideTabs", button.Name == sideTabName)
		end
	end
end

-- Function to handle top tab selection
selectTopTab = function(tabName)
	-- Hide all side tabs first
	hideAllSideTabs()

	-- Update the active top tab
	activeTopTab = tabName

	-- Find the top tab button
	local topTabButton = TopTabs:FindFirstChild(tabName)
	if not topTabButton then
		warn("Top tab button not found:", tabName)
		return
	end

	-- Look for ObjectValue reference named SideTabs
	local sideTabsReference = topTabButton:FindFirstChild("SideTabs")
	if sideTabsReference and sideTabsReference:IsA("ObjectValue") and sideTabsReference.Value then
		-- Show the referenced side tab frame
		local targetSideTab = sideTabsReference.Value
		if targetSideTab and targetSideTab:IsA("Frame") then
			targetSideTab.Visible = true

			-- Get the name of the side tab for tracking purposes
			local sideTabName = targetSideTab.Name

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
		end
	else
		warn("No SideTabs reference found for top tab:", tabName)
	end

	-- Update visual state of top tabs
	for _, button in ipairs(TopTabs:GetChildren()) do
		if button:IsA("TextButton") then
			updateButtonColor(button, "TopTabs", button.Name == tabName)
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
			updateButtonColor(button, "TopTabs", button.Name == activeTopTab)
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
					updateButtonColor(button, "SideTabs", button.Name == activeSideTabs[topTabFrame.Name])
				end)
			end
		end
	end
end

-- Select the default tab when the menu opens
local function selectDefaultTab()
	-- Find first top tab button as default
	for _, button in ipairs(TopTabs:GetChildren()) do
		if button:IsA("TextButton") then
			selectTopTab(button.Name)
			break
		end
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
