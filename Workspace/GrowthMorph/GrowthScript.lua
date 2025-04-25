--[[
	Written by hunxrepair
	2020/10/09
	
	Fixed another bug with head scaling (R6)
	You can now set custom scaling for height, width, depth, head
	
	ROBLOX changes stuff all the time. Something isn't working? DM me or comment
]]

-- 0.5 is half size, 2 is double size

local Width = 0.5 -- How wide your shoulders are
local Height = 0.5 -- How tall you are
local Depth = 0.5 -- How fat you are
local Head = nil -- Head size, auto calculated if set to nil (R15 only)

--local Width = 1.5 -- How wide your shoulders are
--local Height = 1.5 -- How tall you are
--local Depth = 1.5 -- How fat you are
--local Head = nil -- Head size, auto calculated if set to nil (R15 only)

local Vector = Vector3.new(Width, Height, Depth)


script.Parent.Trigger.Touched:Connect(function(Hit)
	local Player = game.Players:GetPlayerFromCharacter(Hit.Parent)
	if Player == nil then return end
	if Player.Character:GetAttribute("Scaled") == true then return end
	Player.Character:SetAttribute("Scaled", true)
	
	
	local Humanoid = Player.Character.Humanoid
	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		local Motors = {}
		table.insert(Motors, Player.Character.HumanoidRootPart.RootJoint)
		for i,Motor in pairs(Player.Character.Torso:GetChildren()) do
			if Motor:IsA("Motor6D") == false then continue end
			table.insert(Motors, Motor)
		end
		for i,v in pairs(Motors) do
			v.C0 = CFrame.new((v.C0.Position * Vector)) * (v.C0 - v.C0.Position)
			v.C1 = CFrame.new((v.C1.Position * Vector)) * (v.C1 - v.C1.Position)
		end
		
		
		for i,Part in pairs(Player.Character:GetChildren()) do
			if Part:IsA("BasePart") == false then continue end
			Part.Size *= Vector
		end
		if Player.Character.Head.Mesh.MeshId ~= "" then
			Player.Character.Head.Mesh.Scale *= Vector
		end
		
		for i,Accessory in pairs(Player.Character:GetChildren()) do
			if Accessory:IsA("Accessory") == false then continue end
			
			Accessory.Handle.AccessoryWeld.C0 = CFrame.new((Accessory.Handle.AccessoryWeld.C0.Position * Vector)) * (Accessory.Handle.AccessoryWeld.C0 - Accessory.Handle.AccessoryWeld.C0.Position)
			Accessory.Handle.AccessoryWeld.C1 = CFrame.new((Accessory.Handle.AccessoryWeld.C1.Position * Vector)) * (Accessory.Handle.AccessoryWeld.C1 - Accessory.Handle.AccessoryWeld.C1.Position)
			Accessory.Handle:FindFirstChildOfClass("SpecialMesh").Scale *= Vector	
		end
		
	elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
		local HD = Humanoid:GetAppliedDescription()
		HD.DepthScale *= Depth
		HD.HeadScale *= Head or math.max(Width, Depth)
		HD.HeightScale *= Height
		HD.WidthScale *= Width
		Humanoid:ApplyDescription(HD)
	end
end)
