-- Healers of Azeroth by DinX: what a click does. Left, right and middle
-- button, each plain or with Shift, Ctrl or Alt: 12 clicks, each one a spell,
-- "target" or "menu". They become attributes on Blizzard's secure unit buttons,
-- so the click itself casts (your click; the add-on never casts by itself).
-- Attributes can only change out of combat.
local _, ns = ...
local HoA = ns.HoA
local L = HoA.L

local B = HoA:NewModule("Bindings")

B.BUTTONS = { { 1, "Left" }, { 2, "Right" }, { 3, "Middle" } }
B.MODS = { { "", "" }, { "shift-", "Shift" }, { "ctrl-", "Ctrl" }, { "alt-", "Alt" } }
-- hover keys: mouse over a frame and press one of these (only while hovering)
B.HOVER_KEYS = { "1", "2", "3", "4", "5" }

-- your class buff (the missing-buff mark; Alt + middle click gives it)
B.CLASS_BUFF = {
	PRIEST = { "Power Word: Fortitude", "Prayer of Fortitude" },
	DRUID = { "Mark of the Wild", "Gift of the Wild" },
	MAGE = { "Arcane Intellect", "Arcane Brilliance" },
	PALADIN = { "Blessing of Kings", "Greater Blessing of Kings", "Blessing of Might", "Greater Blessing of Might" },
}

-- per class: click -> spells, the first one you know is used (a spell by name
-- casts its highest rank)
local DEFAULTS = {
	PRIEST = {
		["1"] = { "Flash Heal", "Lesser Heal" }, ["2"] = { "Renew" }, ["3"] = { "Prayer of Mending", "Heal", "Lesser Heal" },
		["shift-1"] = { "Power Word: Shield" }, ["shift-2"] = { "Greater Heal", "Heal", "Lesser Heal" },
		["ctrl-1"] = { "Dispel Magic" }, ["ctrl-2"] = { "Abolish Disease", "Cure Disease" },
		["alt-1"] = { "Circle of Healing", "Prayer of Healing" }, ["alt-2"] = { "Resurrection" }, ["alt-3"] = { "Power Word: Fortitude" },
		hover1 = { "Flash Heal", "Lesser Heal" }, hover2 = { "Renew" }, hover3 = { "Power Word: Shield" },
		hover4 = { "Greater Heal", "Heal", "Lesser Heal" }, hover5 = { "Dispel Magic" },
	},
	DRUID = {
		["1"] = { "Healing Touch" }, ["2"] = { "Rejuvenation" }, ["3"] = { "Lifebloom", "Regrowth" },
		["shift-1"] = { "Regrowth" }, ["shift-2"] = { "Swiftmend" },
		["ctrl-1"] = { "Remove Curse" }, ["ctrl-2"] = { "Abolish Poison", "Cure Poison" },
		["alt-1"] = { "Wild Growth", "Tranquility" }, ["alt-2"] = { "Rebirth" }, ["alt-3"] = { "Mark of the Wild" },
		hover1 = { "Healing Touch" }, hover2 = { "Rejuvenation" }, hover3 = { "Regrowth" },
		hover4 = { "Swiftmend" }, hover5 = { "Remove Curse" },
	},
	SHAMAN = {
		["1"] = { "Healing Wave" }, ["2"] = { "Lesser Healing Wave", "Healing Wave" }, ["3"] = { "Earth Shield" },
		["shift-1"] = { "Chain Heal" }, ["shift-2"] = { "Riptide", "Lesser Healing Wave" },
		["ctrl-1"] = { "Cure Toxins", "Cure Poison" }, ["ctrl-2"] = { "Cure Disease" },
		["alt-2"] = { "Ancestral Spirit" },
		hover1 = { "Healing Wave" }, hover2 = { "Lesser Healing Wave", "Healing Wave" }, hover3 = { "Chain Heal" },
		hover4 = { "Earth Shield" }, hover5 = { "Cure Toxins", "Cure Poison" },
	},
	PALADIN = {
		["1"] = { "Flash of Light", "Holy Light" }, ["2"] = { "Holy Light" }, ["3"] = { "Beacon of Light", "Blessing of Light" },
		["shift-1"] = { "Holy Shock" }, ["shift-2"] = { "Lay on Hands" },
		["ctrl-1"] = { "Cleanse", "Purify" }, ["ctrl-2"] = { "Blessing of Protection" },
		["alt-2"] = { "Redemption" }, ["alt-3"] = { "Blessing of Kings", "Blessing of Might" },
		hover1 = { "Flash of Light", "Holy Light" }, hover2 = { "Holy Light" }, hover3 = { "Holy Shock" },
		hover4 = { "Cleanse", "Purify" }, hover5 = { "Lay on Hands" },
	},
	MAGE = {
		["ctrl-1"] = { "Remove Curse", "Remove Lesser Curse" },
		["shift-1"] = { "Arcane Intellect" }, ["shift-2"] = { "Amplify Magic", "Dampen Magic" }, ["alt-3"] = { "Arcane Intellect" },
		hover1 = { "Remove Curse", "Remove Lesser Curse" },
	},
}

