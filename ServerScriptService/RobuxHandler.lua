--// Services
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Imports
local Stat = require(ReplicatedStorage.Stat)

--// Variables
local GamepassIds = ReplicatedStorage.GamepassIds

--// Functions
local function AwardTool(Player, ToolName)
	local Tool = script:FindFirstChild(ToolName):Clone()

	if not Tool then
		warn("Error awarding gamepass reward, "..ToolName.." does not exist!")
		return -- An error occured, stop the function from running
	end

	Tool:Clone().Parent = Player.Backpack	
end

local function CreateGamepasses(Player)
	local Data = Stat.GetDataFolder(Player)
	for _, GamepassInstance in GamepassIds:GetChildren() do
		local GPVal = Data.Other:FindFirstChild(GamepassInstance.Name)

		-- Create a gamepass if it doesn't exist
		if not GPVal then
			GPVal = Instance.new("BoolValue")
			GPVal.Name = GamepassInstance.Name
			GPVal.Parent = Data.Other
		end

		if MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamepassInstance.Value) then
			GPVal.Value = true
		end 
	end
end

local function OnCharacterAdded(Character) -- Function loads in the tools
	local Player = Players:GetPlayerFromCharacter(Character)

	for _, GamepassInstance in GamepassIds:GetChildren() do
		if not script:FindFirstChild(GamepassInstance.Name) then continue end -- Gamepass has no tool

		if Stat.Get(Player, GamepassInstance.Name).Value == false then continue end

		AwardTool(Player, GamepassInstance.Name)
	end
end

function OnPlayerAdded(Player)
	Stat.WaitForLoad(Player)
	CreateGamepasses(Player) -- Creates the values

	local Character = Player.Character or Player.CharacterAdded:Wait()

	Player.CharacterAdded:Connect(OnCharacterAdded)
	OnCharacterAdded(Character)
end

function OnGamepassPurchaseFinished(Player, GamepassId, Purchased)
	if not Purchased then return end

	for _, GamepassInstance in GamepassIds:GetChildren() do
		if GamepassInstance.Value == GamepassId then
			AwardTool(Player, GamepassInstance.Name)
			break
		end
	end
end

function ProcessReceipt(ReceiptInfo)
	local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)

	for _, Button in ReplicatedStorage.TemplatePlot.RobuxButtons:GetChildren() do
		if Button.ProductId.Value == ReceiptInfo.ProductId then
			local Amount = Button.Amount.Value
			local Money = Stat.Get(Player, "Money")
			Money.Value += Amount
			break
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

--// Main
Players.PlayerAdded:Connect(OnPlayerAdded)

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(OnGamepassPurchaseFinished)

MarketPlaceService.ProcessReceipt = ProcessReceipt
