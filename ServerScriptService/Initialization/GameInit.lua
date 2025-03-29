-- /ServerScriptService/Initialization/GameInit
-- Hides the default scoreboard

-- Load services and modules
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Hide the leaderboard for all new players joining the game
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

-- Hide the leaderboard for players already in the game
local function onPlayerJoin(player)
	player.PlayerGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end

-- Connect to PlayerAdded event to handle new players
Players.PlayerAdded:Connect(onPlayerJoin)

-- Handle players already in the game
for _, player in pairs(Players:GetPlayers()) do
	onPlayerJoin(player)
end
