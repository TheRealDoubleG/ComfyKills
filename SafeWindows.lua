ComfyKills = ComfyKills or {}
local A = ComfyKills

A.version = "0.4"
A.buildDate = "04.10.2026"
A.safeOptionControls = A.safeOptionControls or {}

local function RelativeTime(epoch)
    local now=type(time)=="function" and time() or 0
    local delta=math.max(0,now-(tonumber(epoch) or now))
    if delta<60 then return tostring(delta).."s" end
    if delta<3600 then return tostring(math.floor(delta/60)).."m" end
    if delta<86400 then return tostring(math.floor(delta/3600)).."h" end
    return tostring(math.floor(delta/86400)).."d"
end

local function SafeCheck(parent,text,x,y,get,set)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); c:SetPoint("TOPLEFT",x,y)
    local label=c.Text or c.text; if label then label:SetText(text) end
    c.__get=get; c:SetChecked(get() and true or false)
    c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); if A.RefreshFeature then A:RefreshFeature() end end)
    A.safeOptionControls[#A.safeOptionControls+1]=c; return c
end
local function SafeButton(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(w or 120,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text); b:SetScript("OnClick",fn); return b
end
local function SafeSlider(parent,label,minV,maxV,step,x,y,get,set,formatter)
    A.__safeSliderIndex=(A.__safeSliderIndex or 0)+1; local name="ComfyKillsSafeSlider"..A.__safeSliderIndex
    local s=CreateFrame("Slider",name,parent,"OptionsSliderTemplate"); s:SetPoint("TOPLEFT",x,y); s:SetWidth(250); s:SetMinMaxValues(minV,maxV); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    _G[name.."Low"]:SetText(tostring(minV)); _G[name.."High"]:SetText(tostring(maxV)); _G[name.."Text"]:SetText(label)
    s.valueText=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); s.valueText:SetPoint("LEFT",s,"RIGHT",12,0); s.__get=get; s.__format=formatter
    local v=get(); s:SetValue(v); s.valueText:SetText(formatter and formatter(v) or tostring(v))
    s:SetScript("OnValueChanged",function(self,value) if self.__refreshing then return end; set(value); self.valueText:SetText(formatter and formatter(value) or tostring(value)); if A.RefreshFeature then A:RefreshFeature() end end)
    A.safeOptionControls[#A.safeOptionControls+1]=s; return s
end
local function SafeDropdown(parent,x,y,width,itemsFn,currentFn,selectFn)
    local d=CreateFrame("Frame",nil,parent,"UIDropDownMenuTemplate"); d:SetPoint("TOPLEFT",x,y); if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(d,width or 200) end
    d.__refresh=function()
        local cur=currentFn(); local label=tostring(cur or "")
        for _,entry in ipairs(itemsFn() or {}) do if entry.value==cur then label=entry.text break end end
        if UIDropDownMenu_SetText then UIDropDownMenu_SetText(d,label) end
    end
    UIDropDownMenu_Initialize(d,function(_,level)
        local cur=currentFn(); for _,entry in ipairs(itemsFn() or {}) do local info=UIDropDownMenu_CreateInfo(); info.text=entry.text; info.value=entry.value; info.checked=entry.value==cur; info.func=function() selectFn(entry.value); CloseDropDownMenus(); d.__refresh(); if A.RefreshFeature then A:RefreshFeature() end end; UIDropDownMenu_AddButton(info,level) end
    end)
    d.__refresh(); A.safeOptionControls[#A.safeOptionControls+1]=d; return d
end
local function SafeEdit(parent,x,y,w,h,multiline)
    local e=CreateFrame("EditBox",nil,parent,multiline and "BackdropTemplate" or "InputBoxTemplate"); e:SetPoint("TOPLEFT",x,y); e:SetSize(w,h); e:SetAutoFocus(false); e:SetMultiLine(multiline and true or false); e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end); return e
end

function A:RefreshSafeOptions()
    for _,c in ipairs(self.safeOptionControls or {}) do
        if c.__refresh then c.__refresh()
        elseif c.__get then
            local value=c.__get(); local kind=c:GetObjectType()
            if kind=="CheckButton" then c:SetChecked(value and true or false)
            elseif kind=="Slider" then c.__refreshing=true; c:SetValue(value); c.__refreshing=false; if c.valueText then c.valueText:SetText(c.__format and c.__format(value) or tostring(value)) end end
        end
    end
    if self.RefreshSharedSettingsPage then self:RefreshSharedSettingsPage() end
    if self.RefreshFeatureOptions then self:RefreshFeatureOptions() end
end

local function SelectSafeTab(index)
    local f=A.optionsFrame; if not f then return end
    for i,tab in ipairs(f.tabs or {}) do tab:SetEnabled(true); tab:SetButtonState(i==index and "PUSHED" or "NORMAL",false); if f.pages[i] then f.pages[i]:SetShown(i==index) end end
end

-- Safe options window: deliberately does not write to UISpecialFrames. That
-- table is protected on Forever and was the source of the ComfyKills block.
function A:InitializeOptions()
    if self.optionsFrame then return end
    wipe(self.safeOptionControls)
    local f=CreateFrame("Frame","ComfyKillsOptions",UIParent,"BasicFrameTemplateWithInset"); f:SetSize(760,620)
    local pos=self.db and self.db.optionsWindow or {}; local point=pos.point or "CENTER"; local rp=pos.relativePoint or point
    f:SetPoint(point,UIParent,rp,pos.x or 0,pos.y or 20); f:SetClampedToScreen(true); f:SetFrameStrata("HIGH"); f:SetFrameLevel(20); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:Hide(); f.TitleText:SetText("ComfyKills")
    f:SetScript("OnDragStart",function(self) if A.IsOptionsWindowLocked and A:IsOptionsWindowLocked() then return end; self:StartMoving() end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); local p,_,r,x,y=self:GetPoint(1); A.db.optionsWindow=A.db.optionsWindow or {}; A.db.optionsWindow.point=p; A.db.optionsWindow.relativePoint=r or p; A.db.optionsWindow.x=x or 0; A.db.optionsWindow.y=y or 0 end)
    self.optionsFrame=f; f.tabs={}; f.pages={}
    local names={self:T("TAB_GENERAL"),self:GetSharedSettingsTabLabel(),self:T("TAB_INFO")}
    for i,label in ipairs(names) do
        local idx=i; local tab=SafeButton(f,label,18+(i-1)*120,-35,110,function() SelectSafeTab(idx) end); f.tabs[i]=tab
        local page=CreateFrame("Frame",nil,f); page:SetPoint("TOPLEFT",12,-70); page:SetPoint("BOTTOMRIGHT",-12,12); f.pages[i]=page
    end
    local general=f.pages[1]
    local title=general:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",20,-10); title:SetText(self:T("TAB_GENERAL"))
    SafeCheck(general,self:T("ADDON_ENABLED"),20,-50,function() return A.db.enabled end,function(v) A:SetEnabled(v) end)
    local ui={CreateCheck=SafeCheck,CreateButton=SafeButton,CreateSlider=SafeSlider,CreateDropdown=SafeDropdown,CreateEdit=SafeEdit}
    if self.BuildGeneralOptions then self:BuildGeneralOptions(general,ui) end
    if self.BuildSharedSettingsPage then self:BuildSharedSettingsPage(f.pages[2]) end
    local info=f.pages[3]; local h=info:CreateFontString(nil,"ARTWORK","GameFontNormalHuge"); h:SetPoint("TOPLEFT",20,-24); h:SetText("ComfyKills")
    local t=info:CreateFontString(nil,"ARTWORK","GameFontHighlight"); t:SetPoint("TOPLEFT",20,-72); t:SetWidth(680); t:SetJustifyH("LEFT"); t:SetText("Version "..tostring(self.version).." · "..tostring(self.status).."\nBuild: "..tostring(self.buildDate).."\nAutor: "..tostring(self.author).."\nDiscord: "..tostring(self.discord).."\nGitHub: "..tostring(self.github).."\n\n/comfykills · /ckills")
    f:SetScript("OnShow",function() if A.ApplySharedWindowSettings then A:ApplySharedWindowSettings() end; A:RefreshSafeOptions() end)
    if self.ApplySharedWindowSettings then self:ApplySharedWindowSettings() end
    SelectSafeTab(1); self:RefreshSafeOptions(); if self.RegisterBlizzardSettingsCategory then self:RegisterBlizzardSettingsCategory() end
end

function A:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show(); self.optionsFrame:Raise(); self:RefreshSafeOptions()
end

-- Safe browser replacement; same database UI without UISpecialFrames writes.
function A:CreateBrowser()
    if self.browser then return end
    local f=CreateFrame("Frame","ComfyKillsBrowser",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(780,610); f:SetPoint("CENTER"); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end); f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f.TitleText:SetText("ComfyKills · "..self:T("DATABASE")); f:Hide(); self.browser=f; self.browserMode="all"
    local all=SafeButton(f,self:T("ALL_KILLS"),20,-32,110,function() A.browserMode="all"; A:RefreshBrowser() end)
    local ses=SafeButton(f,self:T("SESSION"),138,-32,110,function() A.browserMode="session"; A:RefreshBrowser() end)
    local search=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); search:SetSize(260,28); search:SetPoint("TOPRIGHT",-24,-31); search:SetAutoFocus(false); search:SetScript("OnTextChanged",function(self) A.browserSearch=self:GetText() or ""; A:RefreshBrowser() end); search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local headers={{self:T("MOB"),28},{self:T("KILLS"),455},{self:T("TYPE"),535},{self:T("LAST_KILL"),650}}
    for _,h in ipairs(headers) do local t=f:CreateFontString(nil,"ARTWORK","GameFontNormal"); t:SetPoint("TOPLEFT",h[2],-78); t:SetText(h[1]) end
    self.browserRows={}
    for i=1,16 do
        local row=CreateFrame("Frame",nil,f); row:SetSize(730,27); row:SetPoint("TOPLEFT",22,-100-(i-1)*28); local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,i%2==0 and .035 or .015)
        row.name=row:CreateFontString(nil,"ARTWORK","GameFontHighlight"); row.name:SetPoint("LEFT",6,0); row.name:SetWidth(410); row.name:SetJustifyH("LEFT")
        row.count=row:CreateFontString(nil,"ARTWORK","GameFontHighlight"); row.count:SetPoint("LEFT",430,0); row.count:SetWidth(70); row.count:SetJustifyH("RIGHT")
        row.type=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); row.type:SetPoint("LEFT",515,0); row.type:SetWidth(105); row.type:SetJustifyH("LEFT")
        row.last=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); row.last:SetPoint("LEFT",630,0); row.last:SetWidth(85); row.last:SetJustifyH("LEFT"); row:EnableMouse(true)
        row:SetScript("OnEnter",function(self) if not self.data or not GameTooltip then return end; local r=self.data.record; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(r.name or "Unknown",1,.82,0); GameTooltip:AddDoubleLine("NPC ID",tostring(r.npcID or "—"),1,1,1,1,1,1); GameTooltip:AddDoubleLine("Account",tostring(r.total or 0),1,1,1,.2,1,.2); if r.averageXP then GameTooltip:AddDoubleLine(A:T("TOOLTIP_AVG_XP"),string.format("%.1f",r.averageXP),1,1,1,1,.82,0) end; GameTooltip:Show() end)
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end); self.browserRows[i]=row
    end
end

function A:RefreshBrowser()
    if not self.browser or not self.browser:IsShown() then return end
    local records=self:GetBrowserRecords()
    for i,row in ipairs(self.browserRows or {}) do local item=records[i]; if item then row.data=item; row.name:SetText(item.record.name or item.key); row.count:SetText(tostring(item.count)); row.type:SetText(item.record.creatureType or item.record.classification or "—"); row.last:SetText(RelativeTime(item.record.lastKill)); row:Show() else row.data=nil; row:Hide() end end
end
