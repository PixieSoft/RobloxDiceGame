-- /ReplicatedStorage/Modules/Core/TabManager.lua
-- ModuleScript that manages the menu tab system, handling tab selection and content frame visibility

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuStructure = require(ReplicatedStorage.Modules.Core.MenuStructure)
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

local TabManager = {}
TabManager.__index = TabManager  -- Setup metatable for OOP

-- Debug settings
local debugSystem = "Menu" -- System name for debug logs

-- Create new TabManager instance
function TabManager.new()
	local self = {}
	setmetatable(self, TabManager)  -- Set the metatable for proper inheritance

	-- UI references (populated during initialization)
	self.ui = {
		menuFrame = nil,            -- The main menu frame (Background)
		topTabContainer = nil,      -- Container for top tab buttons (TopBar)
		topTabButtons = {},         -- Individual top tab buttons
		sideTabContainer = nil,     -- Container for side tab buttons (SideTabs)
		sideTabButtons = {},        -- Individual side tab buttons
		contentContainer = nil,     -- Container for content frames (Content)
		contentFrames = {},         -- Individual content frames
		templates = {
			sideTabButton = nil     -- Template for side tab buttons
		}
	}

	-- Visual state tracking
	self.colors = {
		originalTopTabColors = {},  -- Original colors of top tab buttons
		originalSideTabColors = {}  -- Original colors of side tab buttons
	}

	-- Current state of the menu
	self.state = {
		currentTopTab = nil,        -- Currently selected top tab
		currentSideTab = nil,       -- Currently selected side tab
		lastSideTabPerTopTab = {},  -- Remembers last side tab for each top tab
		isInitialized = false,      -- Whether initialization has occurred
		debug = false               -- Debug mode toggle
	}

	return self
end

-- Debug print function that only outputs when debug mode is on
function TabManager:DebugPrint(...)
	if self.state.debug then
		Utility.Log(debugSystem, "info", ...)
	end
end

-- Helper function to get a Color3Value's value with fallback
local function getColor3Value(instance, defaultColor)
	if instance and instance:IsA("Color3Value") then
		return instance.Value
	end
	return defaultColor or Color3.fromRGB(255, 255, 255)
end

-- Initialize the TabManager with references to UI elements
function TabManager:Initialize(menuFrame, config)
	if not menuFrame then
		Utility.Log(debugSystem, "warn", "TabManager: menuFrame is nil! Cannot initialize.")
		return self
	end

	if self.state.isInitialized then
		self:DebugPrint("TabManager already initialized")
		return self
	end

	-- Set debug mode from config if provided
	if config and config.debug ~= nil then
		self.state.debug = config.debug
	end

	self:DebugPrint("Initializing TabManager with menu frame:", menuFrame.Name)

	-- Store reference to menu frame (Background)
	self.ui.menuFrame = menuFrame

	-- Based on the screenshot, we know the exact paths to UI elements
	-- TopTabs is located in Background.TopBar
	local topBar = menuFrame:FindFirstChild("TopBar")
	if not topBar then
		Utility.Log(debugSystem, "warn", "TabManager: Could not find TopBar in " .. menuFrame.Name)
		return self
	end
	self.ui.topTabContainer = topBar

	-- SideTabs is located directly in Background
	self.ui.sideTabContainer = menuFrame:FindFirstChild("SideTabs")
	if not self.ui.sideTabContainer then
		Utility.Log(debugSystem, "warn", "TabManager: Could not find SideTabs in " .. menuFrame.Name)
		return self
	end

	-- Content is located directly in Background
	self.ui.contentContainer = menuFrame:FindFirstChild("Content")
	if not self.ui.contentContainer then
		Utility.Log(debugSystem, "warn", "TabManager: Could not find Content in " .. menuFrame.Name)
		return self
	end

	-- Find template for side tab buttons
	self.ui.templates.sideTabButton = self.ui.sideTabContainer:FindFirstChild("Template")
	if not self.ui.templates.sideTabButton then
		Utility.Log(debugSystem, "warn", "TabManager: Missing SideTab button template. Ensure your SideTabs container has a Template child.")
		return self
	end

	-- Hide the template
	self.ui.templates.sideTabButton.Visible = false

	-- Load all top tab buttons and capture original colors
	self:DebugPrint("Loading top tab buttons from", self.ui.topTabContainer.Name)
	for _, topTabButton in ipairs(self.ui.topTabContainer:GetChildren()) do
		if (topTabButton:IsA("TextButton") or topTabButton:IsA("ImageButton")) and not topTabButton:IsA("ValueBase") then
			-- Register this button
			local tabName = topTabButton.Name
			self.ui.topTabButtons[tabName] = topTabButton

			-- Store original color
			self.colors.originalTopTabColors[tabName] = topTabButton.BackgroundColor3

			-- Connect click event
			topTabButton.MouseButton1Click:Connect(function()
				self:SelectTopTab(tabName)
			end)

			self:DebugPrint("Registered top tab button:", tabName)
		end
	end

	-- Store original side tab color from template
	self.colors.originalSideTabColor = self.ui.templates.sideTabButton.BackgroundColor3

	-- Load all content frames
	self:DebugPrint("Loading content frames from", self.ui.contentContainer.Name)
	for _, contentFrame in ipairs(self.ui.contentContainer:GetChildren()) do
		if contentFrame:IsA("Frame") or contentFrame:IsA("ScrollingFrame") then
			-- Register this frame
			local frameName = contentFrame.Name
			self.ui.contentFrames[frameName] = contentFrame

			-- Hide all frames initially
			contentFrame.Visible = false

			self:DebugPrint("Registered content frame:", frameName)
		end
	end

	-- If we were previously on a tab, return to it
	if self.state.currentTopTab and MenuStructure.TopTabs[self.state.currentTopTab] then
		self:SelectTopTab(self.state.currentTopTab)
	else
		-- Otherwise select the default top tab
		self:SelectTopTab(MenuStructure.DefaultTopTab)
	end

	-- Mark as initialized
	self.state.isInitialized = true
	self:DebugPrint("TabManager initialization complete")

	return self
