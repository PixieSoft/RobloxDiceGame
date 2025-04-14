-- /LocalScript attached to button
local button = script.Parent
local creditsFrame = button:WaitForChild("TempCredits")

button.MouseButton1Click:Connect(function()
	creditsFrame.Visible = not creditsFrame.Visible
end)
