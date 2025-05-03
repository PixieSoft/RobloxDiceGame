-- /ServerScriptService/BoosterSystem/BoosterServerHandler.lua
-- Script that handles server-side booster usage and activation requests

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

	-- Create standard events
	local events = {
		"BoosterActivated",
		"BoosterDeactivated",
		"UseBooster"
	}

	for _, eventName in ipairs(events) do
		if not boosterEvents:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = boosterEvents
		end
	end
end

-- Get the UseBooster event
local useBoosterEvent = boosterEvents:FindFirstChild("UseBooster")
if not useBoosterEvent then
	useBoosterEvent = Instance.new("RemoteEvent")
	useBoosterEvent.Name = "UseBooster"
	useBoosterEvent.Parent = boosterEvents
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

	-- Get the booster item
	local boosterItem = Boosters.Items[boosterName]
	if not boosterItem then
		warn("Booster item not found in Boosters.Items: " .. boosterName)
		return
	end

	-- Check if this booster can be activated
	local canActivate = true

	-- Check if this booster is already active for this player
	if Boosters.IsBoosterActive and Boosters.IsBoosterActive(player, boosterName) then
		warn("Booster already active: " .. boosterName)
		canActivate = false
		return
	end

	-- Only proceed if we can activate the booster
	if canActivate then
		-- Deduct boosters from player's count
		boosterStat.Value = boosterStat.Value - quantity

		-- Run the booster's onActivate function
		if type(boosterItem.onActivate) == "function" then
			local success, cleanupFunction = pcall(function()
				return boosterItem.onActivate(player, quantity)
			end)

			if success then
				-- Delegate activation management to the Boosters module
				if Boosters.ActivateBooster then
					-- Use the centralized Boosters system to handle activation
					local activationSuccess = Boosters.ActivateBooster(player, boosterName, quantity, cleanupFunction)
					
					-- If activation failed, refund the boosters
					if not activationSuccess then
						warn("Failed to activate " .. boosterName .. " through Boosters.ActivateBooster")
						boosterStat.Value = boosterStat.Value + quantity
					end
				end
			else
				-- If activation failed, refund the booster
				warn("Failed to activate booster " .. boosterName .. ": " .. tostring(cleanupFunction))
				boosterStat.Value = boosterStat.Value + quantity
			end
		else
			-- If there's no activation function, refund the booster
			warn("Booster " .. boosterName .. " doesn't have an onActivate function")
			boosterStat.Value = boosterStat.Value + quantity
		end
	end
end)

-- Note: Player cleanup is now fully handled by the Boosters module
-- We no longer need duplicate cleanup code here

print("BoosterServerHandler initialized")
