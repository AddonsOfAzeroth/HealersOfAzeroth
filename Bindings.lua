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

-- Razer Naga side plates in Synapse's button numbers, row by row as the thumb
-- sees them (Synapse numbers the buttons of each plate 1..N). "none" is the old
-- keyboard keys 1..5. 12: 3 wide, 4 high; 6: 2 x 3 with the left column 6 5 4
-- and the right column 1 2 3; 2: button 1 above button 2. Synapse's Hypershift
-- is set up as Shift, Ctrl and Alt: with "mods" on every key also has a Shift,
-- Ctrl and Alt layer (12 x 4 = 48 on the 12 plate).
B.PLATES = {
	none = { cols = 5, layout = { { 1, 2, 3, 4, 5 } } },
	["12"] = { cols = 3, layout = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 }, { 10, 11, 12 } } },
	["6"] = { cols = 2, layout = { { 6, 1 }, { 5, 2 }, { 4, 3 } } },
	["2"] = { cols = 1, layout = { { 1 }, { 2 } } },
}
B.PLATE_ORDER = { "none", "12", "6", "2" }

-- Keysets: the WoW key each Synapse button sends. "standard" is Synapse's
-- default (1..9, 0, -, =), "numpad" is Num1..Num9, Num0, Num-, Num+; "learned"
-- comes from Nagas of Azeroth's learn mode (naga.learned[plate]). The 2-button
-- plate is mouse button 4 above 5 in standard and numpad; "none" is always 1..5.
B.KEYSETS = {
	standard = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
	numpad = { "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9",
		"NUMPAD0", "NUMPADMINUS", "NUMPADPLUS" },
}
B.KEYSET_ORDER = { "standard", "numpad" } -- "learned" is pushed by Nagas of Azeroth
local MOUSE_PLATE = { "BUTTON4", "BUTTON5" }

