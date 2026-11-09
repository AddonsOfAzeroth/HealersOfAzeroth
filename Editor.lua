-- Healers of Azeroth by DinX: the click editor. A small window with all your
-- clicks as slots: drag a spell from your spellbook onto a slot and that click
-- casts it. It opens next to the spellbook (setting) or with /hoa clicks.
-- Right-click a slot: empty; Shift + right-click: target. Out of combat only.
-- Or record: press Record, then click a spell in the spellbook with the click
-- you want (Shift + right, ...) or press 1 to 5 on it. A plain cover over that
-- one spell catches the click, so the spell is not cast.
local _, ns = ...
local HoA = ns.HoA
local L = HoA.L
local S = HoA.Style

local E = HoA:NewModule("Editor")

local SLOT, GAP, PAD, HEAD = 64, 4, 10, 28
local LABEL_W = 70

local function spellFromCursor()
	if not GetCursorInfo then return end
	local kind, a, b, c = GetCursorInfo()
	if kind ~= "spell" then return end
	local id = c or (C_SpellBook and C_SpellBook.GetSpellBookItemInfo and (function()
		local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, a, b)
		return ok and type(info) == "table" and info.spellID or nil
	end)())
	if not id then return end
	local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or (GetSpellInfo and GetSpellInfo(id))
	return name
end

local function slot(parent, key)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(SLOT, SLOT - 16)
	S:Backdrop(b, 1)
	b.key = key
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(22, 22)
	b.icon:SetPoint("TOP", 0, -4)
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.text = S:Font(b, 9)
	b.text:SetPoint("BOTTOMLEFT", 2, 3)
	b.text:SetPoint("BOTTOMRIGHT", -2, 3)
	b.text:SetWordWrap(false)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local function drop(self)
		local name = spellFromCursor()
		if not name then return end
		ClearCursor()
		if InCombatLockdown() then return HoA:Print(L["Not in combat: try again after the fight."]) end
		HoA.Bindings:Set(self.key, name)
		E:Render()
	end
	b:SetScript("OnReceiveDrag", drop)
	b:SetScript("OnClick", function(self, button)
		if GetCursorInfo and GetCursorInfo() == "spell" then return drop(self) end
		if button == "RightButton" then
			if InCombatLockdown() then return end
			HoA.Bindings:Set(self.key, IsShiftKeyDown() and "target" or "none")
			E:Render()
		end
	end)
	b:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(S.colors.accent))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(HoA.Bindings:Label(self.key), 1, 1, 1)
		GameTooltip:AddLine(L["Drag a spell from your spellbook here."], 0.6, 0.65, 0.71, true)
		GameTooltip:AddLine(L["Right-click: empty. Shift + right-click: target."], 0.6, 0.65, 0.71, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) GameTooltip:Hide() end)
	return b
end

---------------------------------------------------------------------------
-- Record: a cover over the spellbook spell under the mouse
---------------------------------------------------------------------------
local BUTTON_NR = { LeftButton = 1, RightButton = 2, MiddleButton = 3 }

local function mods()
	if IsShiftKeyDown() then return "shift-", L["Shift"] end
	if IsControlKeyDown() then return "ctrl-", L["Ctrl"] end
	if IsAltKeyDown() then return "alt-", L["Alt"] end
	return "", nil
end

local function inSpellbook(frame)
	local book1, book2 = _G.SpellBookFrame, _G.PlayerSpellsFrame
	for _ = 1, 30 do
		if not frame then return false end
		if frame == book1 or frame == book2 then return true end
		frame = frame.GetParent and frame:GetParent()
	end
	return false
end

function E:Record(key, name, what)
	if InCombatLockdown() then return end
	HoA.Bindings:Set(key, name)
	self.status:SetText(what .. "  >  " .. name)
	self.status:SetTextColor(unpack(S.colors.good or S.colors.accent))
	self:Render()
end

function E:Cover()
	if self.cover then return self.cover end
	local c = CreateFrame("Button", nil, UIParent)
	c:SetFrameStrata("TOOLTIP")
	c:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
	c.edge = c:CreateTexture(nil, "OVERLAY")
	c.edge:SetAllPoints()
	c.edge:SetColorTexture(S.colors.hint[1], S.colors.hint[2], S.colors.hint[3], 0.18)
	c:Hide()
	c:SetScript("OnClick", function(self, button)
		local nr = BUTTON_NR[button]
		if not (nr and self.name) then return end
		local m, mlabel = mods()
		E:Record(m .. nr, self.name, (mlabel and (mlabel .. " + ") or "") .. L[HoA.Bindings.BUTTONS[nr][2]])
	end)
	c:SetScript("OnKeyDown", function(self, key)
		for i, k in ipairs(HoA.Bindings.HOVER_KEYS) do
			if key == k and self.name then
				self:SetPropagateKeyboardInput(false)
				E:Record("hover" .. i, self.name, L["Key"] .. " " .. k)
				if not HoA.char.hoverKeys then
					HoA.char.hoverKeys = true
					HoA:Fire("BINDINGS")
				end
				return
			end
		end
		self:SetPropagateKeyboardInput(true)
	end)
	c:SetScript("OnEnter", function(self)
		if not self.id then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		pcall(GameTooltip.SetSpellByID, GameTooltip, self.id)
		GameTooltip:AddLine(L["Click it with the click you want, or press 1 to 5."], S.colors.hint[1], S.colors.hint[2], S.colors.hint[3], true)
		GameTooltip:Show()
	end)
	c:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self:Hide()
	end)
	self.cover = c
	return c
