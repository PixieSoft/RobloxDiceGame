-- /ServerScriptService/Tests/TestBoosters.lua
-- Simple script that creates a small window showing booster values with +1 buttons

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Get the Boosters module for adding boosters
local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)

local function CreateSimpleBoosterDisplay(player)
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoosterTestDisplay"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Create background frame
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 250, 0, 400)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 2
	frame.Parent = screenGui

	-- Add title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.BorderSizePixel = 0
	title.Text = "Booster Values"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Create scrolling frame for booster list
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "BoosterList"
	scrollFrame.Size = UDim2.new(1, -10, 1, -40)
	scrollFrame.Position = UDim2.new(0, 5, 0, 35)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.Parent = frame

	-- Store references to row containers
	local boosterRows = {}

	-- Function to update booster list
	local function UpdateBoosterList()
		-- Check for leaderstats.Boosters
		local boostersFolder = player:FindFirstChild("leaderstats") and 
			player.leaderstats:FindFirstChild("Boosters")

		-- Clear display if no booster folder exists
		if not boostersFolder then
			-- Remove all existing rows
			for _, child in ipairs(scrollFrame:GetChildren()) do
				child:Destroy()
			end
			boosterRows = {}

			-- Show "no data" message
			local noDataLabel = Instance.new("TextLabel")
			noDataLabel.Name = "NoDataLabel"
			noDataLabel.Size = UDim2.new(1, 0, 0, 30)
			noDataLabel.Position = UDim2.new(0, 0, 0, 0)
			noDataLabel.BackgroundTransparency = 1
			noDataLabel.Text = "No leaderstats.Boosters found"
			noDataLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			noDataLabel.TextSize = 14
			noDataLabel.Font = Enum.Font.Gotham
			noDataLabel.Parent = scrollFrame
			return
		end

		-- Get all boosters in the folder
		local currentBoosters = {}
		for _, child in ipairs(boostersFolder:GetChildren()) do
			currentBoosters[child.Name] = child
		end

		-- Remove rows for boosters that no longer exist
		for boosterName, row in pairs(boosterRows) do
			if not currentBoosters[boosterName] then
				if row and row.Parent then
					row:Destroy()
				end
				boosterRows[boosterName] = nil
			end
		end

		-- Sort booster names (keeping active status indicators at the bottom)
		local regularBoosters = {}
		local activeIndicators = {}

		for boosterName, _ in pairs(currentBoosters) do
			if boosterName:match("_Active$") then
				table.insert(activeIndicators, boosterName)
			else
				table.insert(regularBoosters, boosterName)
			end
		end

		table.sort(regularBoosters)
		table.sort(activeIndicators)

		-- Combine sorted lists with regular boosters first
		local sortedBoosterNames = {}
		for _, name in ipairs(regularBoosters) do
			table.insert(sortedBoosterNames, name)
		end
		for _, name in ipairs(activeIndicators) do
			table.insert(sortedBoosterNames, name)
		end

		-- Update or create rows for current boosters
		local yPos = 0
		for _, boosterName in ipairs(sortedBoosterNames) do
			local booster = currentBoosters[boosterName]

			-- Skip creating +1 buttons for active indicators
			local isActiveIndicator = boosterName:match("_Active$")

			-- Create or update row
			local row = boosterRows[boosterName]
			if not row or not row.Parent then
				-- Create new row container
				row = Instance.new("Frame")
				row.Name = boosterName .. "_Row"
				row.Size = UDim2.new(1, 0, 0, 28)
				row.BackgroundTransparency = 0.9
				row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				row.BorderSizePixel = 1
				row.BorderColor3 = Color3.fromRGB(60, 60, 60)
				row.Parent = scrollFrame
				boosterRows[boosterName] = row

				-- Create label
				local label = Instance.new("TextLabel")
				label.Name = "NameLabel"
				label.Size = UDim2.new(isActiveIndicator and 1 or 0.8, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.TextSize = 14
				label.Font = Enum.Font.Gotham
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.Parent = row

				-- Create +1 button for regular boosters
				if not isActiveIndicator then
					local button = Instance.new("TextButton")
					button.Name = "PlusButton"
					button.Size = UDim2.new(0.2, 0, 1, 0)
					button.Position = UDim2.new(0.8, 0, 0, 0)
					button.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
					button.BackgroundTransparency = 0.7
					button.BorderSizePixel = 1
					button.Text = "+1"
					button.TextColor3 = Color3.fromRGB(255, 255, 255)
					button.TextSize = 14
					button.Font = Enum.Font.GothamBold
					button.Parent = row

					-- Button click handler
					button.MouseButton1Click:Connect(function()
						-- Try to add 1 to the booster using the Boosters module
						Boosters.GiveBooster(player, boosterName, 1)
					end)
				end
			end

			-- Update the label text
			local label = row:FindFirstChild("NameLabel")
			if label then
				if isActiveIndicator then
					-- This is an active status indicator
					local baseName = boosterName:gsub("_Active$", "")
					label.Text = "⚡ " .. baseName .. ": " .. booster.Value .. "s"
					label.TextColor3 = Color3.fromRGB(100, 255, 100)
				else
					-- This is a regular booster count
					label.Text = "🔹 " .. boosterName .. ": " .. booster.Value
					label.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end

			-- Position the row
			row.Position = UDim2.new(0, 0, 0, yPos)
			yPos = yPos + 30
		end
	end

	-- Set up event connections to detect changes
	local function SetupMonitoring()
		-- Check if leaderstats already exists
		if player:FindFirstChild("leaderstats") then
			-- Listen for Boosters folder being added
			player.leaderstats.ChildAdded:Connect(function(child)
				if child.Name == "Boosters" then
					-- Call update when Boosters folder is added
					UpdateBoosterList()

					-- Set up change detection for the Boosters folder
					child.ChildAdded:Connect(UpdateBoosterList)
					child.ChildRemoved:Connect(UpdateBoosterList)

					-- Listen for changes to values
					for _, booster in ipairs(child:GetChildren()) do
						booster.Changed:Connect(UpdateBoosterList)
					end

					-- Also connect to future boosters
					child.ChildAdded:Connect(function(newBooster)
						newBooster.Changed:Connect(UpdateBoosterList)
					end)
				end
			end)

			-- Check for existing Boosters folder
			local boostersFolder = player.leaderstats:FindFirstChild("Boosters")
			if boostersFolder then
				-- Set up change detection for the Boosters folder
				boostersFolder.ChildAdded:Connect(UpdateBoosterList)
				boostersFolder.ChildRemoved:Connect(UpdateBoosterList)

				-- Listen for changes to values
				for _, booster in ipairs(boostersFolder:GetChildren()) do
					booster.Changed:Connect(UpdateBoosterList)
				end

				-- Also connect to future boosters
				boostersFolder.ChildAdded:Connect(function(newBooster)
					newBooster.Changed:Connect(UpdateBoosterList)
				end)
			end
		end

		-- Listen for leaderstats being added
		player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then
				-- Same monitoring setup as above
				child.ChildAdded:Connect(function(statsChild)
					if statsChild.Name == "Boosters" then
						UpdateBoosterList()
						statsChild.ChildAdded:Connect(UpdateBoosterList)
						statsChild.ChildRemoved:Connect(UpdateBoosterList)

						-- Listen for changes to values
						for _, booster in ipairs(statsChild:GetChildren()) do
							booster.Changed:Connect(UpdateBoosterList)
						end

						-- Also connect to future boosters
						statsChild.ChildAdded:Connect(function(newBooster)
							newBooster.Changed:Connect(UpdateBoosterList)
						end)
					end
				end)
			end
		end)
	end

	-- Set up a refresh button
	local refreshButton = Instance.new("TextButton")
	refreshButton.Name = "RefreshButton"
	refreshButton.Size = UDim2.new(0.4, 0, 0, 25)
	refreshButton.Position = UDim2.new(0.3, 0, 0, 3)
	refreshButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	refreshButton.BackgroundTransparency = 0.5
	refreshButton.BorderSizePixel = 1
	refreshButton.Text = "🔄 Refresh"
	refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshButton.TextSize = 14
	refreshButton.Font = Enum.Font.Gotham
	refreshButton.Parent = title
	refreshButton.MouseButton1Click:Connect(UpdateBoosterList)

	-- Do initial update
	UpdateBoosterList()

	-- Set up change detection
	SetupMonitoring()

	-- Also do a periodic refresh just in case we miss any changes
	local updateConnection = RunService.Heartbeat:Connect(function()
		if tick() % 3 < 0.1 then -- Refresh every 3 seconds
			UpdateBoosterList()
		end
	end)

	-- Clean up when destroyed
	screenGui.AncestryChanged:Connect(function(_, newParent)
		if not newParent then
			updateConnection:Disconnect()
		end
	end)

	return screenGui
end

-- Create displays for all existing players
for _, player in ipairs(Players:GetPlayers()) do
	CreateSimpleBoosterDisplay(player)
end

-- Create displays for new players
Players.PlayerAdded:Connect(function(player)
	-- Wait a moment for the player to fully load
	task.wait(2)
	CreateSimpleBoosterDisplay(player)
end)

print("Booster test display loaded with +1 buttons")
