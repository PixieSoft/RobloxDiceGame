local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents
local toggleCartEvent = Instance.new("RemoteEvent")
toggleCartEvent.Name = "ToggleCartEvent"
toggleCartEvent.Parent = ReplicatedStorage

local adjustSpeedEvent = Instance.new("RemoteEvent")
adjustSpeedEvent.Name = "AdjustSpeedEvent"
adjustSpeedEvent.Parent = ReplicatedStorage

-- Add new RemoteEvent for initial speed
local setInitialSpeedEvent = Instance.new("RemoteEvent")
setInitialSpeedEvent.Name = "SetInitialSpeedEvent"
setInitialSpeedEvent.Parent = ReplicatedStorage

-- Handle the toggle request
toggleCartEvent.OnServerEvent:Connect(function(player, seat)
	if seat and seat.Parent and seat.Parent.Name == "Cart" and seat.Parent:FindFirstChild("CarOn") then
		seat.Parent.CarOn.Value = not seat.Parent.CarOn.Value
	end
end)

-- Handle the speed adjustment
adjustSpeedEvent.OnServerEvent:Connect(function(player, seat, delta)
	if seat and seat.Parent and seat.Parent.Name == "Cart" and seat.Parent:FindFirstChild("Speed") then
		local speed = seat.Parent.Speed
		print("Speed adjustment - Old speed:", speed.Value)
		speed.Value = math.clamp(speed.Value + delta, -50, 50)
		print("Speed adjustment - New speed:", speed.Value)
	end
end)

-- Handle initial speed setting
setInitialSpeedEvent.OnServerEvent:Connect(function(player, seat)
	if seat and seat.Parent and seat.Parent:FindFirstChild("Speed") then
		local speed = seat.Parent.Speed
		print("Setting initial speed - Old speed:", speed.Value)
		speed.Value = 30
		print("Setting initial speed - New speed:", speed.Value)
	end
end)