end

-- the tooltip tells which spell the mouse is on: put the cover over it
local function onSpellTooltip(tt, id)
	if tt ~= GameTooltip or not E.recording or InCombatLockdown() then return end
	local owner = tt:GetOwner()
	if not owner or owner == E.cover or not inSpellbook(owner) then return end
	if HoA.IsSecret(id) or type(id) ~= "number" then return end
	local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or (GetSpellInfo and GetSpellInfo(id))
	if not name then return end
	local c = E:Cover()
	c.id, c.name = id, name
	c:ClearAllPoints()
	c:SetAllPoints(owner)
	c:EnableKeyboard(true)
	c:Show()
end

function E:HookTooltip()
	if self.tooltipHooked then return end
	self.tooltipHooked = true
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tt, data)
			onSpellTooltip(tt, data and data.id)
		end)
	elseif GameTooltip.GetSpell then
		GameTooltip:HookScript("OnTooltipSetSpell", function(tt)
			local _, id = tt:GetSpell()
			onSpellTooltip(tt, id)
		end)
	end
end

function E:SetRecording(on)
	if on and InCombatLockdown() then return end
	self.recording = on and true or false
	if on then self:HookTooltip() end
	if not on and self.cover then self.cover:Hide() end
	if not self.frame then return end
	self.recBtn.text:SetText(on and L["Stop"] or L["Record"])
	self.recBtn:SetBackdropColor(on and 0.45 or 0.12, on and 0.12 or 0.12, on and 0.12 or 0.14, 1)
	self.status:SetTextColor(unpack(S.colors.hint))
	self.status:SetText(on and L["Now click a spell in your spellbook with the click you want (Shift + right, ...), or point at it and press 1 to 5."] or "")
end

