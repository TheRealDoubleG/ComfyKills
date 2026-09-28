local ADDON_NAME = ...

ComfyKills = ComfyKills or {}
local A=ComfyKills

A.name=ADDON_NAME or "ComfyKills"
A.version="0.3"
A.buildDate="28.09.2026"
A.status="Beta"
A.gameVersion="WoW Forever 1.60.1"
A.targetBuild="70009"
A.interface=16001
A.author="TheRealDoubleG"
A.discord="the.real.double.g"
A.github="https://github.com/TheRealDoubleG/ComfyKills"

local defaults={
    enabled=true,
    kills={
        showTooltip=true,
        trackDeaths=true,
        countPetKills=true,
        milestoneNotifications=true,
    },
    optionsWindow={point="CENTER",relativePoint="CENTER",x=0,y=20},
    ui={windowLocked=false,windowOpacity=100,showWindowBorder=true,backgroundAlpha=92},
}

function A:Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyKills:|r "..tostring(msg)) end
end
function A:GetClientBuildInfo()
    if type(GetBuildInfo)~="function" then return "?","?","?",nil end
    local v,b,d,i=GetBuildInfo(); return tostring(v or "?"),tostring(b or "?"),tostring(d or "?"),tonumber(i)
end
function A:GetCompatibilityStatus()
    local _,_,_,i=self:GetClientBuildInfo()
    if i and tonumber(i)==tonumber(self.interface) then return true,self:T("COMPAT_MATCH") end
    return false,self:T("COMPAT_UPDATE_REQUIRED")
end
function A:InitializeDB() self:InitializeProfileStorage(defaults,"ComfyKillsDB") end
function A:SetEnabled(v)
    if not self.db then return false end
    self.db.enabled=v and true or false
    if self.RefreshFeature then self:RefreshFeature() end
    if self.RefreshOptions then self:RefreshOptions() end
    return true
end
function A:GetComfyProfileProvider() return self end
function A:OpenOptions() if self.ShowOptions then self:ShowOptions() end end

SLASH_COMFYKILLS1="/comfykills"
SLASH_COMFYKILLS2="/ckills"
SlashCmdList.COMFYKILLS=function(msg)
    msg=tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg=="options" or msg=="config" then A:OpenOptions(); return end
    if A.ShowBrowser then A:ShowBrowser() else A:OpenOptions() end
end

local e=CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED"); e:RegisterEvent("PLAYER_LOGIN")
e:SetScript("OnEvent",function(_,ev,arg1)
    if ev=="ADDON_LOADED" and arg1==A.name then
        A:InitializeDB()
        if A.InitializeFeature then A:InitializeFeature() end
        if A.InitializeOptions then A:InitializeOptions() end
    elseif ev=="PLAYER_LOGIN" and A.RefreshFeature then A:RefreshFeature() end
end)
