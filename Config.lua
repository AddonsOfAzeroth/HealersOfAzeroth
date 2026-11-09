-- Healers of Azeroth by DinX: settings. One page, built with the same calls
-- (Header, Note, Check, Choice, Button) inside the Casters of Azeroth window
-- when that is loaded, else in Blizzard's own settings (AddOns tab).
local _, ns = ...
local HoA = ns.HoA
local L = HoA.L
local S = HoA.Style

local C = HoA:NewModule("Config")

local function opt(key)
	return function() return HoA.char[key] end, function(v) HoA.char[key] = v HoA:Fire("SETTINGS", "frames") end
end

function C.Build(p)
	local B = HoA.Bindings
	p:Header("Healers of Azeroth")
	p:Note(L["Click a group member to heal them: every click is yours, on Blizzard's own secure buttons. Changes take effect out of combat."])
	p:Check(L["Group frames on"], nil, opt("enabled"))
	p:Check(L["Show your own frame when you are alone"], L["Handy to try your clicks."], opt("solo"))
	p:Check(L["In a party"], nil, opt("party"))
	p:Check(L["In a raid"], nil, opt("raid"))
	p:Check(L["Hide Blizzard's party and raid frames"], L["Takes effect after /reload when you turn it off."], opt("hideBlizzard"))
	p:Check(L["Incoming heals on the bars"], nil, opt("incoming"))
	p:Check(L["Missing health (-1234)"], L["Only when the game shows the numbers (often hidden in combat)."], opt("deficit"))
	p:Choice(L["Members per column"], { { 5, "5" }, { 8, "8" }, { 10, "10" }, { 20, "20" }, { 40, "40" } }, opt("perColumn"))
	p:Gap()
	p:Header(L["Your clicks"])
	local opts = { { "target", L["Target"] }, { "menu", L["Menu"] }, { "none", L["Nothing"] } }
	for _, name in ipairs(B:Candidates()) do opts[#opts + 1] = { name, name } end
	for _, m in ipairs(B.MODS) do
		for _, b in ipairs(B.BUTTONS) do
			local key = m[1] .. b[1]
			local label = (m[2] ~= "" and (L[m[2]] .. " + ") or "") .. L[b[2]]
			p:Choice(label, opts, function()
				local kind, spell = B:Resolve(key)
				if kind == "spell" then return spell end
				if kind == "togglemenu" then return "menu" end
				return kind or "none"
			end, function(v) B:Set(key, v) end)
		end
	end
	p:Gap()
	p:Button(L["Back to the class defaults"], function() B:Reset() end, 200)
end

---------------------------------------------------------------------------
-- Standalone: a small page with the same calls, in Blizzard's settings
---------------------------------------------------------------------------
local Page = {}
Page.__index = Page

function Page:Header(text)
	local t = S:Font(self.frame, 14)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetText(text)
	t:SetTextColor(unpack(S.colors.accent))
	self.y = self.y - 26
end

function Page:Note(text)
	local t = S:Font(self.frame, 11)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetWidth(520)
	t:SetJustifyH("LEFT")
	t:SetTextColor(unpack(S.colors.muted))
	t:SetText(text)
	self.y = self.y - math.max(18, t:GetStringHeight() + 8)
end

function Page:Gap(h) self.y = self.y - (h or 8) end

function Page:Check(label, tip, get, set)
	local b = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
	b:SetPoint("TOPLEFT", 12, self.y)
	b:SetChecked(get() and true or false)
	b:SetScript("OnClick", function(btn) set(btn:GetChecked() and true or false) end)
	local t = S:Font(self.frame, 12)
	t:SetPoint("LEFT", b, "RIGHT", 4, 0)
	t:SetText(label)
	if tip then
		b:SetScript("OnEnter", function(btn)
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	self.y = self.y - 28
end

-- a button that steps through the options
function Page:Choice(label, opts, get, set)
	local t = S:Font(self.frame, 12)
	t:SetPoint("TOPLEFT", 16, self.y - 4)
	t:SetText(label)
	local b
	local function paint()
		local cur = get()
		for _, o in ipairs(opts) do if o[1] == cur then b.text:SetText(o[2] .. "  >") end end
	end
	b = self:Button("", function()
		local cur, i = get(), 1
		for k, o in ipairs(opts) do if o[1] == cur then i = k end end
		set(opts[i % #opts + 1][1])
		paint()
	end, 160, 180)
	paint()
end

function Page:Button(label, onClick, width, x)
	local b = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
	b:SetSize(width or 160, 22)
	b:SetPoint("TOPLEFT", x or 16, self.y)
	S:Backdrop(b, 1)
	b.text = S:Font(b, 12)
	b.text:SetPoint("CENTER")
	b.text:SetText(label)
	b:SetScript("OnEnter", function() b:SetBackdropBorderColor(unpack(S.colors.accent)) end)
	b:SetScript("OnLeave", function() b:SetBackdropBorderColor(0, 0, 0, 1) end)
	b:SetScript("OnClick", onClick)
	self.y = self.y - 30
	return b
end

local category
local function standalone()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")
	panel:Hide()
	local page = setmetatable({ frame = panel, y = -16 }, Page)
	C.Build(page)
	category = Settings.RegisterCanvasLayoutCategory(panel, "Healers of Azeroth")
	Settings.RegisterAddOnCategory(category)
end

function HoA:ToggleConfig()
	local c = HoA:Casters()
	if c and c.ToggleConfig and type(c.Config) == "table" and c.Config.Show then
		pcall(c.ToggleConfig, c, true)
		if c.Config.pages and c.Config.pages.hoa then pcall(c.Config.Show, c.Config, "hoa") end
		return
	end
	if category and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID()) end
end

-- built at login (your spells are known by then)
function C:OnEnable()
	local c = HoA:Casters()
	if c then
		c.configPages = type(c.configPages) == "table" and c.configPages or {}
		for _, d in ipairs(c.configPages) do if d.key == "hoa" then return end end
		table.insert(c.configPages, { key = "hoa", label = L["Group frames"], group = "Healers of Azeroth", build = C.Build })
	else
		standalone()
	end
end