function E:Build()
	local B = HoA.Bindings
	local cols = #B.BUTTONS
	local w = PAD * 2 + LABEL_W + cols * (SLOT + GAP)
	local f = CreateFrame("Frame", "HealersOfAzerothEditor", UIParent, "BackdropTemplate")
	S:Backdrop(f, 0.97)
	f:SetFrameStrata("DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	f:Hide()
	tinsert(UISpecialFrames, "HealersOfAzerothEditor")
	local title = S:Font(f, 13)
	title:SetPoint("TOPLEFT", PAD, -8)
	title:SetText(L["Your clicks"])
	title:SetTextColor(unpack(S.colors.accent))
	local close = CreateFrame("Button", nil, f)
	close:SetSize(18, 18)
	close:SetPoint("TOPRIGHT", -4, -4)
	close.t = S:Font(close, 13)
	close.t:SetPoint("CENTER")
	close.t:SetText("x")
	close.t:SetTextColor(unpack(S.colors.muted))
	close:SetScript("OnClick", function() f:Hide() end)
	f:SetScript("OnHide", function() E:SetRecording(false) end)

	-- record button, next to the title
	local rec = CreateFrame("Button", nil, f, "BackdropTemplate")
	rec:SetSize(90, 20)
	rec:SetPoint("TOPRIGHT", -28, -5)
	S:Backdrop(rec, 1)
	rec.text = S:Font(rec, 11)
	rec.text:SetPoint("CENTER")
	rec.text:SetText(L["Record"])
	rec:SetScript("OnClick", function() E:SetRecording(not E.recording) end)
	rec:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(S.colors.accent))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["Record"], 1, 1, 1)
		GameTooltip:AddLine(L["Click a spell in your spellbook the way you want to cast it. It is not cast, only saved."], 0.6, 0.65, 0.71, true)
		GameTooltip:Show()
	end)
	rec:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) GameTooltip:Hide() end)
	self.recBtn = rec

	self.slots = {}
	local y = -HEAD
	-- column titles
	for i, bt in ipairs(B.BUTTONS) do
		local t = S:Font(f, 10)
		t:SetPoint("TOPLEFT", PAD + LABEL_W + (i - 1) * (SLOT + GAP), y)
		t:SetWidth(SLOT)
		t:SetText(L[bt[2]])
		t:SetTextColor(unpack(S.colors.muted))
	end
	y = y - 14
	for _, m in ipairs(B.MODS) do
		local lab = S:Font(f, 11)
		lab:SetPoint("TOPLEFT", PAD, y - 16)
		lab:SetText(m[2] ~= "" and L[m[2]] or L["Plain"])
		for i, bt in ipairs(B.BUTTONS) do
			local s = slot(f, m[1] .. bt[1])
			s:SetPoint("TOPLEFT", PAD + LABEL_W + (i - 1) * (SLOT + GAP), y)
			self.slots[#self.slots + 1] = s
		end
		y = y - (SLOT - 16 + GAP)
	end
	-- hover keys
	y = y - 6
	self.hoverCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	self.hoverCheck:SetSize(22, 22)
	self.hoverCheck:SetPoint("TOPLEFT", PAD - 4, y)
	self.hoverCheck:SetScript("OnClick", function(cb)
		HoA.char.hoverKeys = cb:GetChecked() and true or false
		HoA:Fire("BINDINGS")
		E:Render()
	end)
	local hl = S:Font(f, 11)
	hl:SetPoint("LEFT", self.hoverCheck, "RIGHT", 2, 0)
	hl:SetText(L["Mouse over a frame + key 1 to 5"])
	y = y - 26
	local hw = math.floor((w - PAD * 2 - (#B.HOVER_KEYS - 1) * GAP) / #B.HOVER_KEYS)
	for i, key in ipairs(B.HOVER_KEYS) do
		local s = slot(f, "hover" .. i)
		s:SetWidth(hw)
		s:SetPoint("TOPLEFT", PAD + (i - 1) * (hw + GAP), y)
		s.keyLabel = S:Font(s, 10)
		s.keyLabel:SetPoint("TOPLEFT", 3, -2)
		s.keyLabel:SetText(key)
		s.keyLabel:SetTextColor(unpack(S.colors.hint))
		self.slots[#self.slots + 1] = s
	end
	y = y - (SLOT - 16) - PAD
	local note = S:Font(f, 10)
	note:SetPoint("TOPLEFT", PAD, y)
	note:SetWidth(w - PAD * 2)
	note:SetJustifyH("LEFT")
	note:SetTextColor(unpack(S.colors.muted))
	note:SetText(L["Drag spells from your spellbook onto the slots: heals, buffs, dispels, anything that targets a friend."])
	y = y - 30
	self.status = S:Font(f, 11)
	self.status:SetPoint("TOPLEFT", PAD, y)
	self.status:SetWidth(w - PAD * 2)
	self.status:SetJustifyH("LEFT")
	f:SetSize(w, -y + 36)
	self.frame = f
end

function E:Render()
	if not (self.frame and self.frame:IsShown()) then return end
	for _, s in ipairs(self.slots) do
		local kind, spell = HoA.Bindings:Resolve(s.key)
		local tex = kind == "spell" and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spell)
		s.icon:SetTexture(tex or nil)
		s.icon:SetShown(tex and true or false)
		s.text:SetText(HoA.Bindings:Label(s.key))
		s.text:SetTextColor(unpack(kind and S.colors.text or S.colors.muted))
	end
	self.hoverCheck:SetChecked(HoA.char.hoverKeys and true or false)
end

-- open it, next to `anchor` (the spellbook) when given
function E:Show(anchor)
	if not self.frame then self:Build() end
	local f = self.frame
	f:ClearAllPoints()
	if anchor and anchor.GetRight and anchor:GetRight() then
		f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
	else
		f:SetPoint("CENTER")
	end
	f:Show()
	self:Render()
end

function E:Toggle()
	if self.frame and self.frame:IsShown() then return self.frame:Hide() end
	self:Show()
end

function E:OnEnable()
	-- next to the spellbook (Blizzard's frame names differ per client)
	local function hook(frame)
		if not frame or frame.hoaHooked then return end
		frame.hoaHooked = true
		frame:HookScript("OnShow", function(self)
			if HoA.char.editorWithSpellbook ~= false and HoA.char.enabled then E:Show(self) end
		end)
		frame:HookScript("OnHide", function() if E.frame then E.frame:Hide() end end)
	end
	hook(_G.SpellBookFrame)
	hook(_G.PlayerSpellsFrame)
	-- the spellbook can be loaded later (an addon of Blizzard's own)
	HoA:On("ADDON_LOADED", function() hook(_G.SpellBookFrame) hook(_G.PlayerSpellsFrame) end)
	HoA:Listen("BINDINGS", function() E:Render() end)
	HoA:On("PLAYER_REGEN_DISABLED", function() if E.recording then E:SetRecording(false) end end)
end