-- Hover spells are stored per button number, so a button keeps its spell
-- whatever key it sends: "b3" is button 3 of the 12 or 6 plate (and key 3 of
-- "none"), "m1" and "m2" are the 2-button plate. The old names by key (from
-- the standard keys) map onto them: "1".."9" -> b1..b9, "0" b10, "-" b11,
-- "=" b12, BUTTON4 m1, BUTTON5 m2.
B.ID_OF_KEY = { ["0"] = "b10", ["-"] = "b11", ["="] = "b12", BUTTON4 = "m1", BUTTON5 = "m2" }
for n = 1, 9 do B.ID_OF_KEY[tostring(n)] = "b" .. n end
B.ALL_IDS = { "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "b11", "b12", "m1", "m2" }

for key, p in pairs(B.PLATES) do
	p.buttons = {} -- button numbers in grid order (top left to bottom right)
	p.keys = {}    -- the standard keys in that order (Synapse's defaults)
	for _, row in ipairs(p.layout) do
		for _, n in ipairs(row) do
			p.buttons[#p.buttons + 1] = n
			p.keys[#p.keys + 1] = key == "2" and MOUSE_PLATE[n] or B.KEYSETS.standard[n]
		end
	end
end
-- every standard key any plate uses (for the class defaults)
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
-- casts its highest rank). Hover keys are written here by their standard key
-- (hover-1, hover-=, hover-shift-1) and stored by button number (hover-b1,
-- hover-b12, hover-shift-b1; see B:Name); 1-5 as before, 6 to = for the Naga.
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

local function nagaCfg()
	local n = HoA.char and HoA.char.naga
	return type(n) == "table" and n or {}
end

-- the plate you chose ("none": the old keys 1 to 5)
function B:Plate()
	local p = nagaCfg().plate
	return self.PLATES[p] and p or "none"
end

-- the keyset as chosen (saved): "standard", "numpad" or "learned"
function B:KeysetChoice()
	local k = nagaCfg().keyset
	if k == "numpad" or k == "learned" then return k end
	return "standard"
end

-- the learned keys per plate, pushed by Nagas of Azeroth (nil: none)
function B:Learned()
	local l = nagaCfg().learned
	return type(l) == "table" and l or nil
end

-- the keyset in use: "learned" only when this plate was learned
function B:Keyset()
	local k = self:KeysetChoice()
	if k == "learned" then
		local l = self:Learned()
		return (l and type(l[self:Plate()]) == "table") and "learned" or "standard"
	end
	return k
end

-- the WoW key of button n (false: none, a button the learn mode skipped)
function B:KeyOf(plate, keyset, n)
	if plate == "none" then return self.KEYSETS.standard[n] or false end
	if keyset == "learned" then
		local l = self:Learned()
		local k = l and type(l[plate]) == "table" and l[plate][n]
		return type(k) == "string" and k ~= "" and k or false
	end
	if plate == "2" then return MOUSE_PLATE[n] or false end
	return (self.KEYSETS[keyset] or self.KEYSETS.standard)[n] or false
end

-- the storage id of button n on a plate: "b3", or "m1" on the 2-button plate
function B:SlotId(plate, n) return (plate == "2" and "m" or "b") .. n end

-- the plate in use: { cols, buttons, keys (WoW key or false per cell), ids }
local infoCache = {}
function B:PlateInfo()
	local plate, keyset = self:Plate(), self:Keyset()
	local sig = plate .. "|" .. keyset .. "|" .. (self.keysRev or 0)
	if infoCache.sig == sig then return infoCache.info end
	local p = self.PLATES[plate]
	local info = { cols = p.cols, buttons = p.buttons, keys = {}, ids = {}, plate = plate, keyset = keyset }
	for i, n in ipairs(p.buttons) do
		info.keys[i] = self:KeyOf(plate, keyset, n)
		info.ids[i] = self:SlotId(plate, n)
	end
	infoCache.sig, infoCache.info = sig, info
	return info
end

-- the keys of that plate, in its order (top left to bottom right; false = no key)
function B:HoverKeys() return self:PlateInfo().keys end

-- numpad keys: Windows turns Shift + a numpad key (NumLock on) into another
-- key, so WoW never sees SHIFT-NUMPAD1. The Shift layer is then off by default.
function B:HasNumpad()
	for _, k in ipairs(self:HoverKeys()) do
		if k and k:match("^NUMPAD") then return true end
	end
	return false
end

-- the Shift layer choice: "auto", true or false
function B:ShiftChoice()
	local v = nagaCfg().shift
	if v == true or v == false then return v end
	return "auto"
end

function B:ShiftOn()
	local v = self:ShiftChoice()
	if v ~= "auto" then return v end
	return not self:HasNumpad()
end

-- the layers in use: plain, and with "mods" on also Shift, Ctrl and Alt
-- (Synapse's Hypershift; Shift not with numpad keys). "none" stays plain 1 to 5.
function B:HoverMods()
	local n = HoA.char and HoA.char.naga
	if self:Plate() ~= "none" and not (type(n) == "table" and n.mods == false) then
		if self:ShiftOn() then return self.MODS end
		return { self.MODS[1], self.MODS[3], self.MODS[4] }
	end
	return { self.MODS[1] }
end

-- stable name a hover key is stored under: hover-b1, hover-shift-b1, hover-b12,
-- hover-alt-m2. id is a storage id ("b3", "m1") or an old standard key ("3", "=").
function B:HoverName(mod, id) return "hover-" .. (mod or "") .. (self.ID_OF_KEY[id] or id) end

local MODNAMES = { ["shift-"] = true, ["ctrl-"] = true, ["alt-"] = true }

-- old names are read as the new ones: hover1..hover5 -> hover-b1..hover-b5,
-- hover-<mod><key> -> hover-<mod><id> (hover-= -> hover-b12, hover-shift-BUTTON4 -> hover-shift-m1)
function B:Name(key)
	if type(key) ~= "string" then return key end
	local n = key:match("^hover(%d)$")
	if n then return "hover-b" .. n end
	local rest = key:match("^hover%-(.+)$")
	if not rest then return key end
	local mod = rest:match("^(%a+%-).")
	if mod and MODNAMES[mod] then rest = rest:sub(#mod + 1) else mod = "" end
	local id = self.ID_OF_KEY[rest]
	if id then return "hover-" .. mod .. id end
	return key
end

-- the class defaults by storage name (they are written by key above)
for class, list in pairs(DEFAULTS) do
	local out = {}
	for k, v in pairs(list) do out[B:Name(k)] = v end
	DEFAULTS[class] = out
end

-- every slot of the plate: name (storage, by button number), key (WoW's key:
-- "1", "SHIFT-=", "CTRL-NUMPAD1", "ALT-BUTTON4"), mod ("shift-"), index (place
-- on the plate), number (Synapse's button number) and button: the virtual
-- button "hoverN" the key clicks. A modifier picks the attribute the same way
-- it does for mouse clicks: SHIFT-1 clicks "hover1" with Shift held, so
-- Blizzard's secure button reads "shift-type-hover1". A skipped button has no slot.
function B:HoverSlots()
	local out = {}
	local info = self:PlateInfo()
	for _, m in ipairs(self:HoverMods()) do
		for i, key in ipairs(info.keys) do
			if key then
				out[#out + 1] = { name = self:HoverName(m[1], info.ids[i]), key = m[1]:upper() .. key, mod = m[1], label = m[2],
					index = i, number = info.buttons[i], button = "hover" .. i }
			end
		end
	end
	return out
end

local NUMPAD_TEXT = { NUMPADMINUS = "-", NUMPADPLUS = "+", NUMPADMULTIPLY = "*", NUMPADDIVIDE = "/", NUMPADDECIMAL = "." }

-- how a key reads for people: "Shift + =", "Mouse 4", "Ctrl + Num1"; no key: "-"
function B:KeyLabel(key, modLabel)
	if not key then return "-" end
	local k = key:match("^BUTTON(%d+)$")
	k = k and (L["Mouse"] .. " " .. k)
	if not k then
		local np = key:match("^NUMPAD(.+)$")
		k = np and ("Num" .. (NUMPAD_TEXT[key] or np)) or key
	end
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
		-- hover-<mod><key> (by key) move to hover-<mod><id> (by button number);
		-- a name already stored by button number wins
		local old = {}
		for k in pairs(t) do
			local new = self:Name(k)
			if new ~= k then old[#old + 1] = k end
		end
		table.sort(old)
		for _, k in ipairs(old) do
			local new = self:Name(k)
			if t[new] == nil then t[new] = t[k] end
			t[k] = nil
		end
		-- 1 to 5 always hold something (as before); the other keys only get
		-- the class defaults, the rest stays empty
		for _, key in ipairs(self.HOVER_KEYS) do
			local name = self:HoverName("", key)
			if t[name] == nil then t[name] = defaultFor(name) or { action = "none" } end
		end
		for _, m in ipairs(self.MODS) do
			for _, id in ipairs(self.ALL_IDS) do
				local name = self:HoverName(m[1], id)
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

-- choose the keys the Synapse buttons send: "standard", "numpad" or "learned".
-- learned (optional): { [plate] = { [button number] = WoW key } }, as Nagas of
-- Azeroth's learn mode saves it. The spells stay on their button numbers; the
-- Shift layer goes back to automatic (off with numpad keys). Out of combat
-- the frames follow (as with the plate).
function B:SetKeyset(keyset, learned)
	if keyset ~= "standard" and keyset ~= "numpad" and keyset ~= "learned" then return end
	HoA.char.naga = type(HoA.char.naga) == "table" and HoA.char.naga or {}
	local n = HoA.char.naga
	if type(learned) == "table" then
		local copy = {}
		for plate, keys in pairs(learned) do
			if self.PLATES[plate] and plate ~= "none" and type(keys) == "table" then
				copy[plate] = {}
				for i = 1, 12 do
					if type(keys[i]) == "string" and keys[i] ~= "" then copy[plate][i] = keys[i] end
				end
			end
		end
		n.learned = copy
	end
	n.keyset = keyset
	n.shift = "auto"
	self.keysRev = (self.keysRev or 0) + 1
	HoA:Fire("BINDINGS")
end

-- the Shift layer: "auto" (off with numpad keys), true or false
function B:SetShift(v)
	if v ~= true and v ~= false then v = "auto" end
	HoA.char.naga = type(HoA.char.naga) == "table" and HoA.char.naga or {}
	if HoA.char.naga.shift == v then return end
	HoA.char.naga.shift = v
	HoA:Fire("BINDINGS")
end

function B:Reset()
	HoA.char.bindings = nil
	self.ready = nil
	self:Get()
	HoA:Fire("BINDINGS")
end
