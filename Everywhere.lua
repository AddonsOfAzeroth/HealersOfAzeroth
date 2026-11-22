-- Healers of Azeroth by DinX: hover keys everywhere. The plate keys also cast
-- on any friendly unit under the mouse ("mouseover"): other add-ons' frames,
-- Blizzard's frames, nameplates, characters in the world. Over nothing friendly
-- the key does what it did before.
--
-- How: per plate key a SecureActionButton with a macro (Blizzard's own macro
-- conditionals; one key press runs it once and does exactly one thing):
--   /cast [@mouseover,help,nodead,nomod] Flash Heal; [@mouseover,help,nodead,mod:shift] Renew
--   /stopmacro [@mouseover,help,nodead,nomod][@mouseover,help,nodead,mod:shift]
--   /click ActionButton1
-- The /click is the key's own binding from before (read out of combat). Keys
-- are bound with SetOverrideBindingClick, out of combat only; in combat nothing
-- changes (it is rebuilt when the fight ends).
--
-- Priority: Casters of Azeroth's Naga bar uses a *priority* override, so ours is
-- one too, set after it (the newest override of a key wins). Our group frames
-- set theirs on every mouse enter, so over them they still win; on leave ours
-- is back. A key whose binding we can't click (a non-bar command such as
-- "TARGETNEARESTENEMY") is left alone: /hoa hover lists those.
local _, ns = ...
local HoA = ns.HoA
local L = HoA.L

local V = HoA:NewModule("Everywhere")

V.MAX_MACRO = 255 -- WoW's limit for a macro's text
V.PREFIX = "HealersOfAzerothHover" -- our buttons: HealersOfAzerothHover1, 2, ...
-- only friendly, living units (a resurrection: only friendly dead ones)
V.FRIEND = "@mouseover,help,nodead"
V.DEAD = "@mouseover,help,dead"
V.RES = { ["Resurrection"] = true, ["Redemption"] = true, ["Ancestral Spirit"] = true, ["Rebirth"] = true }
local COND = { [""] = "nomod", ["shift-"] = "mod:shift", ["ctrl-"] = "mod:ctrl", ["alt-"] = "mod:alt" }

-- Blizzard's bar bindings and the button a key presses for them
local BARS = {
	{ "^ACTIONBUTTON(%d+)$", "ActionButton" },
	{ "^MULTIACTIONBAR1BUTTON(%d+)$", "MultiBarBottomLeftButton" },
	{ "^MULTIACTIONBAR2BUTTON(%d+)$", "MultiBarBottomRightButton" },
	{ "^MULTIACTIONBAR3BUTTON(%d+)$", "MultiBarRightButton" },
	{ "^MULTIACTIONBAR4BUTTON(%d+)$", "MultiBarLeftButton" },
	{ "^MULTIACTIONBAR5BUTTON(%d+)$", "MultiBar5Button" },
	{ "^MULTIACTIONBAR6BUTTON(%d+)$", "MultiBar6Button" },
	{ "^MULTIACTIONBAR7BUTTON(%d+)$", "MultiBar7Button" },
	{ "^SHAPESHIFTBUTTON(%d+)$", "StanceButton" },
	{ "^BONUSACTIONBUTTON(%d+)$", "PetActionButton" },
}