-- the spells a click can be set to: everything in DEFAULTS for your class
function B:Candidates()
	local class = select(2, UnitClass("player"))
	local seen, out = {}, {}
	for _, list in pairs(DEFAULTS[class] or {}) do
		for _, name in ipairs(list) do
			if not seen[name] and self:Known(name) then seen[name] = true out[#out + 1] = name end
		end
	end
	table.sort(out)
	return out
end

function B:Known(name)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(name)
		if info and info.spellID then
			if IsPlayerSpell and IsPlayerSpell(info.spellID) then return true end
			if IsSpellKnown and IsSpellKnown(info.spellID) then return true end
		end
	end
	if GetSpellInfo and GetSpellInfo(name) and IsUsableSpell then return (IsUsableSpell(name)) ~= nil end
	return false
end

-- default actions: left = target and right = menu unless the class has a spell
local function defaultFor(key)
	local class = select(2, UnitClass("player"))
	local list = DEFAULTS[class] and DEFAULTS[class][key]
	if list then return { spells = list } end
	if key == "1" then return { action = "target" } end
	if key == "2" then return { action = "menu" } end
end

-- your bindings: { [key] = { spell = name } | { action = "target"|"menu"|"none" } | { spells = {...} } }
function B:Get()
	local c = HoA.char
	if type(c.bindings) ~= "table" then
		c.bindings = {}
		for _, b in ipairs(self.BUTTONS) do
			for _, m in ipairs(self.MODS) do
				local key = m[1] .. b[1]
				c.bindings[key] = defaultFor(key)
			end
		end
	end
	for i = 1, #self.HOVER_KEYS do
		local key = "hover" .. i
		if c.bindings[key] == nil then c.bindings[key] = defaultFor(key) or { action = "none" } end
	end
	return c.bindings
end

-- what a binding does now: "spell", name | "target" | "togglemenu" | nil
function B:Resolve(key)
	local b = self:Get()[key]
	if type(b) ~= "table" then return end
	if b.action == "target" then return "target" end
	if b.action == "menu" then return "togglemenu" end
	if b.action == "none" then return end
	if b.spell then return "spell", b.spell end
	for _, name in ipairs(b.spells or {}) do
		if self:Known(name) then return "spell", name end
	end
	-- nothing known yet (low level): plain left click still targets
	if key == "1" then return "target" end
end

function B:Label(key)
	local kind, spell = self:Resolve(key)
	if kind == "spell" then return spell end
	if kind == "target" then return L["Target"] end
	if kind == "togglemenu" then return L["Menu"] end
	return L["Nothing"]
end

-- put the attributes on one secure button (out of combat)
function B:Apply(button)
	if InCombatLockdown() or not button then return end
	for _, b in ipairs(self.BUTTONS) do
		for _, m in ipairs(self.MODS) do
			local key = m[1] .. b[1]
			local kind, spell = self:Resolve(key)
			button:SetAttribute(m[1] .. "type" .. b[1], kind)
			button:SetAttribute(m[1] .. "spell" .. b[1], spell)
		end
	end
	-- hover keys press a virtual button "hoverN" on the frame under the mouse
	for i = 1, #self.HOVER_KEYS do
		local kind, spell = self:Resolve("hover" .. i)
		button:SetAttribute("type-hover" .. i, kind)
		button:SetAttribute("spell-hover" .. i, spell)
	end
end

-- the snippet a frame runs when the mouse enters it: bind the hover keys to it
function B:HoverEnter()
	if not HoA.char.hoverKeys then return "" end
	local lines = {}
	for i, key in ipairs(self.HOVER_KEYS) do
		lines[#lines + 1] = ("self:SetBindingClick(true, %q, self, %q)"):format(key, "hover" .. i)
	end
	return table.concat(lines, "\n")
end

-- the same as a snippet for frames the group header makes later (in combat too)
function B:Snippet()
	local lines = {}
	for _, b in ipairs(self.BUTTONS) do
		for _, m in ipairs(self.MODS) do
			local key = m[1] .. b[1]
			local kind, spell = self:Resolve(key)
			if type(kind) == "string" then
				lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format(m[1] .. "type" .. b[1], kind)
				if type(spell) == "string" then lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format(m[1] .. "spell" .. b[1], spell) end
			end
		end
	end
	for i = 1, #self.HOVER_KEYS do
		local kind, spell = self:Resolve("hover" .. i)
		if type(kind) == "string" then
			lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format("type-hover" .. i, kind)
			if type(spell) == "string" then lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format("spell-hover" .. i, spell) end
		end
	end
	return table.concat(lines, "\n")
end

function B:Set(key, value)
	local t = self:Get()
	if value == "target" or value == "menu" or value == "none" then
		t[key] = { action = value }
	else
		t[key] = { spell = value }
	end
	HoA:Fire("BINDINGS")
end

function B:Reset()
	HoA.char.bindings = nil
	self:Get()
	HoA:Fire("BINDINGS")
end
