-- /ServerScriptService/LeaderstatsBoosters.lua
-- Script that creates and manages Booster-related leaderstats
-- Uses the Boosters module to determine which boosters to display

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Stat = require(ReplicatedStorage.Stat)
-- Fix: Update the path to the Boosters module from ServerScriptService to ReplicatedStorage
local Boosters = require(ReplicatedStorage.Modules.Core.Boosters)

Players.PlayerAdded:Connect(function(Player)
	if not Stat.WaitForLoad(Player) then return end -- player left before data loaded!

	-- Ensure booster stats exist in player data
	Boosters.EnsureBoosterStats(Player)

	-- Create leaderstats folder if it doesn't exist
	if not Player:FindFirstChild("leaderstats") then
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = Player
	end

	-- Create Boosters folder under leaderstats
	local boostersFolder = Instance.new("Folder")
	boostersFolder.Name = "Boosters"
	boostersFolder.Parent = Player.leaderstats

	-- Create values for each booster type from the Boosters module
	for boosterName, boosterInfo in pairs(Boosters.Items) do
		local boosterStat = Stat.Get(Player, boosterName)

		if boosterStat then
			-- Create IntValue to track this booster in leaderstats
			local boosterValue = Instance.new("IntValue")
			boosterValue.Name = boosterName
			boosterValue.Value = boosterStat.Value
			boosterValue.Parent = boostersFolder

			-- Connect stat changed event to update the leaderstat value
			boosterStat.Changed:Connect(function()
				boosterValue.Value = boosterStat.Value
			end)
		else
			warn("Booster stat not found: " .. boosterName .. " for player " .. Player.Name .. " even after ensuring stats")
		end
	end

	print("Set up Boosters leaderstats for " .. Player.Name)
end)

-- Handle active boosters visualization and expiration
game:GetService("RunService").Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local boostersFolder = player:FindFirstChild("leaderstats") and 
			player.leaderstats:FindFirstChild("Boosters")

		if boostersFolder then
			local activeBoosters = Boosters.GetActiveBoosters(player)

			-- Update or create active booster indicators
			for boosterName, timeLeft in pairs(activeBoosters) do
				local activeIndicator = boostersFolder:FindFirstChild(boosterName .. "_Active")

				if not activeIndicator then
					activeIndicator = Instance.new("NumberValue")
					activeIndicator.Name = boosterName .. "_Active"
					activeIndicator.Parent = boostersFolder
				end

				activeIndicator.Value = timeLeft
			end

			-- Clean up expired booster indicators
			for _, child in ipairs(boostersFolder:GetChildren()) do
				if child.Name:match("_Active$") then
					local boosterName = child.Name:gsub("_Active$", "")
					if not activeBoosters[boosterName] then
						child:Destroy()
					end
				end
			end
		end
	end
end)
