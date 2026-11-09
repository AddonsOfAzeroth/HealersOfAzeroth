-- Healers of Azeroth by DinX: the group frames. Blizzard's secure group header
-- makes one clickable button per member (party or raid, also in combat); we
-- draw on them: health, incoming heals, missing health, a coloured border for
-- a debuff you can dispel, a red edge when a mob is on them, faded when out
-- of range. Health and auras can be hidden in combat: those values go straight
-- to the bars (allowed), they are never calculated with.
local _, ns = ...
local HoA = ns.HoA
local L = HoA.L
local S = HoA.Style
local Safe, IsSecret = HoA.Safe, HoA.IsSecret

local F = HoA:NewModule("Frames")

local DISPEL_COLORS = {
	Magic = { 0.2, 0.6, 1 }, Curse = { 0.6, 0, 1 }, Disease = { 0.6, 0.4, 0 }, Poison = { 0, 0.6, 0 },
}
local hider = CreateFrame("Frame")
hider:Hide()

local function cfg() return HoA.char end
-- the order button's short names
local SHORT = { role = "Role", group = "Groups", class = "Class", name = "Name" }
local function inRaid() return (IsInRaid and IsInRaid()) and true or false end

-- party and raid each have their own place and size; the simulation can ask for either
local function sizeFor(raid)
	local c = cfg()
	if raid then return c.raidWidth or 72, c.raidHeight or 30 end
	return c.width, c.height
end

---------------------------------------------------------------------------
-- Drawing on one member button
---------------------------------------------------------------------------
local function decorate(b)
	if b.hoa then return end
	b.hoa = true
	S:Backdrop(b, 0.9)
	local hp = CreateFrame("StatusBar", nil, b)
	hp:SetStatusBarTexture(S.flat)
	hp:SetPoint("TOPLEFT", 1, -1)
	hp:SetPoint("BOTTOMRIGHT", -1, 1)
	local bg = hp:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.1, 0.1, 0.12, 0.9)
	b.hp = hp
	-- incoming heals: a bar glued to the end of the health fill (works while hidden)
	local clip = CreateFrame("Frame", nil, hp)
	clip:SetAllPoints(hp)
	pcall(clip.SetClipsChildren, clip, true)
	local inc = CreateFrame("StatusBar", nil, clip)
	inc:SetStatusBarTexture(S.flat)
	inc:SetStatusBarColor(0.3, 1, 0.4, 0.45)
	inc:SetPoint("TOPLEFT", hp:GetStatusBarTexture(), "TOPRIGHT")
	inc:SetPoint("BOTTOMLEFT", hp:GetStatusBarTexture(), "BOTTOMRIGHT")
	b.inc = inc
	local top = CreateFrame("Frame", nil, b)
	top:SetAllPoints()
	top:SetFrameLevel(hp:GetFrameLevel() + 3)
	-- role: a small shield (tank) or cross (healer) before the name
	b.role = top:CreateTexture(nil, "OVERLAY")
	b.role:SetSize(11, 11)
	b.role:SetPoint("TOPLEFT", 3, -3)
	b.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
	b.role:Hide()
	-- raid mark (skull, star, ...) at the top middle, as Blizzard sets it
	b.mark = top:CreateTexture(nil, "OVERLAY")
	b.mark:SetSize(14, 14)
	b.mark:SetPoint("TOP", 0, 2)
	b.mark:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	b.mark:Hide()
	b.name = S:Font(top, 11)
	b.name:SetPoint("TOPLEFT", 4, -3)
	b.name:SetPoint("TOPRIGHT", -4, -3)
	b.name:SetJustifyH("LEFT")
	b.name:SetWordWrap(false)
	b.info = S:Font(top, 10)
	b.info:SetPoint("BOTTOMRIGHT", -4, 3)
	-- a mob is on them: a red line at the top
	b.aggro = top:CreateTexture(nil, "OVERLAY")
	b.aggro:SetColorTexture(1, 0.15, 0.15, 1)
	b.aggro:SetPoint("TOPLEFT", 1, -1)
	b.aggro:SetPoint("TOPRIGHT", -1, -1)
	b.aggro:SetHeight(2)
	b.aggro:Hide()
	-- who needs a heal most: a gold edge around the frame
	b.need = CreateFrame("Frame", nil, top, "BackdropTemplate")
	b.need:SetPoint("TOPLEFT", -2, 2)
	b.need:SetPoint("BOTTOMRIGHT", 2, -2)
	b.need:SetBackdrop({ edgeFile = S.flat, edgeSize = 2 })
	b.need:SetBackdropBorderColor(1, 0.82, 0.25, 1)
	b.need:Hide()
	-- your class buff missing: a small mark top right (Alt + middle click gives it)
	b.buff = top:CreateTexture(nil, "OVERLAY")
	b.buff:SetSize(10, 10)
	b.buff:SetPoint("TOPRIGHT", -3, -3)
	b.buff:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.buff:Hide()
	-- a debuff you can dispel: its icon at the right (Ctrl + left click by default)
	b.dispel = top:CreateTexture(nil, "OVERLAY")
	b.dispel:SetSize(14, 14)
	b.dispel:SetPoint("RIGHT", -3, 0)
	b.dispel:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.dispel:Hide()
	-- your own HoTs and shields: up to 3 small icons with their time
	b.hots = {}
	for i = 1, 3 do
		local ic = CreateFrame("Frame", nil, top)
		ic:SetSize(12, 12)
		ic:SetPoint("BOTTOMLEFT", 3 + (i - 1) * 13, 3)
		ic.tex = ic:CreateTexture(nil, "ARTWORK")
		ic.tex:SetAllPoints()
		ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		ic.cd = CreateFrame("Cooldown", nil, ic, "CooldownFrameTemplate")
		ic.cd:SetAllPoints()
		ic.cd:SetReverse(true)
		ic.cd:SetDrawEdge(false)
		ic.cd:SetHideCountdownNumbers(true)
		ic:Hide()
		b.hots[i] = ic
	end
	-- mana for healers (and you): a thin bar at the bottom
	b.mana = CreateFrame("StatusBar", nil, b)
	b.mana:SetStatusBarTexture(S.flat)
	b.mana:SetStatusBarColor(0.25, 0.5, 1)
	b.mana:SetPoint("BOTTOMLEFT", 1, 1)
	b.mana:SetPoint("BOTTOMRIGHT", -1, 1)
	b.mana:SetHeight(3)
	b.mana:SetFrameLevel(hp:GetFrameLevel() + 2)
	b.mana:Hide()
