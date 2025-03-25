-- FruitManagerModule.lua
local FruitManagerModule = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Asset References
local AssetsFolder = ReplicatedStorage:WaitForChild("Assets")
local FruitFolder = AssetsFolder:WaitForChild("Fruit")
local Modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local Constants = require(Modules:WaitForChild("ConstantsModule"))
local CustomEvents = require(Modules:WaitForChild("CustomEventsModule")) 

-- Private variables
local fruitCache = {}

--[[ Cache Management ]]--
function FruitManagerModule.PreloadFruits()
	for _, fruitModel in ipairs(FruitFolder:GetChildren()) do
		if fruitModel:IsA("BasePart") or fruitModel:IsA("Model") then
			fruitCache[fruitModel.Name] = fruitModel:Clone()
			fruitCache[fruitModel.Name].Parent = nil
		end
	end
end

function FruitManagerModule.GetFruitClone(fruitName)
	local template = fruitCache[fruitName]
	if template then
		return template:Clone()
	end
	return nil
end

function FruitManagerModule.CleanupFruit(fruit)
	if fruit then
		fruit:Destroy()
	end
end

--[[ Fruit Physics and Setup ]]--
function FruitManagerModule.ScaleFruitToFit(fruit, spawner)
	local fruitSize = fruit.Size
	local spawnerSize = spawner.Size

	local scaleX = spawnerSize.X / fruitSize.X
	local scaleY = spawnerSize.Y / fruitSize.Y
	local scaleZ = spawnerSize.Z / fruitSize.Z

	local scale = math.min(scaleX, scaleY, scaleZ) * 0.9
	fruit.Size = fruit.Size * scale
end

function FruitManagerModule.SetupFruitPhysics(fruit, spawner)
	FruitManagerModule.ScaleFruitToFit(fruit, spawner)
	fruit.Position = spawner.Position
	fruit.Anchored = true

	if fruit:IsA("BasePart") then
		fruit.CanCollide = false
	else
		for _, part in ipairs(fruit:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end

function FruitManagerModule.SetupFruitPickup(fruit, activeFlag)
	-- Create a flag to track pickup state for this specific fruit instance
	-- This prevents multiple touches from granting fruit multiple times
	local pickedUpValue = Instance.new("BoolValue")
	pickedUpValue.Name = "PickedUp"
	pickedUpValue.Value = false
	pickedUpValue.Parent = fruit

	-- Flag to prevent simultaneous touch processing
	-- This adds extra protection against potential race conditions
	local isProcessingTouch = false

	-- Set up the main touch detection system
	local touchConnection = fruit.Touched:Connect(function(hit)
		-- Validate pickup hasn't already occurred and isn't currently processing
		local pickedUp = fruit:FindFirstChild("PickedUp")
		if not pickedUp or isProcessingTouch or pickedUp.Value then return end

		isProcessingTouch = true

		-- Verify the touch came from a player character
		if hit:IsA("BasePart") and hit.Parent:FindFirstChild("Humanoid") then
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if player then
				-- Get the stat instance from our central stat management system
				-- This ensures we're updating the same value that the tycoon system checks
				local playerFruitStat = require(game.ReplicatedStorage.Stat).Get(player, fruit.Name)
				if playerFruitStat then
					-- Mark as picked up immediately to prevent double-pickup edge cases
					pickedUp.Value = true

					-- Update the player's fruit count in the Stats system
					local spawnAmount = fruit:GetAttribute("SpawnAmount") or 1
					playerFruitStat.Value += spawnAmount

					-- Update spawner state if this fruit came from a spawner
					if activeFlag and activeFlag.Parent then
						activeFlag.Value = false
					end

					-- Notify other systems about the pickup
					-- This allows for effects, achievements, or other systems to respond
					local OnFruitPickup = ReplicatedStorage:FindFirstChild("OnFruitPickup")
					if OnFruitPickup then
						OnFruitPickup:Fire(
							fruit.Name,
							spawnAmount,
							player.Name,
							fruit.Position
						)
					end

					-- Small delay to ensure all systems have time to respond
					task.wait(0.01)

					-- Remove the fruit from the game world
					FruitManagerModule.CleanupFruit(fruit)
				end
			end
		end

		isProcessingTouch = false
	end)

	-- Monitor if the fruit gets removed from the game
	-- This ensures spawners know when their fruit is gone, even if not picked up
	local ancestryConnection = fruit.AncestryChanged:Connect(function(_, parent)
		if not parent and activeFlag and activeFlag.Parent then
			activeFlag.Value = false
		end
	end)

	-- Clean up event connections when fruit is destroyed
	-- This prevents memory leaks from lingering connections
	fruit.Destroying:Connect(function()
		touchConnection:Disconnect()
		ancestryConnection:Disconnect()
	end)
end

function FruitManagerModule.CreateFruit(fruitName, spawner, spawnAmount)
	local fruitClone = FruitManagerModule.GetFruitClone(fruitName)
	if not fruitClone then return nil end

	local flags = spawner:WaitForChild("Flags")
	local activeFlag = flags:WaitForChild("Active")
	activeFlag.Value = true

	fruitClone:SetAttribute("SpawnerId", spawner:GetFullName())
	fruitClone:SetAttribute("SpawnAmount", spawnAmount)

	FruitManagerModule.SetupFruitPhysics(fruitClone, spawner)
	FruitManagerModule.SetupFruitPickup(fruitClone, activeFlag)

	fruitClone.Parent = workspace

	local OnFruitSpawn = ReplicatedStorage:FindFirstChild("OnFruitSpawn")
	if OnFruitSpawn then
		OnFruitSpawn:Fire(
			fruitClone.Name,
			spawnAmount,
			spawner.Name,
			spawner.Position
		)
	end

	return fruitClone
end

-- Initialize cache on module load
FruitManagerModule.PreloadFruits()

return FruitManagerModule
