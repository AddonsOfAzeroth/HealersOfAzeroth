-- Healers of Azeroth by DinX: its line in the "Addons of Azeroth" minimap list (Hub.lua).
local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	C_Timer.After(0, function()
		local hub = _G.AddonsOfAzerothHub
		if not hub then return end
		local HoA = ns.HoA
		hub:Register({
			key = "healers", addon = ADDON,
			click = function() SlashCmdList.HEALERSOFAZEROTH("") end,
			right = function() SlashCmdList.HEALERSOFAZEROTH("clicks") end,
		})
	end)
end)