end

-- your own short buffs on someone (HoTs, shields), with their time
local function hots(b, unit)
	local n = 0
	if HoA.char.hots and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		for i = 1, 20 do
			if n >= #b.hots then break end
			local ok, d = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL|PLAYER")
			if not ok or d == nil then break end
			if type(d) == "table" and not IsSecret(d) then
				local dur = Safe(d.duration, nil)
				-- long buffs (Fortitude ...) are not HoTs; hidden durations are shown
				if not (type(dur) == "number" and (dur <= 0 or dur > 60)) then
					n = n + 1
					local ic = b.hots[n]
					pcall(ic.tex.SetTexture, ic.tex, d.icon)
					local exp = Safe(d.expirationTime, nil)
					if type(dur) == "number" and type(exp) == "number" then
						ic.cd:SetCooldown(exp - dur, dur)
					elseif ic.cd.SetCooldownFromDurationObject and C_UnitAuras.GetAuraDuration then
						pcall(function() ic.cd:SetCooldownFromDurationObject(C_UnitAuras.GetAuraDuration(unit, d.auraInstanceID)) end)
					end
					ic:Show()
				end
			end
		end
	end
	for i = n + 1, #b.hots do b.hots[i]:Hide() end
end

-- your class buff missing on someone (only out of combat: auras are readable then)
local function missingBuff(b, unit)
	local class = select(2, UnitClass("player"))
	local names = HoA.char.buffs and HoA.Bindings.CLASS_BUFF[class]
	if not names or InCombatLockdown() or Safe(UnitIsDeadOrGhost(unit), true) then return b.buff:Hide() end
	local spell
	for _, n in ipairs(names) do if HoA.Bindings:Known(n) then spell = n break end end
	if not spell or not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return b.buff:Hide() end
	for _, n in ipairs(names) do
		local ok, d = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, n, "HELPFUL")
		if not ok then return b.buff:Hide() end -- hidden: don't call it missing
		if d then return b.buff:Hide() end
	end
	local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell)
	b.buff:SetTexture(tex or 136079)
	b.buff:Show()
end