end

-- Select a top tab and update UI
function TabManager:SelectTopTab(topTabName)
	if not self.state.isInitialized then
		Utility.Log(debugSystem, "warn", "TabManager: Cannot select top tab before initialization.")
		return
	end

	-- Check that this top tab exists in MenuStructure
	if not MenuStructure.TopTabs[topTabName] then
		Utility.Log(debugSystem, "warn", "TabManager: Top tab not found in MenuStructure:", topTabName)
		return
	end

	self:DebugPrint("Selecting top tab:", topTabName)

	-- Update state
	self.state.currentTopTab = topTabName

	-- Update UI
	self:UpdateTopTabVisuals(topTabName)
	self:ClearSideTabs()
	self:PopulateSideTabs(topTabName)

	-- Select last used side tab for this top tab, or default if none
	local sideTabToSelect = self.state.lastSideTabPerTopTab[topTabName] or MenuStructure:GetDefaultSideTab(topTabName)
	if sideTabToSelect then
		self:SelectSideTab(sideTabToSelect)
	end
end

-- Select a side tab and update UI
function TabManager:SelectSideTab(sideTabName)
	if not self.state.isInitialized then
		Utility.Log(debugSystem, "warn", "TabManager: Cannot select side tab before initialization.")
		return
	end

	if not self.state.currentTopTab then
		Utility.Log(debugSystem, "warn", "TabManager: Cannot select side tab before selecting a top tab.")
		return
	end

	self:DebugPrint("Selecting side tab:", sideTabName)

	-- Update state
	self.state.currentSideTab = sideTabName

	-- Store this selection for the current top tab (for persistence)
	self.state.lastSideTabPerTopTab[self.state.currentTopTab] = sideTabName

	-- Update UI
	self:UpdateSideTabVisuals(sideTabName)

	-- Show correct content frame
	local contentFrameName = MenuStructure:GetContentFrame(self.state.currentTopTab, sideTabName)
	if contentFrameName then
		self:ShowContentFrame(contentFrameName)
	else
		Utility.Log(debugSystem, "warn", "TabManager: No content frame defined for this tab combination:", 
			self.state.currentTopTab, "/", sideTabName)
	end

	-- Fire a custom selection event that other modules can listen for
	local tabSelected = Instance.new("BindableEvent")
	tabSelected.Name = "TabSelected"
	tabSelected.Event:Connect(function() end) -- Dummy connection to prevent garbage collection
	tabSelected:Fire(self.state.currentTopTab, sideTabName, contentFrameName)
	tabSelected:Destroy()
end

