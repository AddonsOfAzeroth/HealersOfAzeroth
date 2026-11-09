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
	["/hoa: settings. /hoa clicks: edit your clicks. /hoa test: simulate party, raid, off. /hoa sort: next order. /hoa toggle: frames on/off. /hoa unlock: move and resize."] = "/hoa: instellingen. /hoa clicks: je klikken aanpassen. /hoa test: party, raid of uit simuleren. /hoa sort: volgende volgorde. /hoa toggle: frames aan/uit. /hoa unlock: verplaatsen en groter maken.",
	-- simulation, roles, party/raid
	["Party frames"] = "Groepsframes",
	["Order"] = "Volgorde",
	["Role"] = "Rol",
	["Groups"] = "Groepen",
	["Class"] = "Class",
	["Name"] = "Naam",
	["Click: next order (also in combat)."] = "Klik: volgende volgorde (ook in gevecht).",
	["Order button above the frames"] = "Volgorde-knopje boven de frames",
	["By role: tanks, healers, damage"] = "Per rol: tanks, healers, dps",
	["By raid group"] = "Per raidgroep",
	["By class"] = "Per class",
	["By name"] = "Op naam",
	["Raid frames"] = "Raidframes",
	["Member"] = "Lid",
	["Party"] = "Groep",
	["Raid"] = "Raid",
	["Done"] = "Klaar",
	["Simulation: drag the blue box to move, its corner to resize."] = "Simulatie: sleep het blauwe vak om te verplaatsen, de hoek om groter te maken.",
	["See, move and resize the frames with made-up members:"] = "Bekijk, verplaats en vergroot de frames met verzonnen leden:",
	["Simulate party"] = "Groep simuleren",
	["Simulate raid"] = "Raid simuleren",
	["Role icon: tank and healer"] = "Rol-icoon: tank en healer",
	["Also for damage dealers"] = "Ook voor damage dealers",
	-- new options
	["Show the frames"] = "Frames tonen",
	["In a group, or alone in combat"] = "In een groep, of alleen in gevecht",
	["Only in a group"] = "Alleen in een groep",
	["Always"] = "Altijd",
	["Tanks first"] = "Tanks eerst",
	["Tanks on top, then healers, then the rest."] = "Tanks bovenaan, dan healers, dan de rest.",
	["On the frames"] = "Op de frames",
	["Your HoTs and shields with their time"] = "Je HoTs en schilden met hun tijd",
	["Gold edge on who needs a heal most"] = "Gouden rand rond wie een heal het meest nodig heeft",
	["Mark when your class buff is missing"] = "Teken als je class-buff ontbreekt",
	["Alt + middle click gives it."] = "Alt + middenklik geeft hem.",
	["Mana bar for healers"] = "Manabalk voor healers",
	["A dispel icon shows on the right of a frame when you can remove something."] = "Rechts op een frame verschijnt een dispel-icoon als jij iets kan wegnemen.",
	["Open the click editor"] = "Klikken-editor openen",
	["Drag spells from your spellbook onto the slots, or press Record and click a spell the way you want to cast it."] = "Sleep spells uit je spellboek op de vakjes, of druk op Opnemen en klik een spell zoals je hem wil casten.",
	["Open the editor with the spellbook"] = "Editor openen samen met het spellboek",
	["Hover keys: mouse over a frame + 1 to 5"] = "Hover-toetsen: muis op een frame + 1 tot 5",
	["Like Clique: these keys only cast while your mouse is on a frame."] = "Zoals Clique: deze toetsen casten alleen als je muis op een frame staat.",
	["Key"] = "Toets",
	-- editor
	["Plain"] = "Gewoon",
	["Mouse over a frame + key 1 to 5"] = "Muis op een frame + toets 1 tot 5",
	["Drag a spell from your spellbook here."] = "Sleep hier een spell uit je spellboek naartoe.",
	["Right-click: empty. Shift + right-click: target. Ctrl + right-click: Blizzard's menu."] = "Rechtsklik: leegmaken. Shift + rechtsklik: selecteren. Ctrl + rechtsklik: Blizzards menu.",
	["Raid marks (skull, star, ...)"] = "Raid-markeringen (schedel, ster, ...)",
	["Main tank, main assist and marks: set them in Blizzard's menu on a frame (a click set to Menu, e.g. Ctrl + right-click in the click editor). They show here and on everyone's Blizzard frames."] = "Main tank, main assist en markeringen: zet je via Blizzards menu op een frame (een klik op Menu, bv. Ctrl + rechtsklik in de klikken-editor). Ze verschijnen hier en bij iedereen op Blizzards frames.",
	["Not in combat: try again after the fight."] = "Niet in gevecht: probeer opnieuw na het gevecht.",
	["Drag spells from your spellbook onto the slots: heals, buffs, dispels, anything that targets a friend."] = "Sleep spells uit je spellboek op de vakjes: heals, buffs, dispels, alles wat je op een vriend cast.",
	["Record"] = "Opnemen",
	["Stop"] = "Stop",
	["Click it with the click you want, or press 1 to 5."] = "Klik erop met de klik die je wil, of druk 1 tot 5.",
	["Now click a spell in your spellbook with the click you want (Shift + right, ...), or point at it and press 1 to 5."] = "Klik nu een spell in je spellboek met de klik die je wil (Shift + rechts, ...), of wijs hem aan en druk 1 tot 5.",
	["Click a spell in your spellbook the way you want to cast it. It is not cast, only saved."] = "Klik een spell in je spellboek zoals je hem wil casten. Hij wordt niet gecast, alleen opgeslagen.",
	["Drag: make it bigger so more fits. Double-click: default size."] = "Slepen: groter maken zodat er meer in past. Dubbelklik: standaardgrootte.",
}) do NL[k] = v end
