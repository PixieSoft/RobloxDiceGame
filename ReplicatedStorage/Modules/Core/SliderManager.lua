-- /ReplicatedStorage/Modules/Core/SliderManager.lua
-- ModuleScript that manages all slider UI components
-- Designed for extensibility to handle multiple sliders (size, speed, jump, etc.)

local SliderManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	if IsServer then
		-- Create remote events folder
		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = ReplicatedStorage
		end

		local coreFolder = eventsFolder:FindFirstChild("Core")
		if not coreFolder then
			coreFolder = Instance.new("Folder")
			coreFolder.Name = "Core"
			coreFolder.Parent = eventsFolder
		end

		-- Create slider visibility event
		local sliderEvent = coreFolder:FindFirstChild("SliderVisibility")
		if not sliderEvent then
			sliderEvent = Instance.new("RemoteEvent")
			sliderEvent.Name = "SliderVisibility"
			sliderEvent.Parent = coreFolder
		end

		remoteEvents = {visibility = sliderEvent}
	else
		-- Wait for remote events on client
		local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
		if eventsFolder then
			local coreFolder = eventsFolder:WaitForChild("Core", 10)
			if coreFolder then
				local sliderEvent = coreFolder:WaitForChild("SliderVisibility", 10)
				if sliderEvent then
					remoteEvents = {visibility = sliderEvent}

					-- Listen for visibility changes
					sliderEvent.OnClientEvent:Connect(function(sliderType, visible)
						local slider = getSliderModule(sliderType)
						if slider and slider.SetVisible then
							slider.SetVisible(visible)
						end
					end)
				end
			end
		end
	end
end

-- Get a reference to the ScaleCharacter module (lazy-loaded)
local function getScaleCharacter()
	if not ScaleCharacter then
		ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)
	end
	return ScaleCharacter
end

-- Show a specific slider
function SliderManager.ShowSlider(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	if IsServer then
		-- Fire event to all clients
		if remoteEvents and remoteEvents.visibility then
			remoteEvents.visibility:FireAllClients(sliderType, true)
		end
	else
		-- Handle directly on client
		local slider = getSliderModule(sliderType)
		if slider and slider.SetVisible then
			slider.SetVisible(true)
		end
	end
end

-- Hide a specific slider
function SliderManager.HideSlider(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	if IsServer then
		-- Fire event to all clients
		if remoteEvents and remoteEvents.visibility then
			remoteEvents.visibility:FireAllClients(sliderType, false)
		end
	else
		-- Handle directly on client
		local slider = getSliderModule(sliderType)
		if slider and slider.SetVisible then
			slider.SetVisible(false)
		end
	end
end

-- Reset the associated value for a slider
function SliderManager.ResetSliderValue(sliderType, player)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	if sliderType == SliderManager.SliderTypes.SIZE then
		local scaleChar = getScaleCharacter()
		if scaleChar and player then
			scaleChar.SetScale(player, 1.0)
		end
	end
end

-- Hide slider and reset its value (common operation)
function SliderManager.HideAndResetSlider(sliderType, player)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	SliderManager.HideSlider(sliderType)
	SliderManager.ResetSliderValue(sliderType, player)
end

-- Get current visibility state of a slider
function SliderManager.IsSliderVisible(sliderType)
	sliderType = sliderType or SliderManager.SliderTypes.SIZE

	local slider = getSliderModule(sliderType)
	if slider and slider.IsVisible then
		return slider.IsVisible()
	end

	return false
end

-- Initialize the module
SliderManager.Initialize()

return SliderManager
