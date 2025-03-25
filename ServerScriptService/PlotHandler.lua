--// Services
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Requires
local Constants = require(ReplicatedStorage.ModuleScripts.ConstantsModule)
local Multipliers = require(ReplicatedStorage.Multipliers)
local Stat = require(ReplicatedStorage.Stat)

--// Variables
local Plots = workspace.Plots
local DropperParts

local TemplatePlot = ReplicatedStorage.TemplatePlot
local GameType = ReplicatedStorage["Game Settings"].GameType.Value

--// Functions
local function GetPreviousButton(buttonNumber)
	-- Get all available button numbers
	local availableButtons = {}
	for _, button in pairs(TemplatePlot.Buttons:GetChildren()) do
		local buttonNum = tonumber(button.Name)
		if buttonNum then
			table.insert(availableButtons, buttonNum)
		end
	end
	table.sort(availableButtons)

	-- Find the largest button number that's smaller than the current one
	local previousButton = nil
	for _, num in ipairs(availableButtons) do
		if num < buttonNumber then
			previousButton = num
		else
			break
		end
	end

	return previousButton
end

local function FormatButtonPrice(button)
	local priceTexts = {}
	local foundAnyCost = false

	for _, fruitType in ipairs(Constants.Fruit.Types) do
		local costValue = button:FindFirstChild("Cost" .. fruitType)
		if costValue and costValue.Value > 0 then
			foundAnyCost = true
			local currencySymbol = ""
			if fruitType == Constants.Fruit.Healing_Name then
				currencySymbol = "💚"
			elseif fruitType == Constants.Fruit.Attack_Name then
				currencySymbol = "🗡️"
			elseif fruitType == Constants.Fruit.Defense_Name then
				currencySymbol = "🛡️"
			elseif fruitType == Constants.Fruit.Elemental_Name then
				currencySymbol = "⭐"
			end

			table.insert(priceTexts, costValue.Value .. " " .. currencySymbol)
		end
	end

	if not foundAnyCost then
		warn("Button " .. button.Name .. " has no currency costs set!")
		return "Price Not Set"
	end

	return table.concat(priceTexts, "\n")
end

local function MoveButton(Button, Plot)
	local RelativeCFrame = TemplatePlot.Ground.CFrame:ToObjectSpace(Button.CFrame)
	Button.CFrame = Plot.Ground.CFrame:ToWorldSpace(RelativeCFrame)
end

local function HideButton(Button)
	Button.Transparency = 1
	Button.CanCollide = false
	Button.BillboardGui.Enabled = false
	Button.CanTouch = false
end

local function ShowButton(Button)
	Button.Transparency = 0
	Button.CanCollide = true
	Button.BillboardGui.Enabled = true
	Button.CanTouch = true
end

local function MoveUpgrade(Upgrade, Plot)
	local RelativeCFrame = TemplatePlot.Ground.CFrame:ToObjectSpace(Upgrade:GetPivot())
	Upgrade:PivotTo(Plot.Ground.CFrame:ToWorldSpace(RelativeCFrame))
end

local function CanAffordUpgrade(Player, Button)
	local foundAnyCost = false

	for _, fruitType in ipairs(Constants.Fruit.Types) do
		local costValue = Button:FindFirstChild("Cost" .. fruitType)
		if costValue and costValue.Value > 0 then
			foundAnyCost = true
			local playerCurrency = Stat.Get(Player, fruitType)
			if playerCurrency.Value < costValue.Value then
				return false
			end
		end
	end

	if not foundAnyCost then
		warn("Button " .. Button.Name .. " has no currency costs set!")
		return false
	end

	return true
end

local function DeductUpgradeCost(Player, Button)
	for _, fruitType in ipairs(Constants.Fruit.Types) do
		local costValue = Button:FindFirstChild("Cost" .. fruitType)
		if costValue and costValue.Value > 0 then
			local playerCurrency = Stat.Get(Player, fruitType)
			playerCurrency.Value -= costValue.Value
		end
	end
end

local function IsButtonUnlockable(Player, button)
	-- Check the UnlockedByButton value
	local requiredButtonNum = button.UnlockedByButton.Value
	if requiredButtonNum == 0 then
		return true -- No requirement, always unlockable
	end

	-- Check if the required button is purchased
	local requiredButtonStat = Stat.Get(Player, "Button" .. requiredButtonNum)
	if not requiredButtonStat then
		-- Create the stat if it doesn't exist
		local NewButton = Instance.new("BoolValue")
		NewButton.Name = "Button" .. requiredButtonNum
		NewButton.Parent = Stat.GetDataFolder(Player).Buttons
		requiredButtonStat = NewButton
	end

	return requiredButtonStat.Value
end

