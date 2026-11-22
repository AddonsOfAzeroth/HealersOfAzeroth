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
			HoA.Bindings:Set(self.key, IsShiftKeyDown() and "target" or IsControlKeyDown() and "menu" or "none")
			E:Render()
		end
	end)
	b:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(S.colors.accent))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(HoA.Bindings:Label(self.key), 1, 1, 1)
		GameTooltip:AddLine(L["Drag a spell from your spellbook here."], 0.6, 0.65, 0.71, true)
		GameTooltip:AddLine(L["Right-click: empty. Shift + right-click: target. Ctrl + right-click: Blizzard's menu."], 0.6, 0.65, 0.71, true)
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
	c:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
	c.edge = c:CreateTexture(nil, "OVERLAY")
	c.edge:SetAllPoints()
	c.edge:SetColorTexture(S.colors.hint[1], S.colors.hint[2], S.colors.hint[3], 0.18)
	c:Hide()
	c:SetScript("OnClick", function(self, button)
		-- mouse 4 and 5: the hover keys of the 2-button plate
		local side = button and button:match("^Button([45])$")
		if side then return E.OnCoverKey(self, "BUTTON" .. side) end
		local nr = BUTTON_NR[button]
		if not (nr and self.name) then return end
		local m, mlabel = mods()
		E:Record(m .. nr, self.name, (mlabel and (mlabel .. " + ") or "") .. L[HoA.Bindings.BUTTONS[nr][2]])
	end)
	-- a hover key on the spell under the mouse: record it
	function E.OnCoverKey(self, key)
		local B = HoA.Bindings
		local info = B:PlateInfo()
		for i, k in ipairs(info.keys) do
			if key == k and self.name then
				self:SetPropagateKeyboardInput(false)
				-- with Shift, Ctrl or Alt held: that layer (when the plate has layers)
				local m, mlabel = "", nil
				if #B:HoverMods() > 1 then m, mlabel = mods() end
				if m == "shift-" and not B:ShiftOn() then m, mlabel = "", nil end
				E:Record(B:HoverName(m, info.ids[i]), self.name, L["Key"] .. " " .. B:KeyLabel(k, mlabel))
				if not HoA.char.hoverKeys then
					HoA.char.hoverKeys = true
					HoA:Fire("BINDINGS")
				end
				return
			end
		end
		self:SetPropagateKeyboardInput(true)
	end
	c:SetScript("OnKeyDown", E.OnCoverKey)
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
	-- above settings windows (also Casters', which is a DIALOG too)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
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
	self.hoverLabel = S:Font(f, 11)
	self.hoverLabel:SetPoint("LEFT", self.hoverCheck, "RIGHT", 2, 0)
	self.hoverLabel:SetText(L["Mouse over a frame + key 1 to 5"])
	y = y - 26
	-- the modifier layers of a Naga plate: Plain, Shift, Ctrl, Alt (one shows)
	self.layer = ""
	self.layerBtns = {}
	local lw = math.floor((w - PAD * 2 - 3 * GAP) / 4)
	for i, m in ipairs(B.MODS) do
		local lb = CreateFrame("Button", nil, f, "BackdropTemplate")
		lb:SetSize(lw, 18)
		lb:SetPoint("TOPLEFT", PAD + (i - 1) * (lw + GAP), y)
		S:Backdrop(lb, 1)
		lb.text = S:Font(lb, 10)
		lb.text:SetPoint("CENTER")
		lb.text:SetText(m[2] ~= "" and L[m[2]] or L["Plain"])
		lb.mod = m[1]
		lb:SetScript("OnClick", function(self) E.layer = self.mod E:LayoutHover() E:Render() end)
		self.layerBtns[i] = lb
	end
	self.hoverTop = y
	self.hoverPool = {}
	self.clickSlots = #self.slots
	self.note = S:Font(f, 10)
	self.note:SetWidth(w - PAD * 2)
	self.note:SetJustifyH("LEFT")
	self.note:SetTextColor(unpack(S.colors.muted))
	self.note:SetText(L["Drag spells from your spellbook onto the slots: heals, buffs, dispels, anything that targets a friend."])
	self.status = S:Font(f, 11)
	self.status:SetWidth(w - PAD * 2)
	self.status:SetJustifyH("LEFT")
	self.width = w
	self.frame = f
	self:LayoutHover()
end

-- the hover keys in the plate's own shape: 1 to 5 in a row, the 12 plate
-- 3 wide and 4 high, the 6 plate 2 x 3, the 2 plate one above the other
function E:LayoutHover()
	local B, f, w = HoA.Bindings, self.frame, self.width
	local plate = B:PlateInfo()
	local layered = #B:HoverMods() > 1
	if not layered or (self.layer == "shift-" and not B:ShiftOn()) then self.layer = "" end
	self.layoutFor = self:LayoutSig()
	self.hoverLabel:SetText(B:Plate() == "none" and L["Mouse over a frame + key 1 to 5"] or L["Mouse over a frame + a plate key"])
	local y = self.hoverTop
	for _, lb in ipairs(self.layerBtns) do
		-- no Shift tab while numpad keys keep the Shift layer off
		lb:SetShown(layered and (lb.mod ~= "shift-" or B:ShiftOn()))
		lb:SetBackdropBorderColor(unpack(lb.mod == self.layer and S.colors.accent or { 0, 0, 0, 1 }))
	end
	if layered then y = y - 18 - GAP end
	for i = #self.slots, self.clickSlots + 1, -1 do self.slots[i] = nil end
	for _, s in ipairs(self.hoverPool) do s:Hide() end
	local cols = plate.cols
	local hw = math.floor((w - PAD * 2 - (cols - 1) * GAP) / cols)
	local modLabel = ""
	for _, m in ipairs(B.MODS) do if m[1] == self.layer then modLabel = m[2] end end
	local rows = 0
	for i, key in ipairs(plate.keys) do
		local s = self.hoverPool[i]
		if not s then
			s = slot(f, "")
			s.keyLabel = S:Font(s, 10)
			s.keyLabel:SetPoint("TOPLEFT", 3, -2)
			s.keyLabel:SetTextColor(unpack(S.colors.hint))
			self.hoverPool[i] = s
		end
		local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
		rows = row + 1
		s.key = B:HoverName(self.layer, plate.ids[i])
		s:SetWidth(hw)
		s:ClearAllPoints()
		s:SetPoint("TOPLEFT", PAD + col * (hw + GAP), y - row * (SLOT - 16 + GAP))
		s.keyLabel:SetText(B:KeyLabel(key, modLabel))
		s:Show()
		self.slots[#self.slots + 1] = s
	end
	y = y - rows * (SLOT - 16 + GAP) - PAD + GAP
	self.note:ClearAllPoints()
	self.note:SetPoint("TOPLEFT", PAD, y)
	y = y - 30
	self.status:ClearAllPoints()
	self.status:SetPoint("TOPLEFT", PAD, y)
	f:SetSize(w, -y + 36)
end

-- what the hover part is laid out for: plate, keys and layers
function E:LayoutSig()
	local B = HoA.Bindings
	local info = B:PlateInfo()
	return B:Plate() .. "|" .. table.concat((function()
		local t = {}
		for i, k in ipairs(info.keys) do t[i] = k or "" end
		return t
	end)(), ",") .. "|" .. #B:HoverMods()
end

function E:Render()
	if not (self.frame and self.frame:IsShown()) then return end
	if self.layoutFor ~= self:LayoutSig() then self:LayoutHover() end
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

-- the window a button sits in (walk up to the frame on UIParent)
local function windowOf(frame)
	for _ = 1, 20 do
		local p = frame and frame.GetParent and frame:GetParent()
		if not p or p == UIParent then return frame end
		frame = p
	end
	return frame
end

-- open it next to `anchor` (the spellbook, or the settings window a button is
-- in): on the right when it fits, else on the left; never on top of it
function E:Show(anchor)
	if not self.frame then self:Build() end
	local f = self.frame
	f:ClearAllPoints()
	anchor = anchor and windowOf(anchor)
	if anchor and anchor ~= UIParent and anchor.GetRight and anchor:GetRight() then
		local room = (UIParent:GetRight() or 0) - anchor:GetRight()
		if room >= f:GetWidth() + 6 then
			f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
		else
			f:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -6, 0)
		end
	else
		f:SetPoint("CENTER")
	end
	f:Show()
	f:Raise()
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
