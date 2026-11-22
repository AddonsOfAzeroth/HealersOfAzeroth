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

-- Razer Naga side plates, with Synapse's default keys. "none" is the old 1..5.
-- cols: how the plate looks (12: 3 wide, 4 high; 6: 2 x 3; 2: one above the other).
-- Synapse's Hypershift is set up as Shift, Ctrl and Alt: with "mods" on every
-- key also has a Shift, Ctrl and Alt layer (12 x 4 = 48 on the 12 plate).
B.PLATES = {
	none = { keys = B.HOVER_KEYS, cols = 5 },
	["12"] = { keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" }, cols = 3 },
	["6"] = { keys = { "4", "1", "5", "2", "6", "3" }, cols = 2 }, -- Synapse: left column 4 5 6, right column 1 2 3
	["2"] = { keys = { "BUTTON4", "BUTTON5" }, cols = 1 },
}
B.PLATE_ORDER = { "none", "12", "6", "2" }
-- every key any plate uses (for the class defaults and clearing old attributes)
B.ALL_KEYS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BUTTON4", "BUTTON5" }
B.MAX_HOVER = 12 -- virtual buttons hover1..hover12 (one per key on the biggest plate)

-- your class buff (the missing-buff mark; Alt + middle click gives it)
B.CLASS_BUFF = {
	PRIEST = { "Power Word: Fortitude", "Prayer of Fortitude" },
	DRUID = { "Mark of the Wild", "Gift of the Wild" },
	MAGE = { "Arcane Intellect", "Arcane Brilliance" },
	PALADIN = { "Blessing of Kings", "Greater Blessing of Kings", "Blessing of Might", "Greater Blessing of Might" },
}

-- per class: click -> spells, the first one you know is used (a spell by name
-- casts its highest rank). Hover keys are stored as "hover-" .. key (hover-1,
-- hover-=, hover-shift-1, hover-BUTTON4); 1-5 as before, 6 to = for the Naga.
local DEFAULTS = {
	PRIEST = {
		["1"] = { "Flash Heal", "Lesser Heal" }, ["2"] = { "Renew" }, ["3"] = { "Prayer of Mending", "Heal", "Lesser Heal" },
		["shift-1"] = { "Power Word: Shield" }, ["shift-2"] = { "Greater Heal", "Heal", "Lesser Heal" },
		["ctrl-1"] = { "Dispel Magic" }, ["ctrl-2"] = { "Abolish Disease", "Cure Disease" },
		["alt-1"] = { "Circle of Healing", "Prayer of Healing" }, ["alt-2"] = { "Resurrection" }, ["alt-3"] = { "Power Word: Fortitude" },
		["hover-1"] = { "Flash Heal", "Lesser Heal" }, ["hover-2"] = { "Renew" }, ["hover-3"] = { "Power Word: Shield" },
		["hover-4"] = { "Greater Heal", "Heal", "Lesser Heal" }, ["hover-5"] = { "Dispel Magic" },
		-- Naga keys 6 to =
		["hover-6"] = { "Prayer of Healing" }, ["hover-7"] = { "Abolish Disease", "Cure Disease" }, ["hover-8"] = { "Fear Ward", "Inner Fire" },
		["hover-9"] = { "Holy Nova" }, ["hover-0"] = { "Resurrection" }, ["hover--"] = { "Power Word: Fortitude" }, ["hover-="] = { "Shadow Protection" },
	},
	DRUID = {
		["1"] = { "Healing Touch" }, ["2"] = { "Rejuvenation" }, ["3"] = { "Lifebloom", "Regrowth" },
		["shift-1"] = { "Regrowth" }, ["shift-2"] = { "Swiftmend" },
		["ctrl-1"] = { "Remove Curse" }, ["ctrl-2"] = { "Abolish Poison", "Cure Poison" },
		["alt-1"] = { "Wild Growth", "Tranquility" }, ["alt-2"] = { "Rebirth" }, ["alt-3"] = { "Mark of the Wild" },
		["hover-1"] = { "Healing Touch" }, ["hover-2"] = { "Rejuvenation" }, ["hover-3"] = { "Regrowth" },
		["hover-4"] = { "Swiftmend" }, ["hover-5"] = { "Remove Curse" },
		["hover-6"] = { "Abolish Poison", "Cure Poison" }, ["hover-7"] = { "Lifebloom", "Regrowth" }, ["hover-8"] = { "Innervate" },
		["hover-9"] = { "Tranquility" }, ["hover-0"] = { "Rebirth" }, ["hover--"] = { "Mark of the Wild" }, ["hover-="] = { "Thorns" },
	},
	SHAMAN = {
		["1"] = { "Healing Wave" }, ["2"] = { "Lesser Healing Wave", "Healing Wave" }, ["3"] = { "Earth Shield" },
		["shift-1"] = { "Chain Heal" }, ["shift-2"] = { "Riptide", "Lesser Healing Wave" },
		["ctrl-1"] = { "Cure Toxins", "Cure Poison" }, ["ctrl-2"] = { "Cure Disease" },
		["alt-2"] = { "Ancestral Spirit" },
		["hover-1"] = { "Healing Wave" }, ["hover-2"] = { "Lesser Healing Wave", "Healing Wave" }, ["hover-3"] = { "Chain Heal" },
		["hover-4"] = { "Earth Shield" }, ["hover-5"] = { "Cure Toxins", "Cure Poison" },
		["hover-6"] = { "Cure Disease" }, ["hover-7"] = { "Water Walking" }, ["hover-8"] = { "Nature's Swiftness" },
		["hover-9"] = { "Mana Tide Totem" }, ["hover-0"] = { "Ancestral Spirit" }, ["hover--"] = { "Water Shield", "Lightning Shield" }, ["hover-="] = { "Water Breathing" },
	},
	PALADIN = {
		["1"] = { "Flash of Light", "Holy Light" }, ["2"] = { "Holy Light" }, ["3"] = { "Beacon of Light", "Blessing of Light" },
		["shift-1"] = { "Holy Shock" }, ["shift-2"] = { "Lay on Hands" },
		["ctrl-1"] = { "Cleanse", "Purify" }, ["ctrl-2"] = { "Blessing of Protection" },
		["alt-2"] = { "Redemption" }, ["alt-3"] = { "Blessing of Kings", "Blessing of Might" },
		["hover-1"] = { "Flash of Light", "Holy Light" }, ["hover-2"] = { "Holy Light" }, ["hover-3"] = { "Holy Shock" },
		["hover-4"] = { "Cleanse", "Purify" }, ["hover-5"] = { "Lay on Hands" },
		["hover-6"] = { "Blessing of Protection" }, ["hover-7"] = { "Blessing of Freedom" }, ["hover-8"] = { "Blessing of Sacrifice" },
		["hover-9"] = { "Divine Favor" }, ["hover-0"] = { "Redemption" }, ["hover--"] = { "Blessing of Kings", "Blessing of Might" }, ["hover-="] = { "Blessing of Wisdom" },
	},
	MAGE = {
		["ctrl-1"] = { "Remove Curse", "Remove Lesser Curse" },
		["shift-1"] = { "Arcane Intellect" }, ["shift-2"] = { "Amplify Magic", "Dampen Magic" }, ["alt-3"] = { "Arcane Intellect" },
		["hover-1"] = { "Remove Curse", "Remove Lesser Curse" },
		["hover-6"] = { "Arcane Intellect" }, ["hover-7"] = { "Arcane Brilliance", "Arcane Intellect" }, ["hover-8"] = { "Amplify Magic" }, ["hover-9"] = { "Dampen Magic" },
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

-- the plate you chose ("none": the old keys 1 to 5)
function B:Plate()
	local n = HoA.char and HoA.char.naga
	local p = type(n) == "table" and n.plate
	return self.PLATES[p] and p or "none"
end

-- the keys of that plate, in its order (top left to bottom right)
function B:HoverKeys() return self.PLATES[self:Plate()].keys end

-- the layers in use: plain, and with "mods" on also Shift, Ctrl and Alt
-- (Synapse's Hypershift). "none" stays plain 1 to 5, as before.
function B:HoverMods()
	local n = HoA.char and HoA.char.naga
	if self:Plate() ~= "none" and not (type(n) == "table" and n.mods == false) then return self.MODS end
	return { self.MODS[1] }
end

-- stable name a hover key is stored under: hover-1, hover-shift-1, hover-=, hover-alt-BUTTON5
function B:HoverName(mod, key) return "hover-" .. (mod or "") .. key end

-- the old names hover1..hover5 are read as hover-1..hover-5
function B:Name(key)
	local n = type(key) == "string" and key:match("^hover(%d)$")
	if n then return "hover-" .. n end
	return key
end

-- every slot of the plate: name (storage), key (WoW's key: "1", "SHIFT-=",
-- "ALT-BUTTON4"), mod ("shift-"), index (place on the plate) and button: the
-- virtual button "hoverN" the key clicks. A modifier picks the attribute the
-- same way it does for mouse clicks: SHIFT-1 clicks "hover1" with Shift held,
-- so Blizzard's secure button reads "shift-type-hover1".
function B:HoverSlots()
	local out = {}
	for _, m in ipairs(self:HoverMods()) do
		for i, key in ipairs(self:HoverKeys()) do
			out[#out + 1] = { name = self:HoverName(m[1], key), key = m[1]:upper() .. key, mod = m[1], label = m[2], index = i, button = "hover" .. i }
		end
	end
	return out
end

-- how a key reads for people: "Shift + =", "Mouse 4"
function B:KeyLabel(key, modLabel)
	local k = key:match("^BUTTON(%d+)$")
	k = k and (L["Mouse"] .. " " .. k) or key
	if modLabel and modLabel ~= "" then return L[modLabel] .. " + " .. k end
	return k
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
	local t = c.bindings
	if self.ready ~= t then
		-- hover1..hover5 (before the Naga plates) move to hover-1..hover-5
		for i = 1, 5 do
			local old = "hover" .. i
			if t[old] ~= nil then
				if t["hover-" .. i] == nil then t["hover-" .. i] = t[old] end
				t[old] = nil
			end
		end
		-- 1 to 5 always hold something (as before); the other keys only get
		-- the class defaults, the rest stays empty
		for _, key in ipairs(self.HOVER_KEYS) do
			local name = self:HoverName("", key)
			if t[name] == nil then t[name] = defaultFor(name) or { action = "none" } end
		end
		for _, m in ipairs(self.MODS) do
			for _, key in ipairs(self.ALL_KEYS) do
				local name = self:HoverName(m[1], key)
				if t[name] == nil then t[name] = defaultFor(name) end
			end
		end
		self.ready = t
	end
	return t
end

-- what a binding does now: "spell", name | "target" | "togglemenu" | nil
function B:Resolve(key)
	key = self:Name(key)
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

-- the hover keys that get bound while the mouse is on a frame. "none": all of
-- 1 to 5 (as before). A plate: only keys that do something, so an empty slot
-- (say Alt + 9) keeps doing what it did (action bar, Casters' Naga bar).
function B:BoundSlots()
	local out, all = {}, self:Plate() == "none"
	for _, s in ipairs(self:HoverSlots()) do
		if all or self:Resolve(s.name) then out[#out + 1] = s end
	end
	return out
end

-- the same as a string for the secure snippet: "1 hover1,SHIFT-= hover12"
function B:HoverKeyList()
	local parts = {}
	for _, s in ipairs(self:BoundSlots()) do parts[#parts + 1] = s.key .. " " .. s.button end
	return table.concat(parts, ",")
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
	-- hover keys press a virtual button "hoverN" on the frame under the mouse;
	-- first clear what another plate left behind
	for i = 1, self.MAX_HOVER do
		for _, m in ipairs(self.MODS) do
			button:SetAttribute(m[1] .. "type-hover" .. i, nil)
			button:SetAttribute(m[1] .. "spell-hover" .. i, nil)
		end
	end
	for _, s in ipairs(self:HoverSlots()) do
		local kind, spell = self:Resolve(s.name)
		button:SetAttribute(s.mod .. "type-" .. s.button, kind)
		button:SetAttribute(s.mod .. "spell-" .. s.button, spell)
	end
end

-- the snippet a frame runs when the mouse enters it: bind the hover keys to it
-- (true = a priority override, see WrapHover in Frames.lua)
function B:HoverEnter()
	if not HoA.char.hoverKeys then return "" end
	local lines = {}
	for _, s in ipairs(self:BoundSlots()) do
		lines[#lines + 1] = ("self:SetBindingClick(true, %q, self, %q)"):format(s.key, s.button)
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
	for _, s in ipairs(self:HoverSlots()) do
		local kind, spell = self:Resolve(s.name)
		if type(kind) == "string" then
			lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format(s.mod .. "type-" .. s.button, kind)
			if type(spell) == "string" then lines[#lines + 1] = ("self:SetAttribute(%q, %q)"):format(s.mod .. "spell-" .. s.button, spell) end
		end
	end
	return table.concat(lines, "\n")
end

-- what the plate keys do on one layer ("" plain, "shift-", ...): { { "Shift + 1", "Flash Heal" }, ... }
function B:HoverLines(mod)
	local out = {}
	for _, s in ipairs(self:HoverSlots()) do
		if s.mod == (mod or "") and self:Resolve(s.name) then
			out[#out + 1] = { self:KeyLabel(self:HoverKeys()[s.index], s.label), self:Label(s.name) }
		end
	end
	return out
end

function B:Set(key, value)
	if InCombatLockdown() then return end
	key = self:Name(key)
	local t = self:Get()
	if value == "target" or value == "menu" or value == "none" then
		t[key] = { action = value }
	else
		t[key] = { spell = value }
	end
	HoA:Fire("BINDINGS")
end

-- choose a plate: "none", "12", "6" or "2" (the frames follow out of combat)
function B:SetPlate(plate)
	if not self.PLATES[plate] then return end
	HoA.char.naga = type(HoA.char.naga) == "table" and HoA.char.naga or {}
	HoA.char.naga.plate = plate
	HoA:Fire("BINDINGS")
end

function B:Reset()
	HoA.char.bindings = nil
	self.ready = nil
	self:Get()
	HoA:Fire("BINDINGS")
end