local function LoadPlot(Player, Plot)
	if not Plots:FindFirstChild(Plot) then return end

	-- Create Button Values if they don't exist
	for _, buttonObj in pairs(TemplatePlot.Buttons:GetChildren()) do
		local buttonNum = tonumber(buttonObj.Name)
		if not buttonNum then continue end

		if not Stat.Get(Player, "Button" .. buttonNum) then
			local NewButton = Instance.new("BoolValue")
			NewButton.Name = "Button" .. buttonNum
			NewButton.Parent = Stat.GetDataFolder(Player).Buttons
		end
	end

	-- Load regular upgrade buttons
	for _, buttonObj in pairs(TemplatePlot.Buttons:GetChildren()) do
		local buttonNum = tonumber(buttonObj.Name)
		if not buttonNum then continue end

		local Button = Stat.Get(Player, "Button" .. buttonNum)
		if not Button.Value then
			local NewButton = buttonObj:Clone()
			MoveButton(NewButton, Plots[Plot])

			-- Check if button has any currency costs set
			local hasCosts = false
			for _, fruitType in ipairs(Constants.Fruit.Types) do
				local costValue = NewButton:FindFirstChild("Cost" .. fruitType)
				if costValue then
					hasCosts = true
				end
			end

			if not hasCosts then
				warn("Button", buttonNum, "has no currency costs set!")
			end

			NewButton.BillboardGui.Price.Text = FormatButtonPrice(NewButton)

			if GameType == "Modern" then 
				local incomeType = NewButton.IncomeFruitType
				if incomeType then
					local currencySymbol = ""
					if incomeType.Value == Constants.Fruit.Healing_Name then
						currencySymbol = "💚"
					elseif incomeType.Value == Constants.Fruit.Attack_Name then
						currencySymbol = "🗡️"
					elseif incomeType.Value == Constants.Fruit.Defense_Name then
						currencySymbol = "🛡️"
					elseif incomeType.Value == Constants.Fruit.Elemental_Name then
						currencySymbol = "⭐"
					end
					NewButton.BillboardGui.Income.Text = "+" .. NewButton.Income.Value .. currencySymbol .. " /s"
				end
			end

			NewButton.Parent = Plots[Plot].Buttons

			-- Check if this button should be visible based on UnlockedByButton value
			if not IsButtonUnlockable(Player, NewButton) then
				HideButton(NewButton)

				-- Set up monitoring of required button's state
				local requiredButtonNum = NewButton.UnlockedByButton.Value
				local requiredStat = Stat.Get(Player, "Button" .. requiredButtonNum)
				local connection
				connection = requiredStat.Changed:Connect(function(newValue)
					if newValue then
						ShowButton(NewButton)
						connection:Disconnect()
					end
				end)
			end

			-- Setup touch handling for purchases
			local Touched = false
			NewButton.Touched:Connect(function(Hit)
				if Touched then return end
				if not Hit.Parent:FindFirstChild("Humanoid") then return end
				if Players:GetPlayerFromCharacter(Hit.Parent) == Player then
					-- Verify button is unlockable
					if not IsButtonUnlockable(Player, NewButton) then
						return
					end

					if not CanAffordUpgrade(Player, NewButton) then
						-- Flash price text implementation would go here
						return
					end

					Touched = true
					DeductUpgradeCost(Player, NewButton)
					Button.Value = true

					local NewUpgrade = TemplatePlot.Upgrades[buttonNum]:Clone()
					MoveUpgrade(NewUpgrade, Plots[Plot])
					NewUpgrade.Parent = Plots[Plot].Upgrades       
					NewButton:Destroy()

					if NewUpgrade:FindFirstChild("Conveyor") then
						NewUpgrade.Conveyor.ConveyorScript.Enabled = true
					elseif NewUpgrade:FindFirstChild("Killpart") then
						NewUpgrade.KillHandler.Enabled = true
					end
				end
			end)
		else
			-- Player already owns this upgrade
			local NewUpgrade = TemplatePlot.Upgrades[buttonNum]:Clone()
			MoveUpgrade(NewUpgrade, Plots[Plot])
			NewUpgrade.Parent = Plots[Plot].Upgrades

			if NewUpgrade:FindFirstChild("Conveyor") then
				NewUpgrade.Conveyor.ConveyorScript.Enabled = true
			elseif NewUpgrade:FindFirstChild("Killpart") then
				NewUpgrade.KillHandler.Enabled = true
			end
		end
	end
end

local function ClearPlot(Plot)
	Plot = Plots[Plot]

	for _, Button in Plot.Buttons:GetChildren() do
		Button:Destroy()
	end

	for _, RobuxButton in Plot.RobuxButtons:GetChildren() do
		RobuxButton:Destroy()
	end

	for _, Upgrade in Plot.Upgrades:GetChildren() do
		Upgrade:Destroy()
	end
end

