local UtilityModule = {}

-- Unicode symbols for each stat
UtilityModule.Stat_Details = {
	Defense = "🛡️",
	Healing = "🩹",
	Attack = "⚔️",
	Elemental = "🔥"
}

-- Elemental damage types and their associated symbols and image IDs
UtilityModule.Elemental_Details = {
	Dark   = {Symbol = "🌑", Image = "rbxassetid://91973165054454"},
	Fire   = {Symbol = "🔥", Image = "rbxassetid://103833211852692"},
	Nature = {Symbol = "🌿", Image = "rbxassetid://92225337151288"},
	Light  = {Symbol = "☀️", Image = "rbxassetid://76576818307567"},
	Metal  = {Symbol = "🛠️", Image = "rbxassetid://116051866854026"},
	Water  = {Symbol = "💧", Image = "rbxassetid://138995974199112"}
}

-------------------------
-- Choose a random element
-------------------------
function UtilityModule.GetRandomElement()
	local elements = {}
	for element in pairs(UtilityModule.Elemental_Details) do
		table.insert(elements, element)
	end
	return elements[math.random(1, #elements)]
end

-------------------------
-- Get symbol or image based on element 
-------------------------
function UtilityModule.GetElementalDetails(element, detailType)
	if UtilityModule.Elemental_Details[element] then
		return UtilityModule.Elemental_Details[element][detailType] or "❓"
	end
	return "❓"  -- Returns a question mark if element not found
end

-------------------------
-- Roll dice and return the total
-------------------------
function UtilityModule.RollDice(number, sides)
	local total = 0
	for i = 1, number do
		total = total + math.random(1, sides)
	end
	return total
end

-- Rolls a random result based on weighted probabilities
function UtilityModule.RollProbability(probabilityTable: Types.ProbabilityTable): string
	-- Validate input
	if not probabilityTable then
		warn("RollProbability: Probability table is nil")
		return nil
	end

	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(probabilityTable) do
		if type(weight) == "number" then
			totalWeight += weight
		end
	end

	if totalWeight <= 0 then
		warn("RollProbability: Total probability is 0 or negative")
		return nil
	end

	-- Generate random number
	local roll = math.random(1, math.ceil(totalWeight))

	-- Find matching range
	local currentWeight = 0
	for result, weight in pairs(probabilityTable) do
		if type(weight) == "number" then
			currentWeight += weight
			if roll <= currentWeight then
				return result
			end
		end
	end

	-- If we somehow got here, return first valid result
	for result, weight in pairs(probabilityTable) do
		if type(weight) == "number" and weight > 0 then
			return result
		end
	end

	return nil
end

-------------------------
-- Apply Physical Damage
-------------------------
function UtilityModule.ApplyElementalDamage(attacker, defender, damage, damageElement)
	-- Record full damage
	local fullDamage = damage
	
	-- Get defender's stats
	local resistAmount = defender:GetAttribute("Resistance") or 0
	local resistElement = defender:GetAttribute("ResistElement") or ""
	local defenderTemp = defender:GetAttribute("TempHP") or 0
	local defenderHP = defender:GetAttribute("HP")

	-- Subtract resistance from damage
	if resistElement == damageElement then
		-- Apply resistance if elements match
		damage = damage - resistAmount
		if damage < 0 then
			damage = 0
		end
	end

	-- Apply damage to Temp HP
	if damage > defenderTemp then
		-- Reduce damage by Temp HP
		damage = damage - defenderTemp
		defender:SetAttribute("TempHP", 0)
	else
		-- Reduce Temp HP by damage amount
		defender:SetAttribute("TempHP", defenderTemp - damage)
		damage = 0
	end

	-- Apply remaining damage to HP
	defenderHP = defenderHP - damage
	if defenderHP < 0 then defenderHP = 0 end
	defender:SetAttribute("HP", defenderHP)

	print(attacker:GetAttribute("Name") .. " dealt " .. fullDamage .. " " .. damageElement .. " damage. " .. defender:GetAttribute("Name") .. " took " .. damage .. " and has " .. defender:GetAttribute("AC") .. " AC, " .. defender:GetAttribute("TempHP") .. " Temp, " .. defender:GetAttribute("HP") .. " HP")
end

-------------------------
-- Apply Physical Damage
-------------------------
function UtilityModule.ApplyPhysicalDamage(attacker, defender, damage)
	-- Record the full damage
	local fullDamage = damage
	
	-- Get defender's stats
	local armorAmount = defender:GetAttribute("AC") or 0
	local defenderTemp = defender:GetAttribute("TempHP") or 0
	local defenderHP = defender:GetAttribute("HP")

	-- Apply damage to armor
	if damage > 0 and damage >= armorAmount then
		damage = damage - armorAmount
		defender:SetAttribute("AC", 0)
	else
		defender:SetAttribute("AC", armorAmount - damage)
		damage = 0
	end

	-- Apply remaining damage to Temp HP
	if damage > 0 and damage >= defenderTemp then
		damage = damage - defenderTemp
		defender:SetAttribute("TempHP", 0)
	else
		defender:SetAttribute("TempHP", defenderTemp - damage)
		damage = 0
	end

	-- Apply remaining damage to HP
	if damage > 0 and damage >= defenderHP then
		-- Recognize overkill damage
		if damage >= defenderHP + 100 then
			print("Fucking overkill, bro!!!!!!!")
		end
		defender:SetAttribute("HP", 0)
	else
		-- Apply damage to target
		defenderHP = defenderHP - damage
		if defenderHP < 0 then defenderHP = 0 end
		defender:SetAttribute("HP", defenderHP)
	end
	
	print(attacker:GetAttribute("Name") .. " dealt " .. fullDamage .. " damage. " .. defender:GetAttribute("Name") .. " took " .. damage .. " and has " .. defender:GetAttribute("AC") .. " AC, " .. defender:GetAttribute("TempHP") .. " Temp, " .. defender:GetAttribute("HP") .. " HP")
end

-------------------------
-- Apply Healing
-------------------------
function UtilityModule.ApplyHealing(die, healing)
	local currentHP = die:GetAttribute("HP")
	local tempHP = die:GetAttribute("TempHP") or 0
	local maxHP = die:GetAttribute("MaxHP")

	-- Calculate new HP after healing
	local newHP = currentHP + healing

	if newHP > maxHP then
		-- If healing exceeds max HP, calculate the excess and add to TempHP
		local excessHealing = newHP - maxHP
		die:SetAttribute("HP", maxHP)
		tempHP = tempHP + math.floor(excessHealing / 2)
		
		-- Ensure TempHP does not exceed 50% of max HP
		local maxTempHP = maxHP * 0.5
		if tempHP > maxTempHP then
			tempHP = maxTempHP
		end

		-- Set the TempHP attribute on the dice
		die:SetAttribute("TempHP", tempHP)
	else
		-- Otherwise, just add the healing to current HP
		die:SetAttribute("HP", newHP)
	end

	print(die:GetAttribute("Name") .. " healed " .. healing .. " and has " .. die:GetAttribute("HP") .. " HP and " .. die:GetAttribute("TempHP") .. " Temp")
end

return UtilityModule
