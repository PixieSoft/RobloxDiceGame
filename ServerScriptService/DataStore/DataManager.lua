--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Requires
local ProfileService = require(script.ProfileService)

local TempValues = require(script.TempValues)
local Values = require(script.Values)

local ProfileTemplate = {}

local ProfileStore = ProfileService.GetProfileStore(
	ReplicatedStorage["Game Settings"].DataSave.Value, 
	ProfileTemplate
)

local Profiles = {}
local DataManager = {}

--// Functions
local function CreateInstance(Type, Name, Parent, Value)
	local NewInstance = Instance.new(Type)
	NewInstance.Name = Name
	NewInstance.Parent = Parent

	if Value then
		NewInstance.Value = Value
	end

	return NewInstance
end

--// Main
function DataManager.OnPlayerAdded(Player)
	local Profile = ProfileStore:LoadProfileAsync(
		tostring(Player.UserId),
		"ForceLoad"
	)
	
	--// Load Profile
	if Profile then
		Profile:ListenToRelease(function()
			Profiles[Player] = nil
			Player:Kick()
		end)
		
		if Player:IsDescendantOf(Players) then			
			local Data = Profile.Data

			for _,v in Values do
				if v.Type == "Folder" then
					if v.Parent == "Player" then
						if Data[v.Name] then continue end
						Data[v.Name] = {}
					else
						if Data[v.Parent][v.Name] then continue end
						Data[v.Parent][v.Name] = {}
					end
				else  -- type is a value
					if v.Parent == "Player" then
						if Data[v.Name] then continue end
						Data[v.Name] = v.StartingAmount
					else
						if Data[v.Parent][v.Name] then continue end
						Data[v.Parent][v.Name] = v.StartingAmount
					end
				end
			end
			
			Profiles[Player] = Profile
		else
			Profile:Release()
		end
	else
		Player:Kick()
	end
	
	--// Create TempValues
	local TempFolder = CreateInstance("Folder", "TempValues", Player)
	
	for _, TempInfo in TempValues do
		CreateInstance(TempInfo.Type, TempInfo.Name, TempFolder, TempInfo.StartingAmount)
	end
end

function DataManager.OnPlayerRemoving(Player)
	local Profile = Profiles[Player]
	
	if Profile then
		Profile.Data.Other.LastJoin = os.time()
		Profile:Release()
	end
end

function DataManager:Get(Player)
	local Profile = Profiles[Player]
	
	if Profile then
		return Profile.Data
	end
end

function DataManager:CreateFolder(Player) -- converts a profile to a folder
	local Data = DataManager:Get(Player)
	
	local DataFolder = CreateInstance("Folder", Player.Name, ReplicatedStorage.Data)
	
	local function CreateValue(Name, Parent, Value)
		if type(Value) == "number" then
			return CreateInstance("NumberValue", Name, Parent, Value)
		elseif type(Value) == "string" then
			return CreateInstance("StringValue", Name, Parent, Value)
		elseif type(Value) == "boolean" then
			return CreateInstance("BoolValue", Name, Parent, Value)
		end
	end
	
	for Object, ObjectValue in Data do
		if type(ObjectValue) == "table" then
			CreateInstance("Folder", Object, DataFolder)
			
			for Object2, ObjectValue2 in ObjectValue do -- loop thru this folder for the second layer
				if type(ObjectValue2) == "table" then
					CreateInstance("Folder", Object2, DataFolder[Object])
					
					for Object3, ObjectValue3 in ObjectValue2 do
						CreateValue(Object3, DataFolder[Object][Object2], ObjectValue3)
					end					
				else
					CreateValue(Object2, DataFolder[Object], ObjectValue2)
				end
			end
		else
			CreateValue(Object, DataFolder, ObjectValue) -- its a value directly inside data, so save
		end
	end
	
	return DataFolder
end

function DataManager:FolderToProfile(Player)
	local DataFolder = ReplicatedStorage.Data[Player.Name]
	local Data = DataManager:Get(Player)
	
	for _, Object in DataFolder:GetChildren() do
		if Object:IsA("Folder") then
			Data[Object.Name] = {}
			
			for _, ObjectInside in Object:GetChildren() do -- if its a folder, get the things inside
				if ObjectInside:IsA("Folder") then -- for example the pets
					Data[Object.Name][ObjectInside.Name] = {}
					for _, ObjectInside2 in ObjectInside:GetChildren() do -- if its a folder in a folder, do the same but one layer deeper
						Data[Object.Name][ObjectInside.Name][ObjectInside2.Name] = ObjectInside2.Value
					end
				else
					Data[Object.Name][ObjectInside.Name] = ObjectInside.Value
				end
			end
		else
			Data[Object.Name] = Object.Value
		end
	end	
end

return DataManager
