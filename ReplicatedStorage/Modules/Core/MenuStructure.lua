-- /ReplicatedStorage/Modules/Core/MenuStructure.lua
-- ModuleScript that defines the menu structure, including top tabs and their associated side tabs

local MenuStructure = {
	-- Metadata about the menu system
	Version = "1.0.0",
	DefaultTopTab = "Items",

	-- Top tab definitions with their associated side tabs
	TopTabs = {
		Items = {
			DisplayName = "Items",
			Description = "Manage your items and inventory",
			SideTabs = {
				{Name = "Dice", Order = 1, Description = "View and manage your dice collection", ContentFrame = "DiceInventory"},
				{Name = "Boosters", Order = 2, Description = "Access your booster items", ContentFrame = "BoosterInventory"},
				{Name = "Tools", Order = 3, Description = "Equip and manage your tools", ContentFrame = "ToolsInventory"},
				{Name = "Cosmetics", Order = 4, Description = "Customize your appearance", ContentFrame = "CosmeticsInventory"}
			}
		},

		Upgrades = {
			DisplayName = "Upgrades",
			Description = "Upgrade and enhance your capabilities",
			SideTabs = {
				{Name = "Dice", Order = 1, Description = "Upgrade your dice abilities", ContentFrame = "DiceUpgrades"},
				{Name = "Frame", Order = 2, Description = "Customize your dice frames", ContentFrame = "FrameUpgrades"},
				{Name = "Character", Order = 3, Description = "Enhance your character's abilities", ContentFrame = "CharacterUpgrades"}
			}
		},

		Social = {
			DisplayName = "Social",
			Description = "Interact with other players",
			SideTabs = {
				{Name = "Teleport", Order = 1, Description = "Teleport to players or locations", ContentFrame = "TeleportMenu"},
				{Name = "Friends", Order = 2, Description = "Manage your friends list", ContentFrame = "FriendsMenu"},
				{Name = "Trading", Order = 3, Description = "Trade items with other players", ContentFrame = "TradingMenu"},
				{Name = "Dueling", Order = 4, Description = "Challenge players to duels", ContentFrame = "DuelingMenu"},
				{Name = "Boss Fights", Order = 5, Description = "Join or create boss fight teams", ContentFrame = "BossFightsMenu"}
			}
		},

		Goals = {
			DisplayName = "Goals",
			Description = "Track your progress and achievements",
			SideTabs = {
				{Name = "Dice", Order = 1, Description = "Track dice collection goals", ContentFrame = "DiceGoals"},
				{Name = "Character", Order = 2, Description = "View character advancement goals", ContentFrame = "CharacterGoals"},
				{Name = "Exploration", Order = 3, Description = "Monitor exploration objectives", ContentFrame = "ExplorationGoals"},
				{Name = "Collections", Order = 4, Description = "Manage your collections progress", ContentFrame = "CollectionsGoals"},
				{Name = "Progression", Order = 5, Description = "View overall game progression", ContentFrame = "ProgressionGoals"}
			}
		}
	},

	-- Configuration options for the menu system
	Config = {
		TabAnimationSpeed = 0.3, -- Time in seconds for tab transitions
		ShowDescriptionsOnHover = true, -- Whether to show descriptions when hovering over tabs
		RememberLastTab = true, -- Whether to remember the last selected tab between menu opens
	}
}

-- Helper function to get side tabs in their specified order
function MenuStructure:GetOrderedSideTabs(topTabName)
	local topTab = self.TopTabs[topTabName]
	if not topTab then return {} end

	local sideTabs = table.clone(topTab.SideTabs)
	table.sort(sideTabs, function(a, b)
		return (a.Order or 999) < (b.Order or 999)
	end)

	return sideTabs
end

-- Helper function to get the content frame name for a specific tab combination
function MenuStructure:GetContentFrame(topTabName, sideTabName)
	local topTab = self.TopTabs[topTabName]
	if not topTab then return nil end

	for _, sideTab in ipairs(topTab.SideTabs) do
		if sideTab.Name == sideTabName then
			return sideTab.ContentFrame
		end
	end

	return nil
end

-- Helper function to get first side tab for a top tab
function MenuStructure:GetDefaultSideTab(topTabName)
	local orderedTabs = self:GetOrderedSideTabs(topTabName)
	return orderedTabs[1] and orderedTabs[1].Name
end

return MenuStructure
