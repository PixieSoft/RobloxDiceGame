-- /ReplicatedStorage/Modules/Core/SliderManager.lua
-- ModuleScript that manages all slider UI components
-- Designed for extensibility to handle multiple sliders (size, speed, jump, etc.)

local SliderManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import modules
local Utility = require(ReplicatedStorage.Modules.Core.Utility)

-- Debug settings
local debugSystem = "Sliders" -- System name for debug logs

-- References to slider modules (lazy-loaded to prevent circular dependencies)
local SizeSlider = nil
local ScaleCharacter = nil

-- Slider types enum for future expansion
SliderManager.SliderTypes = {
	SIZE = "SizeSlider",
	-- Future additions:
	-- SPEED = "SpeedSlider",
	-- JUMP = "JumpSlider",
	-- etc.
}

-- Check if we're on server or client
local IsServer = game:GetService("RunService"):IsServer()

-- Add RemoteEvent for server-client communication
local remoteEvents = nil

-- Get a reference to a slider module (lazy-loaded)
local function getSliderModule(sliderType)
	if sliderType == SliderManager.SliderTypes.SIZE then
		if not SizeSlider then
			SizeSlider = require(ReplicatedStorage.Modules.Core.SizeSlider)
			Utility.Log(debugSystem, "info", "Lazy-loaded SizeSlider module")
		end
		return SizeSlider
	end

	-- Future sliders would be added here
	-- elseif sliderType == SliderManager.SliderTypes.SPEED then
	--    if not SpeedSlider then
	--        SpeedSlider = require(ReplicatedStorage.Modules.Core.SpeedSlider)
	--    end
	--    return SpeedSlider

	return nil
end

function SliderManager.Initialize()
	Utility.Log(debugSystem, "info", "Initializing SliderManager")

	if IsServer then
		-- Create remote events folder
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = ReplicatedStorage
			Utility.Log(debugSystem, "info", "Created Events folder")
		end

		local coreFolder = eventsFolder:FindFirstChild("Core")
		if not coreFolder then
			coreFolder = Instance.new("Folder")
			coreFolder.Name = "Core"
			coreFolder.Parent = eventsFolder
			Utility.Log(debugSystem, "info", "Created Core folder")
		end

		-- Create slider visibility event
		local sliderEvent = coreFolder:FindFirstChild("SliderVisibility")
		if not sliderEvent then
			sliderEvent = Instance.new("RemoteEvent")
			sliderEvent.Name = "SliderVisibility"
			sliderEvent.Parent = coreFolder
			Utility.Log(debugSystem, "info", "Created SliderVisibility RemoteEvent")
		end

		remoteEvents = {visibility = sliderEvent}
		Utility.Log(debugSystem, "info", "Server-side initialization complete")
	else
		-- Wait for remote events on client
		Utility.Log(debugSystem, "info", "Waiting for remote events on client")
		local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
		if eventsFolder then
			local coreFolder = eventsFolder:WaitForChild("Core", 10)
			if coreFolder then
				local sliderEvent = coreFolder:WaitForChild("SliderVisibility", 10)
				if sliderEvent then
					remoteEvents = {visibility = sliderEvent}
					Utility.Log(debugSystem, "info", "Successfully found SliderVisibility event")

					-- Listen for visibility changes
					sliderEvent.OnClientEvent:Connect(function(sliderType, visible)
						Utility.Log(debugSystem, "info", "Received visibility event: " .. sliderType .. " = " .. tostring(visible))
						local slider = getSliderModule(sliderType)
						if slider and slider.SetVisible then
							slider.SetVisible(visible)
						else
							Utility.Log(debugSystem, "warn", "Slider module not found or missing SetVisible method: " .. sliderType)
						end
					end)
				else
					Utility.Log(debugSystem, "warn", "Failed to find SliderVisibility event after waiting")
				end
			else
				Utility.Log(debugSystem, "warn", "Failed to find Core folder after waiting")
			end
		else
			Utility.Log(debugSystem, "warn", "Failed to find Events folder after waiting")
		end
	end
