--// Services
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

--// Imports
local Short = require(ReplicatedStorage.Short)
local Stat = require(ReplicatedStorage.Stat)

--// Variables
local Player = Players.LocalPlayer

Stat.WaitForLoad() -- Wait's until stats are loaded

local Remotes = ReplicatedStorage.RemoteEvents

local Interface = Player.PlayerGui:WaitForChild("Interface")
local Leftside = Interface.Leftside
local HUD = Interface.HUD

repeat task.wait() until #ReplicatedStorage.TemplatePlot.Buttons:GetChildren() > 0
local AmountOfButtons = #ReplicatedStorage.TemplatePlot.Buttons:GetChildren()

--// Stats
local Rebirth = Stat.Get("Rebirth")
local Money = Stat.Get("Money")
local Tokens = Stat.Get("Tokens")

--// Main
--------- Sound ---------
local function PlaySound(Sound: Sound)
	task.spawn(function()
		local NewSound = Sound:Clone()
		NewSound.Parent = game:GetService("SoundService")
		NewSound:Play()
		task.wait(5)
		NewSound:Destroy()
	end)
end

--------- Currency Label ---------
local function OnMoneyChanged()
	HUD.Counters.MoneyFrame.Main.Text = Short.toSuffix(Money.Value)
end

local function OnTokensChanged()
	HUD.Counters.TokenFrame.TokenLabel.Text = Short.toSuffix(Tokens.Value)
end

--------- Particle ----------
local function SetupButtons()
	for i = 1, AmountOfButtons do
		local Stat = Stat.Get("Button"..i)

		Stat.Changed:Connect(function()
			if not Stat.Value then return end

			local Confetti = script.Confetti:Clone()
			Confetti.Position = Player.Character.HumanoidRootPart.Position
			Confetti.Parent = workspace

			Confetti.Attachment.Particle:Emit(45)
			PlaySound(script.Reward)

			task.wait(3)
			Confetti:Destroy()		
		end)
	end
end

--------- User Interface ---------
local function CreateSideButtons()
	Leftside.RebirthBT.Button.MouseButton1Click:Connect(function()
		HUD.Rebirth.Visible = not HUD.Rebirth.Visible
	end)

	Leftside.ShopBT.Button.MouseButton1Click:Connect(function()
		HUD.Shop.Visible = not HUD.Shop.Visible
	end)
end

local function CreateCloseButtons()
	HUD.Rebirth.Close.Button.MouseButton1Click:Connect(function()
		HUD.Rebirth.Visible = false
	end)

	HUD.Shop.Close.Button.MouseButton1Click:Connect(function()
		HUD.Shop.Visible = false
	end)
end

--// Rebirth Frame
local function OnRebirthBuy()
	HUD.Rebirth.Visible = false
	Remotes.BuyRebirth:FireServer()
end

local PriceStr = 'To Rebirth you need <font color="rgb(15, 208, 12)">%s </font>💸'
local MultiStr = 'Current Multiplier:  <font color="rgb(15, 208, 12)">x%s </font>💸'

local RebirthPrice = ReplicatedStorage["Game Settings"].Balancing.RebirthPrice.Value

local function UpdateRebirthUI()
	local RebirthVal = Stat.Get("Rebirth").Value

	local Price = Short.toSuffix(RebirthPrice * (RebirthVal + 1))
	HUD.Rebirth.Price.Text = string.format(PriceStr, Price)

	local Multi = 1 + RebirthVal * 0.5 -- 1 + 0.5x per rebirth
	HUD.Rebirth.Multi.Text = string.format(MultiStr, Multi)
end

--// Shop Frame
-- Credits to Panko_Danko for creating this!

local Template = HUD.Shop.ObjectHolder.GamepassFrame
Template.Visible = false

for _, GamepassInstance in ReplicatedStorage.GamepassIds:GetChildren() do 
	local Id = GamepassInstance.Value
	local Info = MarketPlaceService:GetProductInfo(Id, Enum.InfoType.GamePass)

	local Frame = Template:Clone()
	Frame.Title.Text = Info.Name
	Frame.Description.Text = Info.Description
	Frame.Price.Text = Info.PriceInRobux .. " Robux"
	Frame.Icon.Image = "rbxassetid://"..Info.IconImageAssetId

	if not MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, Id) then
		Frame.BuyButton.MouseButton1Click:Connect(function()
			MarketPlaceService:PromptGamePassPurchase(Player, Id)
		end)
	else
		Frame.BuyButton.Text = "Bought"
		Frame.BuyButton.BackgroundColor3 = Color3.fromRGB(7, 136, 0)
		Frame.BuyButton.UIStroke1.Color = Color3.fromRGB(0, 0, 0)
		Frame.BuyButton.UIStroke2.Color = Color3.fromRGB(0, 0, 0)
	end

	Frame.Visible = true
	Frame.Parent = HUD.Shop.ObjectHolder
end

--// Connections
Money.Changed:Connect(OnMoneyChanged)
Tokens.Changed:Connect(OnTokensChanged)
HUD.Rebirth.Buy.Button.MouseButton1Click:Connect(OnRebirthBuy)
Rebirth.Changed:Connect(UpdateRebirthUI)

--// Calls
OnMoneyChanged()
OnTokensChanged()
UpdateRebirthUI()
SetupButtons() -- Workspace
CreateSideButtons() -- UI
CreateCloseButtons() -- UI
