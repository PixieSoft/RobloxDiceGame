-- ServerScriptService/Tests/TestVirtualDie

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualDie = require(ReplicatedStorage.Modules.Combat.VirtualDie)

local function TestVirtualDie()
	-- Create a mock real die for testing
	local realDie = Instance.new("Part")
	realDie:SetAttribute("Name", "TestDie")
	realDie:SetAttribute("Attack", 50)
	realDie:SetAttribute("Defense", 40)
	realDie:SetAttribute("Healing", 30)
	realDie:SetAttribute("Elemental", 20)
	realDie:SetAttribute("MaxHP", 100)

	-- Create virtual copy
	local virtualDie = VirtualDie.new(realDie, "TestCombat_1")

	-- Test attribute copying
	print("Name copied:", virtualDie:GetAttribute("Name") == "TestDie")
	print("Attack copied:", virtualDie:GetAttribute("Attack") == 50)

	-- Test combat properties
	print("HP initialized:", virtualDie.hp == 100)
	print("TempHP initialized:", virtualDie.tempHP == 0)

	-- Test attribute modification
	virtualDie:SetAttribute("Attack", 60)
	print("Can modify virtual die:", virtualDie:GetAttribute("Attack") == 60)
	print("Real die unchanged:", realDie:GetAttribute("Attack") == 50)

	realDie:Destroy()
end

TestVirtualDie()
