-- /ServerScriptService/SimpleDiceCollector

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Make all DiceSpawners non-clickable
local function makeSpawnerNonClickable(spawner)
	if spawner:IsA("BasePart") then
		spawner.CanQuery = false  -- Makes it not selectable/clickable
		spawner.CanTouch = false  -- Optional: prevents touch events too
	end
end

-- Apply to existing spawners
for _, spawner in pairs(CollectionService:GetTagged("DiceSpawner")) do
	makeSpawnerNonClickable(spawner)
end

-- Apply to any new spawners
CollectionService:GetInstanceAddedSignal("DiceSpawner"):Connect(makeSpawnerNonClickable)

-- Add click detectors to all dice
local function addClickDetector(die)
	if not die:FindFirstChildOfClass("ClickDetector") and die:GetAttribute("IsDie") then
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 32
		clickDetector.Parent = die

		clickDetector.MouseClick:Connect(function(player)
			-- Skip if die is no longer in workspace
			if not die:IsDescendantOf(workspace) then
				return
			end

			-- Create inventory folder if it doesn't exist
			if not player:FindFirstChild("DiceInventory") then
				local inventory = Instance.new("Folder")
				inventory.Name = "DiceInventory"
				inventory.Parent = player
			end

			-- Save original properties for later use
			die:SetAttribute("OriginalCFrame", tostring(die.CFrame))

			-- Make it non-collidable when in inventory
			die.CanCollide = false

			-- Move die to player's inventory
			die.Parent = player.DiceInventory

			-- Notify player
			local frameStyle = die:GetAttribute("frameStyle") or die:GetAttribute("FrameStyle") or "Classic"
			print(player.Name .. " collected " .. die.Name .. " with frameStyle: " .. frameStyle)
		end)
	end
end

-- Make sure dice are properly set up for clicking
local function setupDie(die)
	if die:IsA("BasePart") and die:GetAttribute("IsDie") then
		-- Ensure the die is clickable
		die.CanQuery = true

		-- Make the die slightly transparent so it looks collectible
		if die.Transparency < 0.1 then  -- Don't make already transparent dice more transparent
			die.Transparency = 0.1
		end

		-- Add the click detector
		addClickDetector(die)
	end
end

-- Set up existing dice
for _, die in pairs(workspace:GetDescendants()) do
	setupDie(die)
end

-- Set up new dice
workspace.DescendantAdded:Connect(function(descendant)
	task.wait() -- Small delay to ensure all properties are set
	setupDie(descendant)
end)

print("Simple dice collector initialized")
