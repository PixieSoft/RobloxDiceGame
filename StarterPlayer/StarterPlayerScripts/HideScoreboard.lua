-- /StarterPlayer/StarterPlayerScripts/HideScoreboard.lua
-- Hides the default scoreboard for players.

local StarterGui = game:GetService("StarterGui")

-- Function to hide the scoreboard (with retry in case it fails at first)
local function hideScoreboard()
	local success = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	-- If it fails, try again after a short delay
	if not success then
		task.delay(1, hideScoreboard)
	end
end

-- Hide the scoreboard
hideScoreboard()
