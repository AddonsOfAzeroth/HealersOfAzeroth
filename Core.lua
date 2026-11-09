-- Healers of Azeroth by DinX: group frames you heal by clicking (like HealBot
-- and Clique). Every heal is your click on a secure Blizzard button: the add-on
-- only decides which spell a click (with Shift, Ctrl, Alt) casts on whom.
local ADDON, ns = ...

local HoA = CreateFrame("Frame", "HealersOfAzerothCore")
ns.HoA = HoA
_G.HealersOfAzeroth = HoA

HoA.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or "?"
HoA.modules = {}

local accountDefaults = {
	language = "auto",
	font = "roboto",
	fontOutline = false,
}
local charDefaults = {
	enabled = true,
	solo = true,          -- show your own frame when you are alone (to set things up)
	party = true,
	raid = true,
	hideBlizzard = true,  -- Blizzard's party and raid frames out of sight
	width = 90,           -- one member
	height = 38,
	raidWidth = 72,       -- one member in a raid (its own place and size)
	raidHeight = 30,
	perColumn = 5,
	incoming = true,      -- incoming heals on the bars
	deficit = true,       -- "-1234" missing health (when the client shows it)
	hots = true,          -- your own HoTs and shields as small icons with their time
	nextHeal = true,      -- a gold edge on who needs a heal most
	buffs = true,         -- a small mark when someone misses your class buff
	healerMana = true,    -- a thin mana bar for healers (and you)
	roleIcons = true,     -- a shield (tank) or cross (healer) before the name
	roleDamage = false,   -- also a sword for damage dealers
	raidMarks = true,     -- Blizzard's raid marks (skull, star, ...) on the frames
	sortBy = nil,         -- "role", "group" (raid groups), "class", "name"; nil: from tanksFirst
	tanksFirst = true,
	sortButton = true,    -- the small order button above the frames (one click, also in combat)    -- tanks on top, then healers, then the rest
	showWhen = "smart",   -- "always", "group" (only in a group), "smart" (group, or solo in combat)
	hoverKeys = false,    -- mouse over a frame + 1..5 casts (Clique style)
	editorWithSpellbook = true, -- the click editor opens next to your spellbook
	bindings = nil,       -- set from the class defaults on first use (Bindings.lua)
	bars = { locked = true },
	points = {},
}

HoA.SCHEMA = 1

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			merge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

function HoA:Print(...)
	print("|cff69ccf0Healers of Azeroth|r:", ...)
end

local handlers = {}
function HoA:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		local ok = pcall(self.RegisterEvent, self, event)
		if not ok then handlers[event] = nil return end
	end
	table.insert(handlers[event], fn)
end

HoA:SetScript("OnEvent", function(self, event, ...)
	local list = handlers[event]
	if list then
		for i = 1, #list do list[i](event, ...) end
	end
end)

function HoA:NewModule(name)
	local m = { name = name }
	self.modules[#self.modules + 1] = m
	self[name] = m
	return m
end

local callbacks = {}
function HoA:Listen(msg, fn)
	callbacks[msg] = callbacks[msg] or {}
	table.insert(callbacks[msg], fn)
end
function HoA:Fire(msg, ...)
	for _, fn in ipairs(callbacks[msg] or {}) do fn(...) end
end

local issecret = issecretvalue or function() return false end
HoA.IsSecret = issecret
function HoA.Safe(v, default)
	if issecret(v) then return default end
	if v == nil then return default end
	return v
end

-- Run fn now, or as soon as combat ends (secure frames can't change in combat).
local afterCombat = {}
function HoA:OutOfCombat(key, fn)
	if not InCombatLockdown() then fn() else afterCombat[key] = fn end
end
HoA:On("PLAYER_REGEN_ENABLED", function()
	for k, fn in pairs(afterCombat) do
		afterCombat[k] = nil
		fn()
	end
end)

function HoA:Casters()
	local c = _G.CastersOfAzeroth or _G.CasterKit
	if type(c) == "table" and type(c.char) == "table" then return c end
end

function HoA:FramesLocked()
	local c = self:Casters()
	if c and type(c.char.bars) == "table" then return c.char.bars.locked ~= false end
	return self.char.bars.locked
end

function HoA:SetFramesLocked(locked)
	self.char.bars.locked = locked
	local c = self:Casters()
	if c and type(c.char.bars) == "table" then
		c.char.bars.locked = locked
		if c.Fire then c:Fire("SETTINGS", "bars") end
	end
	self:Fire("SETTINGS", "bars")
end

HoA:On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	HealersOfAzerothDB = type(HealersOfAzerothDB) == "table" and HealersOfAzerothDB or {}
	HealersOfAzerothCharDB = type(HealersOfAzerothCharDB) == "table" and HealersOfAzerothCharDB or {}
	merge(HealersOfAzerothDB, accountDefaults)
	merge(HealersOfAzerothCharDB, charDefaults)
	HoA.db = HealersOfAzerothDB
	HoA.char = HealersOfAzerothCharDB
	HoA.db.schemaVersion = HoA.SCHEMA
	local c = HoA:Casters()
	HoA.Style:LoadFont(c and c.db or HoA.db)
	for _, m in ipairs(HoA.modules) do
		if m.OnInit then pcall(m.OnInit, m) end
	end
end)

HoA:On("PLAYER_LOGIN", function()
	for _, m in ipairs(HoA.modules) do
		if m.OnEnable then
			local ok, err = pcall(m.OnEnable, m)
			if not ok then HoA:Print("|cffff5555" .. m.name .. ":|r " .. tostring(err)) end
		end
	end
	local c = HoA:Casters()
	if c and c.Listen then
		c:Listen("SETTINGS", function(group)
			if group == "bars" and HoA.Style then HoA.Style:UpdateMovers() end
		end)
	end
	if HoA.Style then HoA.Style:UpdateMovers() end
end)

SLASH_HEALERSOFAZEROTH1 = "/hoa"
SLASH_HEALERSOFAZEROTH2 = "/healersofazeroth"
SlashCmdList.HEALERSOFAZEROTH = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	local L = HoA.L
	if msg == "" or msg == "config" or msg == "settings" then
		HoA:ToggleConfig()
	elseif msg == "unlock" or msg == "lock" then
		HoA:SetFramesLocked(msg == "lock")
		HoA:Print(msg == "lock" and L["Frames locked."] or L["Frames unlocked: drag the frames where you like, drag the corner to make them bigger, type /hoa lock when done."])
	elseif msg == "sort" then
		if InCombatLockdown() then return HoA:Print(L["Not in combat: try again after the fight."]) end
		HoA.Frames:NextSort()
	elseif msg == "test" or msg == "sim" then
		local F = HoA.Frames
		F:Simulate(F.preview == nil and "party" or F.preview == "party" and "raid" or nil)
	elseif msg == "clicks" or msg == "editor" then
		HoA.Editor:Toggle()
	elseif msg == "toggle" then
		HoA.char.enabled = not HoA.char.enabled
		HoA:Fire("SETTINGS", "frames")
	else
		HoA:Print(L["/hoa: settings. /hoa clicks: edit your clicks. /hoa test: simulate party, raid, off. /hoa sort: next order. /hoa toggle: frames on/off. /hoa unlock: move and resize."])
	end
end

do
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_ACTION_BLOCKED")
	f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	f:SetScript("OnEvent", function(_, event, addon, func)
		if addon ~= ADDON then return end
		C_Timer.After(3, function() HoA:Print("|cffff5555blocked:|r " .. tostring(func)) end)
	end)
end
