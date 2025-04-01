-- /StarterGui/Scripts/Menu/MenuController.lua
-- LocalScript that initializes and manages the menu tab system using TabManager and MenuStructure

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Require the necessary modules
local TabManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("TabManager"))
local MenuStructure = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("MenuStructure"))

-- Keep track of whether initialization has occurred
local isInitialized = false
local tabManagerInstance = nil

-- Function to safely wait for an object with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or 5 -- Default timeout of 5 seconds

	local child = parent:FindFirstChild(childName)
	if child then return child end

	local startTime = os.clock()
	local connection
	local childFound = false

	-- Create a promise-like system with timeout
	local thread = coroutine.running()

	connection = parent.ChildAdded:Connect(function(newChild)
		if newChild.Name == childName then
			childFound = true
			connection:Disconnect()
			connection = nil
			coroutine.resume(thread, newChild)
		end
	end)

	-- Wait for the child or timeout
	local result = nil
	task.spawn(function()
		while os.clock() - startTime < timeout and not childFound do
			-- Check again in case it was added between checks
			child = parent:FindFirstChild(childName)
			if child then
				childFound = true
				if connection then
					connection:Disconnect()
					connection = nil
				end
				result = child
				coroutine.resume(thread)
				return
			end
			task.wait(0.1)
		end

		-- Timeout occurred
		if connection then
			connection:Disconnect()
			connection = nil
		end
		coroutine.resume(thread)
	end)

	coroutine.yield()

	-- Return the found child or nil if timed out
	return result or parent:FindFirstChild(childName)
end

-- Function to get references to UI elements
local function getUIReferences()
	print("Trying to get UI references...")

	-- Try to find Interface
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("PlayerGui not found after 10 seconds")
		return nil
	end

	-- Try both possible paths for Menu
	local Interface = playerGui:FindFirstChild("Interface")
	local Menu = nil

	if Interface then
		Menu = safeWaitForChild(Interface, "Menu", 2)
	end

	-- If not found, look directly in PlayerGui
	if not Menu then
		Menu = safeWaitForChild(playerGui, "Menu", 2)
	end

	if not Menu then
		warn("Menu not found in either PlayerGui.Interface or PlayerGui directly")
		-- Create a retry mechanism by returning a function instead of nil
		return function()
			return getUIReferences()
		end
	end

	print("Found Menu:", Menu:GetFullName())

	-- Now get Background
	local Background = Menu:FindFirstChild("Background")
	if not Background then
		warn("Background not found in Menu")
		return nil
	end

	-- Now check for the required UI components
	local TopBar = Background:FindFirstChild("TopBar")
	local SideTabs = Background:FindFirstChild("SideTabs")
	local Content = Background:FindFirstChild("Content")

	if not (TopBar and SideTabs and Content) then
		warn("Missing required UI components in Background:")
		warn("- TopBar:", TopBar ~= nil)
		warn("- SideTabs:", SideTabs ~= nil)
		warn("- Content:", Content ~= nil)
		return nil
	end

	print("Found all required UI components")

	return {
		Interface = Interface,
		Menu = Menu,
		Background = Background
	}
end

-- Function to initialize the tab system
local function initializeTabSystem()
	if isInitialized then return end

	print("Attempting to initialize tab system...")

	-- Get UI references
	local references = getUIReferences()

	-- If references is a function, it means we need to retry
	if type(references) == "function" then
		print("Menu not found, will retry later...")
		return false
	end

	-- If we couldn't get the references, exit
	if not references then
		warn("Failed to get UI references, cannot initialize tab system")
		return false
	end

	local Background = references.Background
	local Menu = references.Menu

	-- Create a new TabManager instance
	tabManagerInstance = TabManager.new()

	-- Initialize the TabManager with the Background frame
	print("Initializing TabManager with Background:", Background:GetFullName())
	tabManagerInstance:Initialize(Background, {debug = true})

	-- Mark as initialized if successful
	if tabManagerInstance.state.isInitialized then
		isInitialized = true
		print("Menu tab system initialization completed successfully")

		-- Also set up a connection to Menu's visibility change
		Menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if Menu.Visible and tabManagerInstance and tabManagerInstance.state.currentTopTab then
				print("Menu visibility changed to visible, refreshing tabs")
				tabManagerInstance:SelectTopTab(tabManagerInstance.state.currentTopTab)
			end
		end)

		return true
	else
		warn("Menu tab system initialization failed")
		return false
	end
end

-- Function to periodically check for Menu and initialize tab system if it exists
local function startInitializationCheck()
	local success = false
	local attempts = 0
	local maxAttempts = 10

	local function checkAndInitialize()
		attempts = attempts + 1
		print("Initialization check attempt", attempts, "of", maxAttempts)

		success = initializeTabSystem()

		if success then
			print("Tab system initialized successfully on attempt", attempts)
			return true
		elseif attempts >= maxAttempts then
			warn("Failed to initialize tab system after", maxAttempts, "attempts")
			return true -- Stop trying
		else
			return false -- Continue trying
		end
	end

	-- Try immediately once
	if checkAndInitialize() then return end

	-- Set up a repeating check
	task.spawn(function()
		while not success and attempts < maxAttempts do
			task.wait(2) -- Check every 2 seconds
			if checkAndInitialize() then break end
		end
	end)
end

-- Start the initialization check when the script runs
startInitializationCheck()

-- Also connect to the Menu button if we can find it
task.spawn(function()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end

	local menuButtonPath = {"Interface", "HUD", "RightHUD", "MenuButton"}
	local currentParent = playerGui

	for _, name in ipairs(menuButtonPath) do
		currentParent = currentParent:FindFirstChild(name)
		if not currentParent then
			warn("Could not find", name, "while looking for MenuButton")
			return
		end
	end

	local menuButton = currentParent

	print("Found MenuButton, connecting click handler")

	menuButton.MouseButton1Click:Connect(function()
		print("MenuButton clicked")

		-- If system is not yet initialized, try to initialize it now
		if not isInitialized then
			print("Tab system not initialized yet, attempting now...")
			local success = initializeTabSystem()
			if not success then
				warn("Failed to initialize tab system on MenuButton click")
			end
		else
			print("Tab system already initialized")
		end
	end)
end)

print("MenuController script loaded successfully")