local function mana(b, unit)
	local role = UnitGroupRolesAssigned and Safe(UnitGroupRolesAssigned(unit), "NONE") or "NONE"
	local show = HoA.char.healerMana and (role == "HEALER" or unit == "player") and Safe(UnitPowerType(unit), 0) == 0
	b.mana:SetShown(show and true or false)
	if show then
		pcall(b.mana.SetMinMaxValues, b.mana, 0, UnitPowerMax(unit, 0))
		pcall(b.mana.SetValue, b.mana, UnitPower(unit, 0))
	end
end

local ROLE_COORDS = {
	TANK = { 0, 19 / 64, 22 / 64, 41 / 64 },
	HEALER = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 },
	DAMAGER = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
}
local ASSIGN_TEX = { MAINTANK = "Interface\\GroupFrame\\UI-Group-MainTankIcon", MAINASSIST = "Interface\\GroupFrame\\UI-Group-MainAssistIcon" }

-- Blizzard's raid mark 1..8 (skull = 8): one cell of a 4x4 sheet
local function showMark(b, index)
	if not cfg().raidMarks or type(index) ~= "number" or index < 1 or index > 8 then return b.mark:Hide() end
	local col, row = (index - 1) % 4, math.floor((index - 1) / 4)
	b.mark:SetTexCoord(col / 4, (col + 1) / 4, row / 4, (row + 1) / 4)
	b.mark:Show()
end

-- tanks and healers get an icon; damage dealers only when asked (less to look at).
-- A raid's main tank / main assist (set in Blizzard's menu) wins over the role.
local function showRole(b, role, assigned)
	local c = cfg()
	if assigned and c.roleIcons then
		b.role:SetTexture(ASSIGN_TEX[assigned])
		b.role:SetTexCoord(0, 1, 0, 1)
		b.role:Show()
		b.name:SetPoint("TOPLEFT", 16, -3)
		return
	end
	b.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
	local tc = c.roleIcons and ROLE_COORDS[role]
	if tc and role == "DAMAGER" and not c.roleDamage then tc = nil end
	if tc then
		b.role:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		b.role:Show()
		b.name:SetPoint("TOPLEFT", 16, -3)
	else
		b.role:Hide()
		b.name:SetPoint("TOPLEFT", 4, -3)
	end
end

local function dispellable(unit)
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
	local ok, d = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, "HARMFUL|RAID_PLAYER_DISPELLABLE")
	if not ok or d == nil then return end
	local open = type(d) == "table" and not IsSecret(d)
	local kind = open and Safe(d.dispelName, nil)
	return DISPEL_COLORS[kind] or { 0.85, 0.3, 1 }, open and d.icon or nil
end

function F:Update(b)
	local unit = b:GetAttribute("unit")
	if not unit or not UnitExists(unit) then return end
	decorate(b)
	local c = cfg()
	local max, cur = UnitHealthMax(unit), UnitHealth(unit)
	pcall(b.hp.SetMinMaxValues, b.hp, 0, max)
	pcall(b.hp.SetValue, b.hp, cur)
	local _, class = UnitClass(unit)
	local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[Safe(class, "")]
	local dead = Safe(UnitIsDeadOrGhost(unit), false)
	local offline = not Safe(UnitIsConnected(unit), true)
	if dead or offline then
		b.hp:SetStatusBarColor(0.3, 0.3, 0.3)
	elseif cc then
		b.hp:SetStatusBarColor(cc.r * 0.8, cc.g * 0.8, cc.b * 0.8)
	else
		b.hp:SetStatusBarColor(0.3, 0.8, 0.4)
	end
	pcall(b.name.SetText, b.name, UnitName(unit))
	local assigned
	if GetPartyAssignment then
		if Safe(GetPartyAssignment("MAINTANK", unit), false) then assigned = "MAINTANK"
		elseif Safe(GetPartyAssignment("MAINASSIST", unit), false) then assigned = "MAINASSIST" end
	end
	showRole(b, UnitGroupRolesAssigned and Safe(UnitGroupRolesAssigned(unit), "NONE") or "NONE", assigned)
	showMark(b, GetRaidTargetIndex and Safe(GetRaidTargetIndex(unit), nil))
	-- missing health when the client shows it, else nothing to calculate
	local text = ""
	if offline then text = L["Offline"]
	elseif dead then text = L["Dead"]
	elseif c.deficit and not IsSecret(cur) and not IsSecret(max) and type(cur) == "number" and type(max) == "number" and cur < max then
		local miss = max - cur
		text = miss >= 1000 and ("-%.1fk"):format(miss / 1000) or ("-" .. miss)
	end
	b.info:SetText(text)
	-- incoming heals
	if c.incoming and UnitGetIncomingHeals then
		b.inc:SetWidth(math.max(1, b.hp:GetWidth()))
		local ok = pcall(b.inc.SetMinMaxValues, b.inc, 0, max) and pcall(b.inc.SetValue, b.inc, UnitGetIncomingHeals(unit) or 0)
		b.inc:SetShown(ok and true or false)
	else
		b.inc:Hide()
	end
	-- a debuff you can dispel: the border takes its colour
	local dc, icon = dispellable(unit)
	if dc then b:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1) else b:SetBackdropBorderColor(0, 0, 0, 1) end
	if dc and (IsSecret(icon) or icon) then
		pcall(b.dispel.SetTexture, b.dispel, icon) -- also when the icon is hidden in combat
		b.dispel:Show()
	else
		b.dispel:Hide()
	end
	-- aggro
	local threat = UnitThreatSituation and Safe(UnitThreatSituation(unit), 0) or 0
	b.aggro:SetShown(type(threat) == "number" and threat >= 2)
	hots(b, unit)
	missingBuff(b, unit)
	mana(b, unit)
	F:Range(b, unit)
	F:QueueNeed()