end

-- Get a reference to the ScaleCharacter module (lazy-loaded)
local function getScaleCharacter()
	if not ScaleCharacter then
		ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
		Utility.Log(debugSystem, "info", "Lazy-loaded ScaleCharacter module")
	end
	return ScaleCharacter
end

-- Show a specific slider
function SliderManager.ShowSlider(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE
	Utility.Log(debugSystem, "info", "ShowSlider called for " .. sliderType)

	if IsServer then
		-- Fire event to all clients
		if remoteEvents and remoteEvents.visibility then
			remoteEvents.visibility:FireAllClients(sliderType, true)
			Utility.Log(debugSystem, "info", "Fired visibility event to all clients: " .. sliderType .. " = true")
		else
			Utility.Log(debugSystem, "warn", "Remote events not available for showing slider")
		end
	else
		-- Handle directly on client
		local slider = getSliderModule(sliderType)
		if slider and slider.SetVisible then
			slider.SetVisible(true)
			Utility.Log(debugSystem, "info", "Set slider visibility directly on client: " .. sliderType .. " = true")
		else
			Utility.Log(debugSystem, "warn", "Cannot set slider visibility - module not found or missing SetVisible method")
		end
	end
end

-- Hide a specific slider
function SliderManager.HideSlider(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE
	Utility.Log(debugSystem, "info", "HideSlider called for " .. sliderType)

	if IsServer then
		-- Fire event to all clients
		if remoteEvents and remoteEvents.visibility then
			remoteEvents.visibility:FireAllClients(sliderType, false)
			Utility.Log(debugSystem, "info", "Fired visibility event to all clients: " .. sliderType .. " = false")
		else
			Utility.Log(debugSystem, "warn", "Remote events not available for hiding slider")
		end
	else
		-- Handle directly on client
		local slider = getSliderModule(sliderType)
		if slider and slider.SetVisible then
			slider.SetVisible(false)
			Utility.Log(debugSystem, "info", "Set slider visibility directly on client: " .. sliderType .. " = false")
		else
			Utility.Log(debugSystem, "warn", "Cannot set slider visibility - module not found or missing SetVisible method")
		end
	end
end

-- Reset the associated value for a slider
function SliderManager.ResetSliderValue(sliderType, player)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE
	Utility.Log(debugSystem, "info", "ResetSliderValue called for " .. sliderType)

	if sliderType == SliderManager.SliderTypes.SIZE then
		local scaleChar = getScaleCharacter()
		if scaleChar and player then
			scaleChar.SetScale(player, 1.0)
			Utility.Log(debugSystem, "info", "Reset scale for player " .. player.Name .. " to 1.0")
		else
			Utility.Log(debugSystem, "warn", "Failed to reset scale - ScaleCharacter module not available or player missing")
		end

		-- Also reset the slider UI position
		local slider = getSliderModule(sliderType)
		if slider and slider.Reset then
			slider.Reset()
			Utility.Log(debugSystem, "info", "Reset slider UI position")
		else
			Utility.Log(debugSystem, "warn", "Cannot reset slider UI - module not found or missing Reset method")
		end
	end
end

-- Hide slider and reset its value (common operation)
function SliderManager.HideAndResetSlider(sliderType, player)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE
	Utility.Log(debugSystem, "info", "HideAndResetSlider called for " .. sliderType)

	SliderManager.HideSlider(sliderType)
	SliderManager.ResetSliderValue(sliderType, player)
end

-- Get current visibility state of a slider
function SliderManager.IsSliderVisible(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	local slider = getSliderModule(sliderType)
	if slider and slider.IsVisible then
		local visible = slider.IsVisible()
		Utility.Log(debugSystem, "info", "IsSliderVisible check: " .. sliderType .. " = " .. tostring(visible))
		return visible
	end

	Utility.Log(debugSystem, "warn", "Cannot get slider visibility - module not found or missing IsVisible method")
	return false
end

-- Initialize the module
SliderManager.Initialize()

return SliderManager
