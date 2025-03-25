-- /StarterGui/CombatHandler/FightButtonScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- References to the Interface components
local Interface = PlayerGui:WaitForChild("Interface")
local Combat = Interface:WaitForChild("Combat")
local DiceBoxPlayer = Combat:WaitForChild("DiceBoxPlayer")
local DiceBoxEnemy = Combat:WaitForChild("DiceBoxEnemy")

-- Create the Fight button if it doesn't exist
local function CreateFightButton()
	local existingButton = PlayerGui:FindFirstChild("FightButton")
	if existingButton and existingButton:IsA("ScreenGui") then
		return existingButton.MainButton -- Return the existing button
	end

	-- Create a ScreenGui for the button
	local buttonGui = Instance.new("ScreenGui")
	buttonGui.Name = "FightButton"
	buttonGui.ResetOnSpawn = false
	buttonGui.Parent = PlayerGui

	-- Create the button
	local fightButton = Instance.new("TextButton")
	fightButton.Name = "MainButton"
	fightButton.Size = UDim2.new(0, 150, 0, 50)
	fightButton.Position = UDim2.new(0.5, -75, 0.9, -25) -- Center bottom of screen
	fightButton.Text = "FIGHT!"
	fightButton.TextSize = 24
	fightButton.Font = Enum.Font.GothamBold
	fightButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- Red color
	fightButton.BorderSizePixel = 2
	fightButton.Parent = buttonGui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = fightButton

	return fightButton
end

-- Function to get dice references from DiceBoxes
local function GetLoadedDice()
	-- Check Player DiceBox
	local playerDieRef = DiceBoxPlayer.LoadedDie:FindFirstChild("DieReference")
	if not playerDieRef or not playerDieRef:IsA("ObjectValue") or not playerDieRef.Value then
		print("No player die loaded!")
		return nil, nil
	end

	-- Check Enemy DiceBox
	local enemyDieRef = DiceBoxEnemy.LoadedDie:FindFirstChild("DieReference")
	if not enemyDieRef or not enemyDieRef:IsA("ObjectValue") or not enemyDieRef.Value then
		print("No enemy die loaded!")
		return nil, nil
	end

	-- Return the actual die instances
	return playerDieRef.Value, enemyDieRef.Value
end

-- Create remote event for combat
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") or Instance.new("Folder", ReplicatedStorage)
combatEvents.Name = "CombatEvents"

local startCombatEvent = combatEvents:FindFirstChild("StartCombat") or Instance.new("RemoteEvent", combatEvents)
startCombatEvent.Name = "StartCombat"

-- Create and set up the fight button
local fightButton = CreateFightButton()

-- Connect the button click handler
fightButton.MouseButton1Click:Connect(function()
	print("Fight button clicked!")

	-- Get loaded dice
	local playerDie, enemyDie = GetLoadedDice()

	if playerDie and enemyDie then
		-- Emergency cleanup - force reset the combat flags before starting a new combat
		if playerDie:GetAttribute("IsInCombat") then
			playerDie:SetAttribute("IsInCombat", false)
		end

		if enemyDie:GetAttribute("IsInCombat") then
			enemyDie:SetAttribute("IsInCombat", false)
		end

		print("Starting combat between: " .. playerDie.Name .. " and " .. enemyDie.Name)

		-- Fire the remote event to start combat on the server
		startCombatEvent:FireServer(playerDie, enemyDie)
	else
		-- Create a notification to inform the player
		local notification = Instance.new("TextLabel")
		notification.Size = UDim2.new(0, 300, 0, 50)
		notification.Position = UDim2.new(0.5, -150, 0.7, 0)
		notification.Text = "Load dice in both slots first!"
		notification.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		notification.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification.TextSize = 20
		notification.Parent = PlayerGui

		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = notification

		-- Remove after 3 seconds
		game:GetService("Debris"):AddItem(notification, 3)
	end
end)

print("Fight button handler initialized")