--// Player stuff ig
local function OnPlayerRemoving(Player)
	local Plot = Player.TempValues.Plot.Value
	if Plot == 0 then return end -- Player has no plot

	local PlotInstance = Plots[Plot]
	PlotInstance.Claimed.Value = "None"
	PlotInstance.Door.Claim.SurfaceGui.TextLabel.Text = "Claim"

	ClearPlot(Plot)
	Player.TempValues.Plot.Value = 0

	-- Remove player's DropperParts folder
	local PlayerDropperPartsFolder = workspace.DropperParts:FindFirstChild(Player.Name .. "-DropperParts")
	if PlayerDropperPartsFolder then
		PlayerDropperPartsFolder:Destroy()
	end
end

function OnPlayerAdded(Player)
	if not Stat.WaitForLoad(Player) then return end -- player left!

	-- Debug print to check data structure
	print("=== Player Data Structure ===")
	local dataFolder = Stat.GetDataFolder(Player)
	if dataFolder then
		print("Stats folder exists:", dataFolder:FindFirstChild("Stats") ~= nil)
		for _, stat in dataFolder:GetDescendants() do
			print(stat:GetFullName(), stat:IsA("NumberValue") and stat.Value or "")
		end
	else
		print("Data folder not found for player")
	end    

	local Plot = Player.TempValues.Plot

	Plot.Changed:Connect(function()
		LoadPlot(Player, Plot.Value)
	end)

	Stat.Get(Player, "Rebirth").Changed:Connect(function()
		ClearPlot(Plot.Value)
		LoadPlot(Player, Plot.Value)
	end)

	-- Create Button Values
	for i = 1, #TemplatePlot.Buttons:GetChildren() do
		if not Stat.Get(Player, "Button"..i) then
			local NewButton = Instance.new("BoolValue")
			NewButton.Name = "Button"..i
			NewButton.Parent = Stat.GetDataFolder(Player).Buttons
		end
	end

	if GameType == "Classic" then
		-- Create DropperParts folder for player
		local PlayerDropperPartsFolder = Instance.new("Folder")
		PlayerDropperPartsFolder.Name = Player.Name .. "-DropperParts"
		PlayerDropperPartsFolder.Parent = DropperParts
	elseif GameType == "Modern" then
		-- For modern tycoons, handle income for each currency type
		local TemplateButtons = ReplicatedStorage.TemplatePlot.Buttons:GetChildren()

		while task.wait(1) do
			if Player.Parent == nil then break end
			if Player.TempValues.Plot.Value == 0 then continue end -- Player hasn't claimed a tycoon

			-- Create a table to track income for each currency type
			local Incomes = {
				[Constants.Fruit.Healing_Name] = 0,
				[Constants.Fruit.Attack_Name] = 0,
				[Constants.Fruit.Defense_Name] = 0,
				[Constants.Fruit.Elemental_Name] = 0,
				["Money"] = 0  -- Keep money for backward compatibility
			}

			-- Calculate income for each owned button
			for _, Button in TemplateButtons do
				if not Stat.Get(Player, "Button"..Button.Name).Value then continue end -- Player doesn't own this

				local fruitType = Button:FindFirstChild("IncomeFruitType")
				if fruitType and Button:FindFirstChild("Income") then
					local currencyType = fruitType.Value
					if Incomes[currencyType] ~= nil then
						Incomes[currencyType] += Button.Income.Value
					else
						warn("Invalid currency type:", currencyType, "for button:", Button.Name)
					end
				end
			end

			-- Apply income for each currency type
			for currencyType, amount in pairs(Incomes) do
				if amount > 0 then
					local stat = Stat.Get(Player, currencyType)
					if stat then
						-- Apply multiplier only to Money currency
						if currencyType == "Money" then
							stat.Value += amount * Multipliers.GetMoneyMultiplier(Player)
						else
							stat.Value += amount
						end
					else
						warn("Could not find stat for currency:", currencyType)
					end
				end
			end
		end
	end
end

--// Doors
local function CreateDoor(v, Hit)
	if v.Claimed.Value ~= "None" then return end -- Already Claimed

	if Hit.Parent:FindFirstChild("Humanoid") then -- Check if it is a player
		local Player = Players:GetPlayerFromCharacter(Hit.Parent)

		if Player.TempValues.Plot.Value ~= 0 then return end -- Player already claimed a plot

		--// Update tycoon so it become's the player's
		Player.TempValues.Plot.Value = tonumber(v.Name)
		v.Claimed.Value = Player.Name
		v.Door.Claim.SurfaceGui.TextLabel.Text = Player.Name.."'s Plot"
	end
end

local function CreateDoors()
	for _,v in Plots:GetChildren() do
		v.Door.Claim.Touched:Connect(function(Hit)
			CreateDoor(v, Hit)
		end)
	end
end

--// Dropper Parts Folder
local function CreateDropperPartsFolder()
	if GameType == "Classic" then
		DropperParts = Instance.new("Folder")
		DropperParts.Name = "DropperParts"
		DropperParts.Parent = workspace
	end
end

--// Calls
CreateDoors()
CreateDropperPartsFolder()

--// Connections
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