end

-- the gold edge: who needs a heal most (lowest health share, below 90 %;
-- only when the game shows the numbers)
function F:Need()
	local best, bestPct
	for unit, b in pairs(self.byUnit or {}) do
		if b.need then b.need:Hide() end
		if HoA.char.nextHeal and UnitExists(unit) and not Safe(UnitIsDeadOrGhost(unit), true) then
			local cur, max = UnitHealth(unit), UnitHealthMax(unit)
			if not IsSecret(cur) and not IsSecret(max) and type(cur) == "number" and type(max) == "number" and max > 0 then
				local pct = cur / max
				if pct < 0.9 and (not bestPct or pct < bestPct) then best, bestPct = b, pct end
			end
		end
	end
	if best and best.need then best.need:Show() end
end

function F:QueueNeed()
	if self.needQueued then return end
	self.needQueued = true
	C_Timer.After(0.2, function() F.needQueued = false pcall(F.Need, F) end)
end

function F:Range(b, unit)
	if not UnitInRange then return end
	local inRange, checked = UnitInRange(unit)
	if IsSecret(inRange) then
		if b.SetAlphaFromBoolean then pcall(b.SetAlphaFromBoolean, b, inRange, 1, 0.45) end
		return
	end
	if checked == false or unit == "player" then b:SetAlpha(1) return end
	b:SetAlpha(inRange and 1 or 0.45)
end

---------------------------------------------------------------------------
-- The header and its anchor
---------------------------------------------------------------------------
local byUnit = {}
F.byUnit = byUnit

function F:Members()
	local out = {}
	local h = self.header
	if not h then return out end
	local i = 1
	while true do
		local b = h:GetAttribute("child" .. i) or h[i]
		if not b then break end
		out[#out + 1] = b
		i = i + 1
	end
	return out
end

-- every member: decorate, bindings (out of combat), map unit -> button
function F:Scan()
	wipe(byUnit)
	for _, b in ipairs(self:Members()) do
		decorate(b)
		if not b.hoaBound and not InCombatLockdown() then
			HoA.Bindings:Apply(b)
			b.hoaBound = true
		end
		F:WrapHover(b)
		local u = b:GetAttribute("unit")
		if u then byUnit[u] = b F:Update(b) end
	end
end

function F:Build()
	local c = cfg()
	local anchor = CreateFrame("Frame", "HealersOfAzerothAnchor", UIParent)
	anchor:SetSize(c.width, c.height)
	self.anchor = anchor
	local raidAnchor = CreateFrame("Frame", "HealersOfAzerothRaidAnchor", UIParent)
	raidAnchor:SetSize(sizeFor(true))
	self.raidAnchor = raidAnchor
	local h = CreateFrame("Frame", "HealersOfAzerothHeader", UIParent, "SecureGroupHeaderTemplate")
	self.header = h
	h:SetAttribute("template", "SecureUnitButtonTemplate,BackdropTemplate")
	h:SetAttribute("templateType", "Button")
	h:SetAttribute("point", "TOP")
	h:SetAttribute("yOffset", -3)
	h:SetAttribute("columnSpacing", 3)
	h:SetAttribute("columnAnchorPoint", "LEFT")
	h:SetAttribute("maxColumns", 8)
	h:SetAttribute("groupBy", "GROUP")
	h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	h:SetAttribute("sortMethod", "INDEX")
	self:Place()
	S:RegisterMover(anchor, "group", L["Party frames"], function(fr)
		fr:SetPoint("LEFT", UIParent, "LEFT", 220, 40)
	end, nil, S:Sizing(anchor, "group", { min = { 50, 20 }, max = { 240, 90 }, apply = function(w, h2)
		c.width, c.height = w or 90, h2 or 38
		anchor:SetSize(c.width, c.height)
		F:SizeChanged()
	end }))
	S:RegisterMover(raidAnchor, "raid", L["Raid frames"], function(fr)
		fr:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -260)
	end, nil, S:Sizing(raidAnchor, "raid", { min = { 40, 16 }, max = { 200, 80 }, apply = function(w, h2)
		c.raidWidth, c.raidHeight = w or 72, h2 or 30
		raidAnchor:SetSize(c.raidWidth, c.raidHeight)
		F:SizeChanged()
	end }))
