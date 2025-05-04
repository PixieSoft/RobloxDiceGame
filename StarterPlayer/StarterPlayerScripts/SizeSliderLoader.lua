-- /StarterPlayer/StarterPlayerScripts/SizeSliderLoader.lua
-- LocalScript that ensures the SizeSlider module is loaded on the client

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Simply requiring the module will trigger its auto-initialization
local SizeSlider = require(ReplicatedStorage.Modules.Core.SizeSlider)

-- In SizeSliderLoader.lua
local ScaleCharacter = require(ReplicatedStorage.Modules.Core.ScaleCharacter)

-- Make sure ScaleCharacter is initialized on client
ScaleCharacter.Initialize()
