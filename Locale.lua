-- Healers of Azeroth by DinX: translations. Code uses English strings as keys: L["Text"].
local _, ns = ...
local HoA = ns.HoA

local NL = {}
HoA.translations = { nlNL = NL }

HoA.L = setmetatable({}, {
	__index = function(_, key)
		local lang = HoA.db and HoA.db.language or "auto"
		if lang == "auto" then -- follow Casters of Azeroth, else the client
			local c = HoA.Casters and HoA:Casters()
			lang = (c and c.db and c.db.language ~= "auto" and c.db.language) or (GetLocale() == "nlNL" and "nlNL") or "enUS"
		end
		local t = HoA.translations[lang]
		return t and t[key] or key
	end,
})

for k, v in pairs({
	-- clicks
	["Left"] = "Links",
	["Right"] = "Rechts",
	["Middle"] = "Midden",
	["Shift"] = "Shift",
	["Ctrl"] = "Ctrl",
	["Alt"] = "Alt",
	["Target"] = "Selecteren",
	["Menu"] = "Menu",
	["Nothing"] = "Niets",
	-- frames
	["Offline"] = "Offline",
	["Dead"] = "Dood",
	["Group frames"] = "Groepsframes",
	-- settings
	["Click a group member to heal them: every click is yours, on Blizzard's own secure buttons. Changes take effect out of combat."] = "Klik op een groepslid om het te healen: elke klik is van jou, op Blizzards eigen beveiligde knoppen. Wijzigingen gelden buiten gevecht.",
	["Group frames on"] = "Groepsframes aan",
	["Show your own frame when you are alone"] = "Je eigen frame tonen als je alleen bent",
	["Handy to try your clicks."] = "Handig om je klikken uit te proberen.",
	["In a party"] = "In een groep",
	["In a raid"] = "In een raid",
	["Hide Blizzard's party and raid frames"] = "Blizzards groeps- en raidframes verbergen",
	["Takes effect after /reload when you turn it off."] = "Uitzetten werkt na /reload.",
	["Incoming heals on the bars"] = "Binnenkomende heals op de balken",
	["Missing health (-1234)"] = "Ontbrekend leven (-1234)",
	["Only when the game shows the numbers (often hidden in combat)."] = "Alleen als het spel de cijfers toont (in gevecht vaak verborgen).",
	["Members per column"] = "Leden per kolom",
	["Your clicks"] = "Jouw klikken",
	["Back to the class defaults"] = "Terug naar de standaard van je klasse",
	["Language"] = "Taal",
	["Automatic"] = "Automatisch",
	-- slash
	["Frames locked."] = "Kaders vergrendeld.",
	["Frames unlocked: drag the frames where you like, drag the corner to make them bigger, type /hoa lock when done."] = "Kaders ontgrendeld: sleep de frames waar je wil, sleep de hoek om ze groter te maken, typ /hoa lock als je klaar bent.",
	["/hoa: settings (your clicks). /hoa toggle: frames on/off. /hoa unlock: move and resize."] = "/hoa: instellingen (jouw klikken). /hoa toggle: frames aan/uit. /hoa unlock: verplaatsen en groter maken.",
	["Drag: make it bigger so more fits. Double-click: default size."] = "Slepen: groter maken zodat er meer in past. Dubbelklik: standaardgrootte.",
}) do NL[k] = v end
