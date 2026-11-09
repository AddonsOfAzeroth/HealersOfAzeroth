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
	local h = CreateFrame("Frame", "HealersOfAzerothHeader", UIParent, "SecureGroupHeaderTemplate")
	h:SetPoint("TOPLEFT", anchor, "TOPLEFT")
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
	self.header = h
	self:Configure()
	S:RegisterMover(anchor, "group", L["Group frames"], function(fr)
		fr:SetPoint("LEFT", UIParent, "LEFT", 220, 40)
	end, nil, S:Sizing(anchor, "group", { min = { 50, 20 }, max = { 240, 90 }, apply = function(w, h2)
		c.width, c.height = w or 90, h2 or 38
		anchor:SetSize(c.width, c.height)
		HoA:OutOfCombat("hoa-size", function() F:Configure() end)
	end }))
end

-- sizes, who shows, and the click snippet for new buttons (out of combat)
function F:Configure()
	local h = self.header
	if not h or InCombatLockdown() then return HoA:OutOfCombat("hoa-config", function() F:Configure() end) end
	local c = cfg()
	h:SetAttribute("showPlayer", true)
	h:SetAttribute("showSolo", c.solo)
	h:SetAttribute("showParty", c.party)
	h:SetAttribute("showRaid", c.raid)
	h:SetAttribute("unitsPerColumn", c.perColumn)
	-- tanks on top, then healers, then the rest (or by raid group)
	if c.tanksFirst then
		h:SetAttribute("groupBy", "ASSIGNEDROLE")
		h:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
	else
		h:SetAttribute("groupBy", "GROUP")
		h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	end
	h:SetAttribute("initialConfigFunction", ([[
		self:SetWidth(%d)
		self:SetHeight(%d)
		self:RegisterForClicks("AnyUp")
		self:SetAttribute("hoaKeys", %q)
		%s
		%s
	]]):format(c.width, c.height, table.concat(HoA.Bindings.HOVER_KEYS, ","),
		c.hoverKeys and 'self:SetAttribute("hoaHover", true)' or "", HoA.Bindings:Snippet()))
	for _, b in ipairs(self:Members()) do
		b:SetSize(c.width, c.height)
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
	HoA:On("GROUP_ROSTER_UPDATE", function() C_Timer.After(0.2, function() pcall(F.Scan, F) end) end)
	HoA:On("PLAYER_ROLES_ASSIGNED", function() C_Timer.After(0.2, function() pcall(F.Scan, F) end) end)
	-- the buff marks only show out of combat: refresh when it ends
	HoA:On("PLAYER_REGEN_ENABLED", function() C_Timer.After(0.5, function() pcall(F.Scan, F) end) end)
	HoA:On("PLAYER_REGEN_DISABLED", function() for _, b in pairs(byUnit) do if b.buff then b.buff:Hide() end end end)
	HoA:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, function() pcall(F.Scan, F) end) end)
	HoA:Listen("BINDINGS", function() HoA:OutOfCombat("hoa-config", function() F:Configure() end) end)
	HoA:Listen("SETTINGS", function(group) if group == "frames" then HoA:OutOfCombat("hoa-config", function() F:Configure() end) end end)
	-- range fades a few times a second
	C_Timer.NewTicker(0.3, function()
		for unit, b in pairs(byUnit) do pcall(F.Range, F, b, unit) end
	end)
end
