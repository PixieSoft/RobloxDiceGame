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

-- Debug logging function that checks if a system's debug flag is enabled before logging
-- @param System (string) - The system name to check in ReplicatedStorage/Debug (anywhere in the hierarchy)
-- @param Severity (string) - The severity level: "info", "warn", or "err"
-- @param Text (string) - The message to output
function Utility.Log(System, Severity, Text)
	-- Get a reference to the Debug folder
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DebugFolder = ReplicatedStorage:FindFirstChild("Debug")

	-- If the Debug folder doesn't exist, do nothing
	if not DebugFolder then
		return
	end

	-- Find the first BoolValue with matching name anywhere in the Debug folder hierarchy
	local SystemFlag
	for _, descendant in ipairs(DebugFolder:GetDescendants()) do
		if descendant:IsA("BoolValue") and descendant.Name == System then
			SystemFlag = descendant
			break
		end
	end

	-- If flag doesn't exist or is disabled, don't log
	if not SystemFlag or not SystemFlag.Value then
		return
	end

	-- Output the message based on severity
	if Severity == "info" then
		print("[" .. System .. "] " .. Text)
	elseif Severity == "warn" then
		warn("[" .. System .. "] " .. Text)
	elseif Severity == "err" then
		error("[" .. System .. "] " .. Text)
	else
		-- Default to info if severity is not recognized
		print("[" .. System .. "] " .. Text .. " (Unknown severity: " .. Severity .. ")")
	end
end

return Utility
