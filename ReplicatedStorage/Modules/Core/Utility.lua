-- /ReplicatedStorage/Modules/Core/Utility.lua
-- ModuleScript that provides utility functions for various systems

local Utility = {}

-- Format a time duration in seconds into a human-readable string
-- @param seconds (number) - Time in seconds to format
-- @return (string) - Formatted time string like "1d 14h 43m 45s" or parts thereof
function Utility.FormatTimeDuration(seconds)
	-- Convert seconds to components
	local days = math.floor(seconds / 86400)
	seconds = seconds % 86400

	local hours = math.floor(seconds / 3600)
	seconds = seconds % 3600

	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60

	-- Format the time string
	local parts = {}

	-- Add each time component if non-zero
	if days > 0 then
		table.insert(parts, days .. "d")
	end

	if hours > 0 then
		table.insert(parts, hours .. "h")
	end

	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end

	if seconds > 0 then
		table.insert(parts, seconds .. "s")
	end

	-- Handle the case of zero duration
	if #parts == 0 then
		return "0s"
	end

	-- Join time components with spaces
	return table.concat(parts, " ")
end

return Utility
