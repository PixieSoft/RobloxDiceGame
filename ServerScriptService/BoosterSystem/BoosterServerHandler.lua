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

	-- Deduct boosters from player's count FIRST to prevent double-decrement issues
	boosterStat.Value = boosterStat.Value - quantity

	-- Run the booster's onActivate function
	if type(boosterItem.onActivate) == "function" then
		local success, result = pcall(function()
			return boosterItem.onActivate(player, quantity)
		end)

		if success then
			-- If Boosters module has tracking for active boosters, use it
			if Boosters.ActivateBooster then
				-- Call internal Boosters system to handle activation properly
				Boosters.ActivateBooster(player, boosterName, quantity, result)
			else
				-- Simple tracking approach if the module doesn't have built-in tracking
				local activationTime = os.time()
				local duration = boosterItem.duration or 60 -- Default 60 seconds if not specified

				-- Multiply duration by quantity to get total duration
				local totalDuration = duration * quantity
				local expirationTime = activationTime + totalDuration

				-- Fire the client event for activation
				local activatedEvent = boosterEvents:FindFirstChild("BoosterActivated")
				if activatedEvent then
					activatedEvent:FireClient(player, boosterName, expirationTime)
				end

				-- Set up expiration timer if the booster has a duration
				if totalDuration and totalDuration > 0 then
					task.delay(totalDuration, function()
						-- Run cleanup function if available
						if type(result) == "function" then
							local success, errorMsg = pcall(result)
							if not success then
								warn("Error in cleanup function for booster", boosterName, ":", errorMsg)
							end
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
			-- If activation failed, refund the booster
			warn("Failed to activate booster " .. boosterName .. ": " .. tostring(result))
			boosterStat.Value = boosterStat.Value + quantity
		end
	else
		-- If there's no activation function, refund the booster
		warn("Booster " .. boosterName .. " doesn't have an onActivate function")
		boosterStat.Value = boosterStat.Value + quantity
	end
end)

-- Clean up active boosters when players leave
Players.PlayerRemoving:Connect(function(player)
	if Boosters.CleanupPlayerBoosters then
		Boosters.CleanupPlayerBoosters(player)
	end
end)

print("BoosterServerHandler initialized")