end

function F:SizeChanged()
	if self.Preview and self.preview then self:Preview(self.preview) end
	HoA:OutOfCombat("hoa-size", function() F:Configure() end)
end

-- the header sits on the party or the raid anchor (out of combat)
function F:Place()
	local h = self.header
	if not h then return end
	if InCombatLockdown() then return HoA:OutOfCombat("hoa-place", function() F:Place() end) end
	local raid = inRaid()
	if self.placedRaid == raid and h:GetPoint() then return end
	self.placedRaid = raid
	h:ClearAllPoints()
	h:SetPoint("TOPLEFT", raid and self.raidAnchor or self.anchor, "TOPLEFT")
	self:Configure()
end

-- sizes, who shows, and the click snippet for new buttons (out of combat)
function F:Configure()
	local h = self.header
	if not h or InCombatLockdown() then return HoA:OutOfCombat("hoa-config", function() F:Configure() end) end
	local c = cfg()
	local w, hh = sizeFor(inRaid())
	h:SetAttribute("showPlayer", true)
	h:SetAttribute("showSolo", c.solo)
	h:SetAttribute("showParty", c.party)
	h:SetAttribute("showRaid", c.raid)
	h:SetAttribute("unitsPerColumn", c.perColumn)
	-- order: by role (tanks, healers, damage), by raid group, by class, or by name
	local sort = F:SortMode()
	local sb = F:SortButton()
	if sb then
		for i, v in ipairs(F.SORTS) do if v == sort then sb:SetAttribute("sortIndex", i) end end
		sb.text:SetText(L[SHORT[sort]])
		sb:SetShown(c.sortButton ~= false)
	end
	h:SetAttribute("sortMethod", sort == "name" and "NAME" or "INDEX")
	if sort == "role" then
		h:SetAttribute("groupBy", "ASSIGNEDROLE")
		h:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
	elseif sort == "class" then
		h:SetAttribute("groupBy", "CLASS")
		h:SetAttribute("groupingOrder", "WARRIOR,PALADIN,DEATHKNIGHT,DRUID,PRIEST,SHAMAN,MONK,EVOKER,DEMONHUNTER,ROGUE,HUNTER,MAGE,WARLOCK")
	elseif sort == "group" then
		h:SetAttribute("groupBy", "GROUP")
		h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	else
		h:SetAttribute("groupBy", nil)
		h:SetAttribute("groupingOrder", nil)
	end
	h:SetAttribute("initialConfigFunction", ([[
		self:SetWidth(%d)
		self:SetHeight(%d)
		self:RegisterForClicks("AnyUp")
		self:SetAttribute("hoaKeys", %q)
		%s
		%s
	]]):format(w, hh, table.concat(HoA.Bindings.HOVER_KEYS, ","),
		c.hoverKeys and 'self:SetAttribute("hoaHover", true)' or "", HoA.Bindings:Snippet()))
	for _, b in ipairs(self:Members()) do
		b:SetSize(w, hh)
		HoA.Bindings:Apply(b)
		b:SetAttribute("hoaHover", c.hoverKeys and true or nil)
		b:SetAttribute("hoaKeys", table.concat(HoA.Bindings.HOVER_KEYS, ","))
		b.hoaBound = true
		F:WrapHover(b)
	end
	-- when to show: always, only in a group, or in a group and solo in combat
	if RegisterStateDriver and UnregisterStateDriver then
		UnregisterStateDriver(h, "visibility")
		if not c.enabled then
			h:Hide()
		elseif c.showWhen == "group" then
			RegisterStateDriver(h, "visibility", "[group] show; hide")
		elseif c.showWhen == "smart" then
			RegisterStateDriver(h, "visibility", "[group] show; [combat] show; hide")
		else
			h:Show()
		end
	elseif c.enabled then h:Show() else h:Hide() end
	self:HideBlizzard()
	self:Scan()
