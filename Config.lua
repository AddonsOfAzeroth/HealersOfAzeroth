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

-- three short pages: the frames, what shows on them, your clicks
C.PAGES = {
	{ key = "hoa", label = "Group frames" },
	{ key = "hoaShow", label = "On the frames" },
	{ key = "hoaClicks", label = "Your clicks" },
}

function C.BuildFrames(p)
	p:Header("Healers of Azeroth")
	p:Note(L["Click a group member to heal them: every click is yours, on Blizzard's own secure buttons. Changes take effect out of combat."])
	p:Check(L["Group frames on"], nil, opt("enabled"))
	p:Choice(L["Show the frames"], { { "smart", L["In a group, or alone in combat"] }, { "group", L["Only in a group"] }, { "always", L["Always"] } }, opt("showWhen"))
	p:Check(L["Show your own frame when you are alone"], L["Handy to try your clicks."], opt("solo"))
	p:Check(L["In a party"], nil, opt("party"))
	p:Check(L["In a raid"], nil, opt("raid"))
	p:Check(L["Hide Blizzard's party and raid frames"], L["Takes effect after /reload when you turn it off."], opt("hideBlizzard"))
	p:Choice(L["Members per column"], { { 5, "5" }, { 8, "8" }, { 10, "10" }, { 20, "20" }, { 40, "40" } }, opt("perColumn"))
	p:Choice(L["Order"], { { "role", L["By role: tanks, healers, damage"] }, { "group", L["By raid group"] }, { "class", L["By class"] }, { "name", L["By name"] } },
		function() return HoA.Frames:SortMode() end, function(v) HoA.char.sortBy = v HoA:Fire("SETTINGS", "frames") end)
	p:Check(L["Order button above the frames"], L["Click: next order (also in combat)."], opt("sortButton"))
	p:Gap()
	p:Note(L["See, move and resize the frames with made-up members:"])
	p:Button(L["Simulate party"], function() HoA.Frames:Simulate("party") end, 160)
	p:Button(L["Simulate raid"], function() HoA.Frames:Simulate("raid") end, 160)
end

function C.BuildShow(p)
	p:Header(L["On the frames"])
	p:Check(L["Incoming heals on the bars"], nil, opt("incoming"))
	p:Check(L["Missing health (-1234)"], L["Only when the game shows the numbers (often hidden in combat)."], opt("deficit"))
	p:Check(L["Role icon: tank and healer"], nil, opt("roleIcons"))
	p:Check(L["Also for damage dealers"], nil, opt("roleDamage"))
	p:Check(L["Raid marks (skull, star, ...)"], nil, opt("raidMarks"))
	p:Note(L["Main tank, main assist and marks: set them in Blizzard's menu on a frame (a click set to Menu, e.g. Ctrl + right-click in the click editor). They show here and on everyone's Blizzard frames."])
	p:Check(L["Your HoTs and shields with their time"], nil, opt("hots"))
	p:Check(L["Gold edge on who needs a heal most"], nil, opt("nextHeal"))
	p:Check(L["Mark when your class buff is missing"], L["Alt + middle click gives it."], opt("buffs"))
	p:Check(L["Mana bar for healers"], nil, opt("healerMana"))
	p:Note(L["A dispel icon shows on the right of a frame when you can remove something."])
end

function C.BuildClicks(p)
	local B = HoA.Bindings
	p:Header(L["Your clicks"])
	p:Note(L["Drag spells from your spellbook onto the slots, or press Record and click a spell the way you want to cast it."])
	p:Button(L["Open the click editor"], function() HoA.Editor:Show() end, 200)
	p:Check(L["Open the editor with the spellbook"], nil, opt("editorWithSpellbook"))
	p:Check(L["Hover keys: mouse over a frame + 1 to 5"], L["Like Clique: these keys only cast while your mouse is on a frame."], function() return HoA.char.hoverKeys end, function(v) HoA.char.hoverKeys = v HoA:Fire("BINDINGS") end)
	p:Gap()
	p:Button(L["Back to the class defaults"], function() B:Reset() end, 200)
end

C.PAGES[1].build, C.PAGES[2].build, C.PAGES[3].build = C.BuildFrames, C.BuildShow, C.BuildClicks

-- everything on one page (kept for callers that want it)
function C.Build(p)
	C.BuildFrames(p) p:Gap() C.BuildShow(p) p:Gap() C.BuildClicks(p)
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
	local function panel(build)
		local f = CreateFrame("Frame")
		f:Hide()
		build(setmetatable({ frame = f, y = -16 }, Page))
		return f
	end
	category = Settings.RegisterCanvasLayoutCategory(panel(C.BuildFrames), "Healers of Azeroth")
	Settings.RegisterAddOnCategory(category)
	-- the other pages as sub-pages when the client has them, else one long page
	if Settings.RegisterCanvasLayoutSubcategory then
		Settings.RegisterCanvasLayoutSubcategory(category, panel(C.BuildShow), L["On the frames"])
		Settings.RegisterCanvasLayoutSubcategory(category, panel(C.BuildClicks), L["Your clicks"])
	end
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
		for _, pg in ipairs(C.PAGES) do
			table.insert(c.configPages, { key = pg.key, label = L[pg.label], group = "Healers of Azeroth", build = pg.build })
		end
	else
		standalone()
	end
end
