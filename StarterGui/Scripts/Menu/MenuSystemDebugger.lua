-- /StarterGui/Scripts/Menu/MenuSystemDebugger.lua
-- LocalScript that helps debug the Menu tab system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Function to print detailed information about the menu system
local function debugMenuSystem()
	print("\n=== Menu System Debug ===")

	-- Check if Menu exists and is visible
	local Interface = playerGui:FindFirstChild("Interface")
	local Menu = Interface and Interface:FindFirstChild("Menu") 

	print("Menu exists:", Menu ~= nil)
	print("Menu visible:", Menu and Menu.Visible)

	-- Check Background and components
	local Background = Menu and Menu:FindFirstChild("Background")
	print("Background exists:", Background ~= nil)

	if Background then
		local TopBar = Background:FindFirstChild("TopBar")
		local SideTabs = Background:FindFirstChild("SideTabs")
		local Content = Background:FindFirstChild("Content")

		print("TopBar exists:", TopBar ~= nil)
		print("SideTabs exists:", SideTabs ~= nil)
		print("Content exists:", Content ~= nil)

		-- Print TopBar children
		if TopBar then
			print("\nTopBar children:")
			for _, child in pairs(TopBar:GetChildren()) do
				print("- " .. child.Name .. " [" .. child.ClassName .. "]")

				-- Add click handler to buttons for debugging
				if (child:IsA("TextButton") or child:IsA("ImageButton")) and not child:GetAttribute("DebugHandlerAdded") then
					child:SetAttribute("DebugHandlerAdded", true)
					child.MouseButton1Click:Connect(function()
						print("TopTab button clicked:", child.Name)
					end)
					print("  (Added debug click handler)")
				end
			end
		end

		-- Print SideTabs children
		if SideTabs then
			print("\nSideTabs children:")
			for _, child in pairs(SideTabs:GetChildren()) do
				print("- " .. child.Name .. " [" .. child.ClassName .. "]")

				-- Add click handler to buttons for debugging
				if (child:IsA("TextButton") or child:IsA("ImageButton")) and child.Name ~= "Template" and not child:GetAttribute("DebugHandlerAdded") then
					child:SetAttribute("DebugHandlerAdded", true)
					child.MouseButton1Click:Connect(function()
						print("SideTab button clicked:", child.Name)
					end)
					print("  (Added debug click handler)")
				end
			end
		end

		-- Print Content children
		if Content then
			print("\nContent frames:")
			for _, child in pairs(Content:GetChildren()) do
				print("- " .. child.Name .. " [" .. child.ClassName .. "] Visible: " .. tostring(child.Visible))

				-- Add temporary visibility toggle functionality
				if (child:IsA("Frame") or child:IsA("ScrollingFrame")) and not child:GetAttribute("DebugHandlerAdded") then
					child:SetAttribute("DebugHandlerAdded", true)

					-- Create debug button that toggles visibility
					local debugButton = Instance.new("TextButton")
					debugButton.Size = UDim2.new(0, 100, 0, 30)
					debugButton.Position = UDim2.new(1, -110, 0, 10)
					debugButton.Text = "Toggle Visible"
					debugButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
					debugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					debugButton.Parent = child

					-- Function to toggle visibility
					debugButton.MouseButton1Click:Connect(function()
						child.Visible = not child.Visible
						print("Toggled visibility of " .. child.Name .. " to " .. tostring(child.Visible))
					end)

					print("  (Added debug visibility toggle)")
				end
			end
		end
	end

	-- Try to look for TabManager instance in the MenuController script
	local MenuController = playerGui:FindFirstChild("Scripts") and 
		playerGui.Scripts:FindFirstChild("Menu") and
		playerGui.Scripts.Menu:FindFirstChild("MenuController")

	if MenuController then
		print("\nMenuController script exists. TabManager status unknown (can't access script variables)")
	else
		print("\nMenuController script not found in expected location")
	end

	print("=== End Debug ===\n")
end

-- Add a debug button to the player's screen
local function createDebugButton()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuDebugger"
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 120, 0, 30)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Parent = screenGui

	local debugButton = Instance.new("TextButton")
	debugButton.Size = UDim2.new(1, -10, 1, -4)
	debugButton.Position = UDim2.new(0, 5, 0, 2)
	debugButton.Text = "Debug Menu"
	debugButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	debugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	debugButton.Parent = frame

	debugButton.MouseButton1Click:Connect(function()
		debugMenuSystem()
	end)

	-- Also create a button to manually call top tab selection
	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.new(0, 120, 0, 30)
	selectButton.Position = UDim2.new(0, 10, 0, 50)
	selectButton.Text = "Select Items Tab"
	selectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.Parent = screenGui

	selectButton.MouseButton1Click:Connect(function()
		-- Try to call TabManager.SelectTopTab through the command bar
		local success = pcall(function()
			-- Try to access global TabManager variable from MenuController
			local tabManager = _G.tabManagerInstance
			if tabManager then
				print("Found tabManagerInstance, attempting to select Items tab")
				tabManager:SelectTopTab("Items")
			else
				print("TabManager instance not found in global scope")
			end
		end)

		if not success then
			print("Failed to select Items tab")
		end
	end)

	print("Menu debug button created - click to run diagnostics")
end

-- Create the debug button
createDebugButton()

-- Run initial debug scan when the script loads
task.spawn(function()
	task.wait(3) -- Wait a few seconds to let other scripts initialize
	debugMenuSystem()
end)