V.buttons = {}
V.fallback = {} -- [WoW key] = { frame, button } | {} (unbound) | false (can't click)
V.groups = {}   -- what is bound now: { { keys = { "1", "SHIFT-1" }, text = macro }, ... }
V.skipped = {}  -- { { key = "ALT-9", why = "TARGETNEARESTENEMY" }, ... }

local function now() return GetTime and GetTime() or 0 end

local function on()
	local c = HoA.char
	return c and c.hoverKeys and c.hoverEverywhere ~= false and true or false
end

-- a harmful spell is never cast by this path (only friendly targets)
local function harmful(name)
	local fn = (C_Spell and C_Spell.IsSpellHarmful) or IsHarmfulSpell
	if not fn then return false end
	local ok, r = pcall(fn, name)
	return ok and r and true or false
end

-- action buttons act on key down or key up, as Blizzard's setting says; ours
-- and the /click follow it, so a press is one click, never two
local function keyDown()
	return GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") and true or false
end

-- a binding -> what /click presses: frame, button | "" (unbound) | nil (can't)
function V:Target(action)
	if action == nil or action == "" then return "" end
	local frame, button = action:match("^CLICK ([^:]+):(.+)$")
	if not frame then frame = action:match("^CLICK (%S+)$") button = "LeftButton" end
	if frame then return frame, button end
	for _, b in ipairs(BARS) do
		local n = action:match(b[1])
		if n and _G[b[2] .. n] then return b[2] .. n, "LeftButton" end
	end
end

-- what a key does without us. Our group frames' own hover click (the mouse is
-- on one right now) hides what is below: keep what we read before
function V:Read(key)
	local action = GetBindingAction(key, true)
	local button = type(action) == "string" and action:match("^CLICK [^:]+:(hover%d+)$")
	if button then
		self.busy = true
		return self.fallback[key], action
	end
	local frame, btn = self:Target(action)
	if frame == "" then return {}, action end
	-- never one of our own buttons (it would click itself)
	if frame and frame:sub(1, #self.PREFIX) ~= self.PREFIX then return { frame, btn }, action end
	return false, action
end

local function cond(l)
	return "[" .. (V.RES[l.spell] and V.DEAD or V.FRIEND) .. "," .. COND[l.mod] .. "]"
end

-- the macro for one or more layers of a key (one button)
function V:Macro(layers)
	local cast, stop = {}, {}
	for _, l in ipairs(layers) do
		cast[#cast + 1] = cond(l) .. " " .. l.spell
		stop[#stop + 1] = cond(l)
	end
	local lines = { "/cast " .. table.concat(cast, "; "), "/stopmacro " .. table.concat(stop) }
	-- over nothing friendly: the key's own binding (by modifier when they differ)
	local down = keyDown() and " 1" or ""
	local clicks, same, first = {}, true, nil
	for _, l in ipairs(layers) do
		local fb = l.fallback
		local to = fb and fb[1] and (fb[1] .. " " .. fb[2] .. down)
		if to then clicks[#clicks + 1] = "[" .. COND[l.mod] .. "] " .. to end
		if first == nil then first = to or false end
		if to ~= first then same = false end
	end
	if same and first then
		lines[3] = "/click " .. first
	elseif #clicks > 0 then
		lines[3] = "/click " .. table.concat(clicks, "; ")
	end
	return table.concat(lines, "\n")
end

-- every key of the plate with a hover spell: read its fallback and group the
-- layers per key into one button (split per layer when the macro is too long)
function V:Plan()
	local B = HoA.Bindings
	local groups, skipped = {}, {}
	self.busy = false
	if not on() then return groups, skipped end
	-- the plate's keys as the keyset sends them (a skipped button has none);
	-- the spells are stored per button number
	local info = B:PlateInfo()
	for i, key in ipairs(info.keys) do
		local layers = {}
		for _, m in ipairs(key and B:HoverMods() or {}) do
			local full = m[1]:upper() .. key
			local kind, spell = B:Resolve(B:HoverName(m[1], info.ids[i]))
			if kind == "spell" and type(spell) == "string" then
				local fb, action = self:Read(full)
				self.fallback[full] = fb
				if harmful(spell) then
					skipped[#skipped + 1] = { key = full, why = "harm", spell = spell }
				elseif fb == nil then
					skipped[#skipped + 1] = { key = full, why = "busy" }
				elseif fb == false then
					skipped[#skipped + 1] = { key = full, why = tostring(action) }
				else
					layers[#layers + 1] = { mod = m[1], key = full, spell = spell, fallback = fb }
				end
			end
		end
		if #layers > 0 then
			local text = self:Macro(layers)
			if #text <= self.MAX_MACRO then
				local keys = {}
				for _, l in ipairs(layers) do keys[#keys + 1] = l.key end
				groups[#groups + 1] = { keys = keys, text = text }
			else
				-- too long for one macro: a button per layer (SHIFT-1 its own)
				for _, l in ipairs(layers) do
					local one = self:Macro({ l })
					if #one <= self.MAX_MACRO then
						groups[#groups + 1] = { keys = { l.key }, text = one }
					else
						skipped[#skipped + 1] = { key = l.key, why = "long" }
					end
				end
			end
		end
	end
	return groups, skipped
end

function V:Owner()
	self.owner = self.owner or CreateFrame("Frame", "HealersOfAzerothEverywhere", UIParent)
	return self.owner
end

function V:Button(i)
	local b = self.buttons[i]
	if not b then
		b = CreateFrame("Button", self.PREFIX .. i, UIParent, "SecureActionButtonTemplate")
		b:Hide()
		self.buttons[i] = b
	end
	return b
end

-- out of combat: take our keys off, read what they do now, put them back
function V:Rebuild()
	if InCombatLockdown() then return HoA:OutOfCombat("hoa-everywhere", function() V:Rebuild() end) end
	if not (SetOverrideBindingClick and ClearOverrideBindings and GetBindingAction) then return end
	self.quietUntil = now() + 0.5
	local owner = self:Owner()
	ClearOverrideBindings(owner)
	local groups, skipped = self:Plan()
	local click = keyDown() and "AnyDown" or "AnyUp"
	for i, g in ipairs(groups) do
		local b = self:Button(i)
		b:RegisterForClicks(click)
		b:SetAttribute("type", "macro")
		b:SetAttribute("macrotext", g.text)
		for _, key in ipairs(g.keys) do
			SetOverrideBindingClick(owner, true, key, b:GetName(), "LeftButton")
		end
	end
	for i = #groups + 1, #self.buttons do
		self.buttons[i]:SetAttribute("type", nil)
		self.buttons[i]:SetAttribute("macrotext", nil)
	end
	self.groups, self.skipped = groups, skipped
	-- the mouse was on one of our frames: read those keys again in a moment
	if self.busy and (self.retries or 0) < 3 then
		self.retries = (self.retries or 0) + 1
		C_Timer.After(1, function() V:Schedule() end)
	elseif not self.busy then
		self.retries = 0
	end
end

-- many events at once (spells, bindings): one rebuild a moment later
function V:Schedule()
	if self.pending then return end
	self.pending = true
	C_Timer.After(0.2, function()
		V.pending = false
		HoA:OutOfCombat("hoa-everywhere", function() V:Rebuild() end)
	end)
end

-- /hoa hover: which keys cast everywhere, and which are left alone
function V:Report()
	if not on() then return HoA:Print(L["Hover everywhere is off."]) end
	local keys = {}
	for _, g in ipairs(self.groups) do
		for _, k in ipairs(g.keys) do keys[#keys + 1] = k end
	end
	HoA:Print(L["Hover everywhere: %d keys."]:format(#keys) .. " " .. table.concat(keys, " "))
	for _, s in ipairs(self.skipped) do
		local why = s.why == "harm" and L["harmful spell"] or s.why == "long" and L["macro too long"]
			or s.why == "busy" and L["try again"] or s.why
		HoA:Print("  " .. s.key .. ": " .. L["left alone"] .. " (" .. why .. ")")
	end
end

function V:OnEnable()
	HoA:Listen("BINDINGS", function() V:Schedule() end)
	HoA:On("SPELLS_CHANGED", function() V:Schedule() end)
	HoA:On("PLAYER_REGEN_ENABLED", function() V:Schedule() end)
	-- our own changes fire UPDATE_BINDINGS too: those are skipped
	HoA:On("UPDATE_BINDINGS", function()
		if now() < (V.quietUntil or 0) then return end
		V:Schedule()
	end)
	HoA:On("CVAR_UPDATE", function(_, name)
		if type(name) == "string" and name:lower() == "actionbuttonusekeydown" then V:Schedule() end
	end)
	-- Casters of Azeroth sets its bars' and Naga keys after we load: read again
	HoA:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(2, function() V:Schedule() end) end)
	local c = HoA:Casters()
	if c and c.Listen then
		c:Listen("SETTINGS", function(group)
			if group == "naga" or group == "bars" then C_Timer.After(0.5, function() V:Schedule() end) end
		end)
	end
	-- Nagas of Azeroth owns the Naga bar now: follow its key changes too
	local n = _G.NagasOfAzeroth
	if n and n.Listen then
		n:Listen("NAGA_CHANGED", function()
			-- Nagas also fires this on the UPDATE_BINDINGS our own rebuild causes: skip those
			if now() < (V.quietUntil or 0) then return end
			C_Timer.After(0.5, function() V:Schedule() end)
		end)
	end
	self:Schedule()
end
