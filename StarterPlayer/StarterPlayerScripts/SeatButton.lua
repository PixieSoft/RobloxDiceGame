-- Place this script in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Wait for RemoteEvents
local toggleCartEvent = ReplicatedStorage:WaitForChild("ToggleCartEvent")
local adjustSpeedEvent = ReplicatedStorage:WaitForChild("AdjustSpeedEvent")

-- Keep track of the current seat for button clicks
local currentSeat = nil

local function createArrowButton(isUpArrow)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 50, 0, 50)
	button.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
	button.Text = isUpArrow and "▲" or "▼"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 30
	button.Font = Enum.Font.SourceSansBold

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

-- Function to toggle the cart
local function toggleCart()
	if currentSeat and currentSeat.Parent then
		toggleCartEvent:FireServer(currentSeat)
	end
end

-- Add keyboard input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
		toggleCart()
	end
end)

local function createButton()
	local existingGui = player.PlayerGui:FindFirstChild("SeatButtonGui")
	if existingGui then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SeatButtonGui"
	screenGui.ResetOnSpawn = false

	-- Create button container
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 300, 0, 110)  -- Increased height to accommodate new button
	container.Position = UDim2.new(0.5, -150, 0.75, -25)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- Create down speed button
	local downButton = createArrowButton(false)
	downButton.Position = UDim2.new(0, 0, 0, 0)
	downButton.Parent = container

	-- Create main speed display button
	local mainButton = Instance.new("TextButton")
	mainButton.Size = UDim2.new(0, 200, 0, 50)
	mainButton.Position = UDim2.new(0, 50, 0, 0)
	mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	mainButton.Text = "0"
	mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainButton.TextScaled = false
	mainButton.TextSize = 38
	mainButton.Font = Enum.Font.SourceSansBold
	mainButton.Parent = container

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = mainButton

	-- Create up speed button
	local upButton = createArrowButton(true)
	upButton.Position = UDim2.new(0, 250, 0, 0)
	upButton.Parent = container

	-- Create direction toggle button
	local directionButton = Instance.new("TextButton")
	directionButton.Size = UDim2.new(0, 100, 0, 50)
	directionButton.Position = UDim2.new(0, 100, 0, 60)  -- Centered under main button
	directionButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)  -- Blue color
	directionButton.Text = "⇄"  -- Unicode symbol for bidirectional arrow
	directionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	directionButton.TextSize = 38
	directionButton.Font = Enum.Font.SourceSansBold
	directionButton.Parent = container

	local directionCorner = Instance.new("UICorner")
	directionCorner.CornerRadius = UDim.new(0, 8)
	directionCorner.Parent = directionButton

	-- Add click handlers
	mainButton.MouseButton1Click:Connect(toggleCart)

	-- Direction toggle handler
	directionButton.MouseButton1Click:Connect(function()
		if currentSeat and currentSeat.Parent then
			local speedValue = currentSeat.Parent:FindFirstChild("Speed")
			if speedValue then
				-- Reverse the current speed
				adjustSpeedEvent:FireServer(currentSeat, -2 * speedValue.Value)
			end
		end
	end)

	local function handleSpeedButton(button, delta)
		local debounce = false

		button.MouseButton1Click:Connect(function()
			if debounce then return end
			if currentSeat and currentSeat.Parent then
				debounce = true

				local tweenService = game:GetService("TweenService")
				local flashTween = tweenService:Create(button, 
					TweenInfo.new(0.1, Enum.EasingStyle.Linear), 
					{BackgroundTransparency = 0.5}
				)
				local revertTween = tweenService:Create(button, 
					TweenInfo.new(0.1, Enum.EasingStyle.Linear), 
					{BackgroundTransparency = 0}
				)

				flashTween:Play()
				adjustSpeedEvent:FireServer(currentSeat, delta)
				print("Firing speed adjustment with delta:", delta)

				task.delay(0.1, function()
					revertTween:Play()
					task.delay(0.1, function()
						debounce = false
					end)
				end)
			end
		end)
	end

	handleSpeedButton(upButton, 10)
	handleSpeedButton(downButton, -10)

	-- Set up value changed listeners
	if currentSeat and currentSeat.Parent then
		if currentSeat.Parent:FindFirstChild("CarOn") then
			currentSeat.Parent.CarOn.Changed:Connect(function(newValue)
				mainButton.BackgroundColor3 = newValue 
					and Color3.fromRGB(0, 255, 0)
					or Color3.fromRGB(255, 0, 0)
			end)

			mainButton.BackgroundColor3 = currentSeat.Parent.CarOn.Value 
				and Color3.fromRGB(0, 255, 0)
				or Color3.fromRGB(255, 0, 0)
		end

		if currentSeat.Parent:FindFirstChild("Speed") then
			currentSeat.Parent.Speed.Changed:Connect(function(newValue)
				mainButton.Text = tostring(newValue)
			end)

			mainButton.Text = tostring(currentSeat.Parent.Speed.Value)
		end
	end

	screenGui.Parent = player.PlayerGui
	return screenGui
end

local function removeButton()
	local gui = player.PlayerGui:FindFirstChild("SeatButtonGui")
	if gui then
		gui:Destroy()
	end
	currentSeat = nil
end

-- Rest of the code remains unchanged...
local function setupSeat(seat)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant and seat.Occupant.Parent == player.Character then
			print("Player sat in:", seat:GetFullName())
			print("Seat's parent:", seat.Parent:GetFullName())

			if seat.Parent then
				local speedValue = seat.Parent:FindFirstChild("Speed")
				if speedValue then
					print("Before requesting initial speed set:", speedValue.Value)
					-- Wait for RemoteEvent
					local setInitialSpeedEvent = ReplicatedStorage:WaitForChild("SetInitialSpeedEvent")
					setInitialSpeedEvent:FireServer(seat)
					print("After requesting initial speed set:", speedValue.Value)

					-- Add Changed listener for debugging
					speedValue.Changed:Connect(function(newValue)
						print("Speed changed to:", newValue, "at time:", tick())
					end)
				end
			end

			currentSeat = seat
			createButton()
		else
			removeButton()
		end
	end)
end

-- Wait for character to load
if not player.Character then
	player.CharacterAdded:Wait()
end

-- Set up existing seats
for _, object in pairs(game.Workspace:GetDescendants()) do
	if object:IsA("Seat") or object:IsA("VehicleSeat") then
		setupSeat(object)
	end
end

-- Set up any seats added in the future
game.Workspace.DescendantAdded:Connect(function(object)
	if object:IsA("Seat") or object:IsA("VehicleSeat") then
		setupSeat(object)
	end
end)