end

F.SORTS = { "role", "group", "class", "name" }
function F:SortMode()
	local c = cfg()
	if c.sortBy then return c.sortBy end
	return c.tanksFirst == false and "group" or "role" -- older setting
end

-- next order (/hoa sort), out of combat
function F:NextSort()
	local cur, i = self:SortMode(), 1
	for k, v in ipairs(self.SORTS) do if v == cur then i = k end end
	cfg().sortBy = self.SORTS[i % #self.SORTS + 1]
	self:Configure()
	HoA:Print(L["Order"] .. ": " .. L[F.SORT_LABEL[cfg().sortBy]])
end

F.SORT_LABEL = { role = "By role: tanks, healers, damage", group = "By raid group", class = "By class", name = "By name" }

-- one click, also in combat: a secure button that changes the header's order
-- (Blizzard's own restricted code; the header redraws itself)
function F:SortButton()
	local h = self.header
	if self.sortBtn or not h or not SecureHandlerSetFrameRef then return self.sortBtn end
	local b = CreateFrame("Button", "HealersOfAzerothSortButton", h, "SecureHandlerClickTemplate,BackdropTemplate")
	b:SetSize(64, 14)
	b:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 0, 2)
	S:Backdrop(b, 0.8)
	b.text = S:Font(b, 9)
	b.text:SetPoint("CENTER")
	b.text:SetTextColor(unpack(S.colors.muted))
	b:RegisterForClicks("AnyUp")
	SecureHandlerSetFrameRef(b, "header", h)
	b:SetAttribute("_onclick", [[
		local i = (self:GetAttribute("sortIndex") or 1) % 4 + 1
		self:SetAttribute("sortIndex", i)
		local h = self:GetFrameRef("header")
		if i == 1 then
			h:SetAttribute("sortMethod", "INDEX")
			h:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
			h:SetAttribute("groupBy", "ASSIGNEDROLE")
		elseif i == 2 then
			h:SetAttribute("sortMethod", "INDEX")
			h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
			h:SetAttribute("groupBy", "GROUP")
		elseif i == 3 then
			h:SetAttribute("sortMethod", "INDEX")
			h:SetAttribute("groupingOrder", "WARRIOR,PALADIN,DEATHKNIGHT,DRUID,PRIEST,SHAMAN,MONK,EVOKER,DEMONHUNTER,ROGUE,HUNTER,MAGE,WARLOCK")
			h:SetAttribute("groupBy", "CLASS")
		else
			h:SetAttribute("groupBy", nil)
			h:SetAttribute("groupingOrder", nil)
			h:SetAttribute("sortMethod", "NAME")
		end
	]])
	b:HookScript("OnClick", function(self)
		local mode = F.SORTS[self:GetAttribute("sortIndex") or 1]
		cfg().sortBy = mode
		self.text:SetText(L[SHORT[mode]])
		if not InCombatLockdown() then F:Scan() end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Order"] .. ": " .. L[F.SORT_LABEL[F:SortMode()]], 1, 1, 1)
		GameTooltip:AddLine(L["Click: next order (also in combat)."], 0.6, 0.65, 0.71, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	self.sortBtn = b
	return b
end

-- hover keys: while the mouse is on a frame, 1..5 click it with "hoverN".
-- Blizzard's secure snippets set and clear those keys (allowed in combat).
local hoverHandler
function F:WrapHover(b)
	if b.hoaHover or InCombatLockdown() or not SecureHandlerWrapScript then return end
	hoverHandler = hoverHandler or CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
	b.hoaHover = true
	SecureHandlerWrapScript(b, "OnEnter", hoverHandler, [[
		if self:GetAttribute("hoaHover") then
			local keys = self:GetAttribute("hoaKeys")
			if keys then
				local i = 0
				for key in keys:gmatch("[^,]+") do
					i = i + 1
					self:SetBindingClick(true, key, self, "hover" .. i)
				end
			end
		end
	]])
	SecureHandlerWrapScript(b, "OnLeave", hoverHandler, [[ self:ClearBindings() ]])
end

-- Blizzard's party and raid frames out of sight (when asked)
function F:HideBlizzard()
	if not cfg().hideBlizzard or not cfg().enabled or self.blizzHidden or InCombatLockdown() then return end
	self.blizzHidden = true
	for _, n in ipairs({ "CompactRaidFrameManager", "CompactRaidFrameContainer", "PartyFrame" }) do
		local f = _G[n]
		if f then
			pcall(f.UnregisterAllEvents, f)
			f:Hide()
			f:SetParent(hider)
		end
	end
end

---------------------------------------------------------------------------
-- Simulation: made-up members to see, move and resize the party or raid
-- frames. Plain frames (no clicks), out of combat only.
---------------------------------------------------------------------------
local ICON = "Interface\\Icons\\"
local FAKE = {
	{ "Tank", "WARRIOR", 0.62, { aggro = true, role = "TANK" } },
	{ "You", nil, 1, { hot = "Spell_Holy_Renew", role = "DAMAGER" } },
	{ "Healer", "PRIEST", 0.85, { mana = 0.7, role = "HEALER" } },
	{ "Mage", "MAGE", 0.34, { need = true, dispel = "Spell_Holy_DispelMagic", hot = "Spell_Holy_PowerWordShield" } },
	{ "Rogue", "ROGUE", 0.9, { buff = true } },
}
local RAID_CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local function fakeMember(i, raid)
	if not raid and FAKE[i] then return FAKE[i] end
	if raid and i <= 5 then return FAKE[i] end
	local class = RAID_CLASSES[(i * 7) % #RAID_CLASSES + 1]
	local hp = ((i * 37) % 100) / 100
	return { L["Member"] .. " " .. i, class, math.max(0.08, hp), { dead = (i % 13 == 0) } }
end

F.preview = nil
local pool = {}
function F:Preview(mode)
	if InCombatLockdown() then mode = nil end
	self.preview = mode
	for _, b in ipairs(pool) do b:Hide() end
	if self.header then pcall(self.header.SetAlpha, self.header, mode and 0 or 1) end
	self:PreviewBar(mode)
	if not mode then return end
	local raid = mode == "raid"
	local w, h = sizeFor(raid)
	local anchor = raid and self.raidAnchor or self.anchor
	local n, per = raid and 40 or 5, cfg().perColumn or 5 -- Forever has 40-player raids
	local _, myClass = UnitClass("player")
	for i = 1, n do
		local b = pool[i]
		if not b then
			b = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
			b:SetFrameStrata("MEDIUM")
			decorate(b)
			pool[i] = b
		end
		b:SetSize(w, h)
		local col, row = math.floor((i - 1) / per), (i - 1) % per
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", anchor, "TOPLEFT", col * (w + 3), -row * (h + 3))
		local m = fakeMember(i, raid)
		local name, class, hp, o = m[1], m[2] or myClass, m[3], m[4]
		local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
		b.hp:SetMinMaxValues(0, 100)
		b.hp:SetValue(o.dead and 0 or hp * 100)
		if cc then b.hp:SetStatusBarColor(cc.r, cc.g, cc.b) end
		b.inc:SetMinMaxValues(0, 100)
		b.inc:SetValue(hp < 0.7 and not o.dead and 12 or 0)
		b.inc:SetWidth(w)
		b.name:SetText(name)
		showRole(b, o.role or (raid and (i == 7 or i == 8) and "HEALER") or "DAMAGER", raid and (i == 1 and "MAINTANK" or i == 6 and "MAINTANK" or i == 2 and "MAINASSIST") or nil)
		showMark(b, (i == 1 and 8) or (i == 6 and 1) or nil)
		b.info:SetText(o.dead and L["Dead"] or (cfg().deficit and hp < 1 and ("-" .. math.floor((1 - hp) * 4000))) or "")
		b.aggro:SetShown(o.aggro and true or false)
		b.need:SetShown(o.need and cfg().nextHeal and true or false)
		b.buff:SetTexture(ICON .. "Spell_Holy_WordFortitude")
		b.buff:SetShown(o.buff and cfg().buffs and true or false)
		b.dispel:SetTexture(o.dispel and (ICON .. o.dispel) or nil)
		b.dispel:SetShown(o.dispel and true or false)
		b:SetBackdropBorderColor(unpack(o.dispel and DISPEL_COLORS.Magic or { 0, 0, 0 }))
		for k, ic in ipairs(b.hots) do
			local show = k == 1 and o.hot and cfg().hots
			if show then ic.tex:SetTexture(ICON .. o.hot) end
			ic:SetShown(show and true or false)
		end
		b.mana:SetMinMaxValues(0, 1)
		b.mana:SetValue(o.mana or 0)
		b.mana:SetShown(o.mana and cfg().healerMana and true or false)
		b:SetAlpha(i % 11 == 0 and 0.45 or 1) -- one out of range
		b:Show()
	end
end

-- a small bar while simulating: party, raid, done
function F:PreviewBar(mode)
	local bar = self.pbar
	if not bar and not mode then return end
	if not bar then
		bar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		bar:SetSize(420, 52)
		bar:SetPoint("TOP", 0, -120)
		bar:SetFrameStrata("DIALOG")
		S:Backdrop(bar, 0.95)
		bar.text = S:Font(bar, 11)
		bar.text:SetPoint("TOPLEFT", 10, -8)
		bar.text:SetText(L["Simulation: drag the blue box to move, its corner to resize."])
		local function btn(label, x, fn)
			local b = CreateFrame("Button", nil, bar, "BackdropTemplate")
			b:SetSize(90, 20)
			b:SetPoint("BOTTOMLEFT", x, 6)
			S:Backdrop(b, 1)
			b.text = S:Font(b, 11)
			b.text:SetPoint("CENTER")
			b.text:SetText(label)
			b:SetScript("OnClick", fn)
			b:SetScript("OnEnter", function() b:SetBackdropBorderColor(unpack(S.colors.accent)) end)
			b:SetScript("OnLeave", function() b:SetBackdropBorderColor(0, 0, 0, 1) end)
			return b
		end
		bar.party = btn(L["Party"], 10, function() F:Simulate("party") end)
		bar.raid = btn(L["Raid"], 106, function() F:Simulate("raid") end)
		bar.done = btn(L["Done"], 320, function() F:Simulate(nil) end)
		self.pbar = bar
	end
	bar:SetShown(mode and true or false)
	if mode then
		bar.party.text:SetTextColor(unpack(mode == "party" and S.colors.accent or S.colors.text))
		bar.raid.text:SetTextColor(unpack(mode == "raid" and S.colors.accent or S.colors.text))
	end
end

-- start, switch or stop: unlocks the frames while it runs
function F:Simulate(mode)
	if InCombatLockdown() then return HoA:Print(L["Not in combat: try again after the fight."]) end
	self:Preview(mode)
	HoA:SetFramesLocked(not mode)
end

function F:OnEnable()
	self:Build()
	local ev = CreateFrame("Frame")
	for _, e in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_HEAL_PREDICTION", "UNIT_CONNECTION",
		"UNIT_THREAT_SITUATION_UPDATE", "UNIT_NAME_UPDATE", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER" }) do
		pcall(ev.RegisterEvent, ev, e)
	end
	ev:SetScript("OnEvent", function(_, _, unit)
		local b = unit and byUnit[unit]
		if b then pcall(F.Update, F, b) end
	end)
	HoA:On("GROUP_ROSTER_UPDATE", function() C_Timer.After(0.2, function() pcall(F.Place, F) pcall(F.Scan, F) end) end)
	HoA:On("PLAYER_ROLES_ASSIGNED", function() C_Timer.After(0.2, function() pcall(F.Scan, F) end) end)
	HoA:On("RAID_TARGET_UPDATE", function() pcall(F.Scan, F) end)
	-- the buff marks only show out of combat: refresh when it ends
	HoA:On("PLAYER_REGEN_ENABLED", function() C_Timer.After(0.5, function() pcall(F.Scan, F) end) end)
	HoA:On("PLAYER_REGEN_DISABLED", function()
		for _, b in pairs(byUnit) do if b.buff then b.buff:Hide() end end
		if F.preview then F:Preview(nil) HoA:SetFramesLocked(true) end
	end)
	HoA:Listen("SETTINGS", function() if F.preview then F:Preview(F.preview) end end)
	HoA:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, function() pcall(F.Scan, F) end) end)
	HoA:Listen("BINDINGS", function() HoA:OutOfCombat("hoa-config", function() F:Configure() end) end)
	HoA:Listen("SETTINGS", function(group) if group == "frames" then HoA:OutOfCombat("hoa-config", function() F:Configure() end) end end)
	-- range fades a few times a second
	C_Timer.NewTicker(0.3, function()
		for unit, b in pairs(byUnit) do pcall(F.Range, F, b, unit) end
	end)
end
