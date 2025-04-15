-- /ServerScriptService/BoosterSystem/BoosterServerHandler.lua
-- Script that handles server-side booster usage and activation

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

	quantity = quantity or 1
	if quantity <= 0 then 
		warn("Invalid quantity: " .. tostring(quantity))
		return
	end

	print("Player " .. player.Name .. " is attempting to use " .. quantity .. " " .. boosterName)

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

	-- Run the booster's onActivate function
	if type(boosterItem.onActivate) == "function" then
		local success, cleanupFunction = pcall(function()
			return boosterItem.onActivate(player, quantity)
		end)

		if success then
			print("Successfully activated " .. boosterName)

			-- Deduct boosters from player's count
			boosterStat.Value = boosterStat.Value - quantity

			-- If Boosters module has tracking for active boosters, use it
			if Boosters.ActivateBooster then
				-- Call internal Boosters system to handle activation properly
				Boosters.ActivateBooster(player, boosterName, quantity, cleanupFunction)
			else
				-- Simple tracking approach if the module doesn't have built-in tracking
				local activationTime = os.time()
				local duration = boosterItem.duration or 60 -- Default 60 seconds if not specified
				local expirationTime = activationTime + duration

				-- Fire the client event for activation
				local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
				if activatedEvent then
					activatedEvent:FireClient(player, boosterName, expirationTime)
				end

				-- Set up expiration timer if the booster has a duration
				if duration and duration > 0 then
					task.delay(duration, function()
						-- Run cleanup function if available
						if type(cleanupFunction) == "function" then
							pcall(cleanupFunction)
						end

						-- Fire the client event for deactivation
						local deactivatedEvent = boosterEvents:FindFirstChild("BoosterDeactivated")
						if deactivatedEvent then
							deactivatedEvent:FireClient(player, boosterName)
						end
					end)
				end
			end
		else
			warn("Failed to activate booster " .. boosterName .. ": " .. tostring(cleanupFunction))
		end
	else
		warn("Booster " .. boosterName .. " doesn't have an onActivate function")
	end
end)

-- Clean up active boosters when players leave
Players.PlayerRemoving:Connect(function(player)
	if Boosters.CleanupPlayerBoosters then
		Boosters.CleanupPlayerBoosters(player)
	end
end)

print("BoosterServerHandler initialized")
