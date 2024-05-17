--[[
	1.  MLookLock sets perma-mouselook with the LMB as MoveForward and RMB as MoveBackward
	2.  It has a temporary disable keybind to use the mouse as normal (hold it to use the mouse)
	3.  Double-clicking on the temporary key will toggle MLookLock on and off for extended use of the mouse.
	4.  Any of the WoW UIPanels (such as the spell book, character frame, Loot Window and more) will automatically disable
	MLookLock while they're on the screen).
	5.  You can add frames to a watched frame list, and they will behave like the WoW UI panels.
	
	The fact that WoW wasn't designed for this use leads to a couple of quirks - it is possible to confuse
	things by (for instance) pressing and holding the left mouse button *RIGHT AFTER* right-clicking
	a corpse with AutoLoot set.  If you ever have the cursor not show up when you hold the momentary 
	button, just press and hold the momentary button then click the LMB - this usually clears it.
	
	Keybindings:
		Momentary 	- used to momentarily disable MLookLock (double click toggles MLL)
		Add Frame	- used to add a frame to the frame watch list
		Del Frame	- used to remove a frame from the frame watch list
	Slash commands
		/mll clearlist	- clears the frame watch list
		/mll timer nnn	- where nnn is the number of milliseconds between checking the watched frames
	
	MOVEFORWARD/MOVEBACKWARD down = Don't disable
	MOMENTARY, not MF/MB down = disable
	FRAME onscreen, not MF/MB down = disable
	
	V1.0	Initial Release
	V1.1	Fixed a small error introduced when I cleaned up the code for public release
--]]
local crosshairFrame = CreateFrame("Frame", "OldScrollsCrosshairFrame", UIParent)
crosshairFrame:SetWidth(16)
crosshairFrame:SetHeight(16)
crosshairFrame:SetPoint("CENTER", 0, 0)

local crosshairTexture = crosshairFrame:CreateTexture(nil, "OVERLAY")
crosshairTexture:SetAllPoints()
crosshairTexture:SetTexture("Interface\\AddOns\\MLookLock\\crosshair.tga")

function ShowCrosshair()
    crosshairFrame:Show()
end

function HideCrosshair()
    crosshairFrame:Hide()
end

local 	enabled, mfd, mbd, mtd, open = true, nil, nil, nil, nil
local 	onevent, onupdate, toggleenabled, setmouselook, checkframes, checklist, slashcmd
local	lastclick, dclickdelay = GetTime(), .3
local 	timer = .25

MLookLockSavedData = {
	framelist 	= {},
	timer		= .25,
	enabled 	= true,
}

BINDING_HEADER_MLOOKLOCK = "Mairelon's LookLock"
BINDING_NAME_MLL_MOMENTARY = "Momentary Disable"
BINDING_NAME_MLL_ADDFRAME = "Add frame to watch list"
BINDING_NAME_MLL_DELFRAME = "Delete frame from watch list"

function checkframes()
	local leftFrame = GetUIPanel("left");
	local centerFrame = GetUIPanel("center");
	local rightFrame = GetUIPanel("right");
	local doublewideFrame = GetUIPanel("doublewide");
	local fullScreenFrame = GetUIPanel("fullscreen");
	
	frm = leftFrame or centerFrame or rightFrame or doublewideFrame or fullScreenFrame or checklist();
	setmouselook();
end

function checklist()
	if not MLookLockSavedData then
		return;
	end
	for frame, _ in pairs(MLookLockSavedData.framelist) do
		local f = getglobal(frame);
		if f and f:IsVisible() then 
			return true;
		end
	end
end

function onevent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		SetMouselookOverrideBinding("BUTTON1", "MOVEFORWARD");
		SetMouselookOverrideBinding("BUTTON2", "MOVEBACKWARD");
		checkframes();
		UIErrorsFrame:AddMessage("Mouse Look Lock is " .. ((MLookLockSavedData.enabled and "ON") or "OFF"), 1, 1, 0);
	end
end

function setmouselook()
	if mfd or mbd then 
		return;
	end
	if mtd or frm or (not MLookLockSavedData.enabled) then
		if IsMouselooking() then 
			MouselookStop()
			HideCrosshair() 
		end
		return;
	end
	if not IsMouselooking() then
		MouselookStart()
		ShowCrosshair()
	end
end

function toggleenabled()
	MLookLockSavedData.enabled = not MLookLockSavedData.enabled;
	UIErrorsFrame:AddMessage("Mouse Look " .. ((MLookLockSavedData.enabled and "ON") or "OFF"), 1, 1, 0);
	setmouselook()
end

function MLookLockChangeSettings(mode, keystate)
	if mode == "momentary" then
		if keystate == "down" then
			if (GetTime() - lastclick) < dclickdelay then
				toggleenabled();
			end
			lastclick = GetTime();
			mtd = true;
		else
			mtd = false;
		end
		setmouselook();
	elseif mode == "addframe" then
		if not MLookLockSavedData then
			return;
		end
		local frame = GetMouseFocus();
		if frame and frame.GetName and frame:GetName() then
			MLookLockSavedData.framelist[frame:GetName()] = true;
			UIErrorsFrame:AddMessage(frame:GetName() .. " has been added to the frame watch", 0, 1, 0);
		end
	elseif mode == "delframe" then
		if not MLookLockSavedData then
			return;
		end
		local frame = GetMouseFocus();
		if frame and frame.GetName and frame:GetName() then
			MLookLockSavedData.framelist[frame:GetName()] = nil;
			UIErrorsFrame:AddMessage(frame:GetName() .. " has been removed from the frame watch", 0, 1, 0);
		end
	end
end

function slashcmd(msg)
	msg = strlower(msg);
	if string.match(msg, "timer") then
		local delay = string.match(msg,"(%d+)");
		prn(delay, msg)
		if delay and tonumber(delay) then
			MLookLockSavedData.timer = delay/1000;
		end
	elseif string.match("msg", "clearlist") then
		for k,v in pairs(MLookLockSavedData.framelist) do
			MLookLockSavedData.framelist[k] = nil;
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Use /mll clearlist to clear the frame watch list")
		DEFAULT_CHAT_FRAME:AddMessage("Use /mll timer nnn - where nnn is the delay in milliseconds")
		DEFAULT_CHAT_FRAME:AddMessage("to delay between checking the frame watch list")
	end;
end

local 	frame = CreateFrame("Frame")
		frame:RegisterEvent("PLAYER_LOGIN");
		frame:SetScript("OnEvent", onevent);
		frame:SetScript("OnMouseDown", frame.OnMouseDown)


		
SlashCmdList["MLOOKLOCK_COMMAND"] = slashcmd
SLASH_MLOOKLOCK_COMMAND1 = "/mll"





