-- /ServerScriptService/BoosterSystem/BoosterServerHandler.lua
-- Script that handles server-side booster request validation and inventory management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get modules
local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)
local Stat = require(ReplicatedStorage.Stat)

-- Create or get BoosterEvents folder
local boosterEvents = ReplicatedStorage:FindFirstChild("BoosterEvents")
if not boosterEvents then
	boosterEvents = Instance.new("Folder")
	boosterEvents.Name = "BoosterEvents"
	boosterEvents.Parent = ReplicatedStorage

	-- Create the UseBooster event (this is the only event we need here)
	local useBoosterEvent = Instance.new("RemoteEvent")
	useBoosterEvent.Name = "UseBooster"
	useBoosterEvent.Parent = boosterEvents
end

-- Get the UseBooster event
local useBoosterEvent = boosterEvents:FindFirstChild("UseBooster")
if not useBoosterEvent then
	error("UseBooster event not found")
end

-- Handle player's request to use a booster
useBoosterEvent.OnServerEvent:Connect(function(player, boosterName, quantity)
	-- Validate input
	if not boosterName or not Boosters.Items[boosterName] then
		warn("Invalid booster name: " .. tostring(boosterName))
		return
	end

	-- Make sure quantity is a number and has a default value
	quantity = tonumber(quantity) or 1
	if quantity <= 0 then 
		warn("Invalid quantity: " .. tostring(quantity))
		return
	end

	-- Get the booster stat
	local boosterStat = Stat.Get(player, boosterName)
	if not boosterStat then
		warn("Booster stat not found for " .. boosterName)
		return
	end

	-- Check if player has enough boosters
	if boosterStat.Value < quantity then
		warn("Player doesn't have enough " .. boosterName .. ". Has " .. boosterStat.Value .. ", needs " .. quantity)
		return
	end

	-- Deduct boosters from player's count
	-- Only deduct after validation passes
	boosterStat.Value = boosterStat.Value - quantity

	-- Use the centralized booster activation system
	local success = Boosters.UseBooster(player, boosterName, quantity)

	-- If activation failed, refund the boosters
	if not success then
		warn("Failed to activate " .. boosterName .. ", refunding boosters")
		boosterStat.Value = boosterStat.Value + quantity
	end
end)

print("BoosterServerHandler initialized")