-- Update the visual state of top tab buttons to reflect selection
function TabManager:UpdateTopTabVisuals(selectedTabName)
	-- Get the select color from the TopTabs Color3Value
	local selectColorValue = self.ui.topTabContainer:FindFirstChild("SelectColor")
	local selectColor = getColor3Value(selectColorValue, Color3.fromRGB(255, 255, 255))

	for tabName, button in pairs(self.ui.topTabButtons) do
		local isSelected = (tabName == selectedTabName)

		-- Update visual state
		if isSelected then
			button.BackgroundColor3 = selectColor
		else
			-- Restore original color
			button.BackgroundColor3 = self.colors.originalTopTabColors[tabName] or button.BackgroundColor3
		end
	end
end

-- Update the visual state of side tab buttons to reflect selection
function TabManager:UpdateSideTabVisuals(selectedTabName)
	-- Get the select color from the SideTabs Color3Value
	local selectColorValue = self.ui.sideTabContainer:FindFirstChild("SelectColor")
	local selectColor = getColor3Value(selectColorValue, Color3.fromRGB(255, 255, 255))

	for tabName, button in pairs(self.ui.sideTabButtons) do
		local isSelected = (tabName == selectedTabName)

		-- Update visual state
		if isSelected then
			button.BackgroundColor3 = selectColor
		else
			-- Restore original color
			button.BackgroundColor3 = self.colors.originalSideTabColors[tabName] or self.colors.originalSideTabColor
		end
	end
end

-- Clear all side tab buttons
function TabManager:ClearSideTabs()
	-- Remove all side tab buttons except the template
	for _, button in pairs(self.ui.sideTabButtons) do
		button:Destroy()
	end

	-- Reset side tab buttons table
	self.ui.sideTabButtons = {}
	self.colors.originalSideTabColors = {}
end

-- Populate side tabs for the given top tab
function TabManager:PopulateSideTabs(topTabName)
	local sideTabs = MenuStructure:GetOrderedSideTabs(topTabName)
	local yOffset = 0

	for _, sideTab in ipairs(sideTabs) do
		-- Clone template for this side tab
		local newButton = self.ui.templates.sideTabButton:Clone()
		newButton.Name = sideTab.Name
		newButton.Text = sideTab.Name
		newButton.Visible = true

		-- Position properly
		newButton.Position = UDim2.new(0, 0, 0, yOffset)
		newButton.Parent = self.ui.sideTabContainer

		-- Store original color
		self.colors.originalSideTabColors[sideTab.Name] = newButton.BackgroundColor3

		-- Set tooltip if descriptions are enabled
		if MenuStructure.Config.ShowDescriptionsOnHover then
			newButton.ToolTip = sideTab.Description
		end

		-- Handle click
		newButton.MouseButton1Click:Connect(function()
			self:SelectSideTab(sideTab.Name)
		end)

		-- Register button
		self.ui.sideTabButtons[sideTab.Name] = newButton

		-- Update position for next button
		yOffset = yOffset + newButton.Size.Y.Offset + 5 -- 5 is the default padding
	end

	-- Update the canvas size if using a scrolling frame
	if self.ui.sideTabContainer:IsA("ScrollingFrame") then
		self.ui.sideTabContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end
end

-- Hide all content frames
function TabManager:HideAllContentFrames()
	for _, frame in pairs(self.ui.contentFrames) do
		frame.Visible = false
	end
end

-- Show a specific content frame
function TabManager:ShowContentFrame(frameName)
	-- Hide all content frames first
	self:HideAllContentFrames()

	-- Find the requested frame
	local contentFrame = self.ui.contentFrames[frameName]
	if contentFrame then
		contentFrame.Visible = true
		self:DebugPrint("Showing content frame:", frameName)

		-- Fire content shown event (can be used for lazy loading)
		local contentShown = Instance.new("BindableEvent")
		contentShown.Name = "ContentShown"
		contentShown.Event:Connect(function() end) -- Dummy connection
		contentShown:Fire(frameName)
		contentShown:Destroy()
	else
		Utility.Log(debugSystem, "warn", "Content frame not found:", frameName)
	end
end

-- Get current tab state
function TabManager:GetCurrentTabs()
	return {
		topTab = self.state.currentTopTab,
		sideTab = self.state.currentSideTab,
		lastSideTabPerTopTab = self.state.lastSideTabPerTopTab
	}
end

-- Export the module
return TabManager
