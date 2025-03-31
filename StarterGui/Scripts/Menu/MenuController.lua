-- /StarterGui/Scripts/Menu/MenuController.lua
-- LocalScript that initializes and manages the menu tab system using TabManager and MenuStructure

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Require the necessary modules
local TabManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("TabManager"))
local MenuStructure = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("MenuStructure"))

-- Reference to the Menu ScreenGui
local menuGui = playerGui:WaitForChild("Menu")
local menuBackground = menuGui:WaitForChild("Background")
local mainFrame = menuGui:WaitForChild("Main")

-- Keep track of whether initialization has occurred
local isInitialized = false

-- Function to initialize the tab system
local function initializeTabSystem()
	if isInitialized then return end

	-- Debug output to help us understand the structure
	print("Initializing tab system...")
	print("Menu structure:")
	print("- TopTabs exists:", mainFrame:FindFirstChild("TopTabs") ~= nil)
	print("- SideTabs exists:", mainFrame:FindFirstChild("SideTabs") ~= nil)
	print("- Content exists:", mainFrame:FindFirstChild("Content") ~= nil)

	-- Check if TabManager is an object or a table with functions
	local initMethod = nil
	if typeof(TabManager) == "table" then
		-- Output available methods
		print("TabManager methods:")
		for key, value in pairs(TabManager) do
			if typeof(value) == "function" then
				print("- " .. key)
				if key == "new" or key == "Create" or key == "Init" then
					initMethod = key
				end
			end
		end
	end

	-- Try to initialize TabManager properly
	local tabManagerInstance = TabManager
	if initMethod then
		-- If there's an initialization method, call it
		print("Using initialization method:", initMethod)
		tabManagerInstance = TabManager[initMethod](mainFrame)
	end

	-- Try both approaches - as an object method and as a function
	local success = false

	-- Try approach 1: Call as an object method with colon syntax
	pcall(function()
		TabManager:Initialize(mainFrame, {debug = true})
		success = true
		print("Successfully initialized TabManager using colon syntax")
	end)

	-- If that failed, try approach 2: Call as a function with dot syntax
	if not success then
		pcall(function()
			TabManager.Initialize(tabManagerInstance, mainFrame, {debug = true})
			success = true
			print("Successfully initialized TabManager using dot syntax")
		end)
	end

	-- If both approaches failed, try direct property access
	if not success then
		-- Create a minimal implementation to get things working
		print("Both initialization approaches failed, using fallback implementation")

		-- Set up manual tab switching
		local topTabs = mainFrame:FindFirstChild("TopTabs")
		local sideTabs = mainFrame:FindFirstChild("SideTabs")
		local content = mainFrame:FindFirstChild("Content")

		if topTabs and sideTabs and content then
			-- Connect top tab buttons
			for _, topTabButton in pairs(topTabs:GetChildren()) do
				if topTabButton:IsA("TextButton") or topTabButton:IsA("ImageButton") then
					topTabButton.MouseButton1Click:Connect(function()
						-- Handle top tab selection
						print("Selected top tab:", topTabButton.Name)

						-- Here we would implement manual tab switching
						-- based on your MenuStructure
					end)
				end
			end
		else
			warn("Could not find required UI elements for fallback implementation")
		end
	end

	-- Mark as initialized
	isInitialized = true
	print("Menu tab system initialization completed")
end

-- Function to handle menu visibility changes
local function onMenuVisibilityChanged()
	if menuGui.Enabled then
		-- Make sure tab system is initialized when menu becomes visible
		if not isInitialized then
			initializeTabSystem()
		else
			-- Restore tab state logic would go here
			print("Menu reopened, would restore previous tab state")
		end
	end
end

-- Connect to menu visibility changes
menuGui:GetPropertyChangedSignal("Enabled"):Connect(onMenuVisibilityChanged)

-- Initialize if menu is already visible
if menuGui.Enabled then
	initializeTabSystem()
end

-- Log that the script has loaded
print("MenuController script loaded successfully")

