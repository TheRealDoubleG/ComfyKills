ComfyKills=ComfyKills or {}
local A=ComfyKills
A.unitCache=A.unitCache or {}

local MILESTONES={[10]=true,[25]=true,[50]=true,[100]=true,[250]=true,[500]=true,[1000]=true,[2500]=true,[5000]=true}

local function Epoch() return type(time)=="function" and time() or 0 end
local function Now() return type(GetTime)=="function" and GetTime() or 0 end

local function NPCIDFromGUID(guid)
    if type(guid)~="string" then return nil end
    return tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
end

local function CurrentPosition()
    if not C_Map or type(C_Map.GetBestMapForUnit)~="function" or type(C_Map.GetPlayerMapPosition)~="function" then return nil end
    local ok,mapID=pcall(C_Map.GetBestMapForUnit,"player")
    if not ok or not mapID then return nil end
    local ok2,pos=pcall(C_Map.GetPlayerMapPosition,mapID,"player")
    if not ok2 or not pos or type(pos.GetXY)~="function" then return mapID end
    local x,y=pos:GetXY()
    return mapID,tonumber(x),tonumber(y)
end

local function RelativeTime(epoch)
    local delta=math.max(0,Epoch()-(tonumber(epoch) or Epoch()))
    if delta<60 then return tostring(delta).."s" end
    if delta<3600 then return tostring(math.floor(delta/60)).."m" end
    if delta<86400 then return tostring(math.floor(delta/3600)).."h" end
    return tostring(math.floor(delta/86400)).."d"
end

function A:CaptureUnit(unit)
    if type(UnitGUID)~="function" then return end
    local guid=UnitGUID(unit)
    if not guid then return end
    self.unitCache[guid]={
        name=type(UnitName)=="function" and UnitName(unit) or nil,
        level=type(UnitLevel)=="function" and tonumber(UnitLevel(unit)) or nil,
        creatureType=type(UnitCreatureType)=="function" and UnitCreatureType(unit) or nil,
        classification=type(UnitClassification)=="function" and UnitClassification(unit) or nil,
        seenAt=Epoch(),
    }
end

function A:GetSessionMobCount(key)
    if type(ComfyData)~="table" then return 0 end
    local store=ComfyData:GetKillStore()
    local session=store.sessions and store.sessions[ComfyData.sessionID or "current"]
    return session and session.mobs and (tonumber(session.mobs[key]) or 0) or 0
end

function A:RecordKill(sourceGUID,destGUID,destName)
    if not self.db or not self.db.enabled or type(ComfyData)~="table" or type(ComfyData.RecordKill)~="function" then return end
    local playerGUID=type(UnitGUID)=="function" and UnitGUID("player") or nil
    local petGUID=type(UnitGUID)=="function" and UnitGUID("pet") or nil
    if sourceGUID~=playerGUID and not (self.db.kills.countPetKills and sourceGUID==petGUID) then return end

    local cached=self.unitCache[destGUID] or {}
    local mapID,x,y=CurrentPosition()
    local key,record=ComfyData:RecordKill({
        npcID=NPCIDFromGUID(destGUID),
        name=destName or cached.name or "Unknown",
        level=cached.level,creatureType=cached.creatureType,classification=cached.classification,
        mapID=mapID,x=x,y=y,time=Epoch(),
    })

    self.pendingKillKey=key
    self.pendingKillAt=Now()
    self.pendingKillXPBefore=type(UnitXP)=="function" and tonumber(UnitXP("player")) or nil

    if self.db.kills.milestoneNotifications and record and MILESTONES[tonumber(record.total) or 0] then
        self:Print((record.name or "Mob")..": "..tostring(record.total).." kills")
    end
    self:RefreshBrowser()
    self:RefreshFeatureOptions()
end

function A:HandleCombatLog()
    if type(CombatLogGetCurrentEventInfo)~="function" then return end
    local data={CombatLogGetCurrentEventInfo()}
    if data[2]=="PARTY_KILL" then A:RecordKill(data[4],data[8],data[9]) end
end

function A:HandleXPUpdate()
    if not self.pendingKillKey or Now()-(self.pendingKillAt or 0)>5 then self.pendingKillKey=nil; return end
    local current=type(UnitXP)=="function" and tonumber(UnitXP("player")) or nil
    local before=self.pendingKillXPBefore
    if current and before then
        local delta=current-before
        if delta>0 and type(ComfyData)=="table" then ComfyData:RecordKillXP(self.pendingKillKey,delta) end
    end
    self.pendingKillKey=nil
end

function A:AddUnitTooltip(tooltip,unit)
    if not self.db or not self.db.enabled or not self.db.kills.showTooltip or type(ComfyData)~="table" or not unit then return end
    local guid=type(UnitGUID)=="function" and UnitGUID(unit) or nil
    local npcID=NPCIDFromGUID(guid)
    local name=type(UnitName)=="function" and UnitName(unit) or nil
    local key=ComfyData:GetKillKey({npcID=npcID,name=name})
    local record=ComfyData:GetKillRecord(key)
    if not record then return end
    local charKey=ComfyData:GetCurrentKey()
    tooltip:AddLine(" ")
    tooltip:AddLine("ComfyKills",0.2,0.65,1)
    tooltip:AddDoubleLine(self:T("TOOLTIP_CHARACTER"),tostring((record.characters and record.characters[charKey]) or 0),1,1,1,0.2,1,0.2)
    tooltip:AddDoubleLine(self:T("TOOLTIP_ACCOUNT"),tostring(record.total or 0),1,1,1,0.2,1,0.2)
    tooltip:AddDoubleLine(self:T("TOOLTIP_SESSION"),tostring(self:GetSessionMobCount(key)),1,1,1,0.2,1,0.2)
    if tonumber(record.averageXP) then tooltip:AddDoubleLine(self:T("TOOLTIP_AVG_XP"),string.format("%.1f",record.averageXP),1,1,1,1,0.82,0) end
end

function A:HookTooltips()
    if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall)=="function" and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(t)
            local _,unit=t:GetUnit()
            A:AddUnitTooltip(t,unit)
        end)
    elseif GameTooltip and type(GameTooltip.HookScript)=="function" then
        pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",function(t)
            local _,unit=t:GetUnit(); A:AddUnitTooltip(t,unit)
        end)
    end
end

function A:GetSummary()
    if type(ComfyData)~="table" then return 0,0,0 end
    local store=ComfyData:GetKillStore()
    local total,unique=0,0
    for _,r in pairs(store.account or {}) do unique=unique+1; total=total+(tonumber(r.total) or 0) end
    local deaths=store.deaths and store.deaths[ComfyData:GetCurrentKey()]
    return total,unique,deaths and tonumber(deaths.total) or 0
end

function A:RefreshFeatureOptions()
    if self.summaryText then
        local total,unique,deaths=self:GetSummary()
        self.summaryText:SetText(string.format(self:T("SUMMARY_FORMAT"),total,unique,deaths))
    end
end

function A:GetBrowserRecords()
    local out={}
    if type(ComfyData)~="table" then return out end
    local store=ComfyData:GetKillStore()
    local query=tostring(self.browserSearch or ""):lower()
    local session=store.sessions and store.sessions[ComfyData.sessionID or "current"]
    for key,record in pairs(store.account or {}) do
        local count=tonumber(record.total) or 0
        if self.browserMode=="session" then count=session and session.mobs and (tonumber(session.mobs[key]) or 0) or 0 end
        if count>0 and (query=="" or tostring(record.name or ""):lower():find(query,1,true)) then
            out[#out+1]={key=key,record=record,count=count}
        end
    end
    table.sort(out,function(a,b)
        if a.count~=b.count then return a.count>b.count end
        return tostring(a.record.name or ""):lower()<tostring(b.record.name or ""):lower()
    end)
    return out
end

function A:CreateBrowser()
    if self.browser then return end
    local f=CreateFrame("Frame","ComfyKillsBrowser",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(780,610); f:SetPoint("CENTER"); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end); f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f.TitleText:SetText("ComfyKills · "..self:T("DATABASE")); f:Hide(); table.insert(UISpecialFrames,f:GetName())
    self.browser=f; self.browserMode="all"

    local all=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); all:SetSize(110,24); all:SetPoint("TOPLEFT",20,-32); all:SetText(self:T("ALL_KILLS")); all:SetScript("OnClick",function() A.browserMode="all"; A:RefreshBrowser() end)
    local ses=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); ses:SetSize(110,24); ses:SetPoint("LEFT",all,"RIGHT",8,0); ses:SetText(self:T("SESSION")); ses:SetScript("OnClick",function() A.browserMode="session"; A:RefreshBrowser() end)
    local search=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); search:SetSize(260,28); search:SetPoint("TOPRIGHT",-24,-31); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged",function(self) A.browserSearch=self:GetText() or ""; A:RefreshBrowser() end); search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

    local headers={{self:T("MOB"),28},{self:T("KILLS"),455},{self:T("TYPE"),535},{self:T("LAST_KILL"),650}}
    for _,h in ipairs(headers) do local t=f:CreateFontString(nil,"ARTWORK","GameFontNormal"); t:SetPoint("TOPLEFT",h[2],-78); t:SetText(h[1]) end

    self.browserRows={}
    for i=1,16 do
        local row=CreateFrame("Frame",nil,f); row:SetSize(730,27); row:SetPoint("TOPLEFT",22,-100-(i-1)*28)
        local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,i%2==0 and 0.035 or 0.015)
        row.name=row:CreateFontString(nil,"ARTWORK","GameFontHighlight"); row.name:SetPoint("LEFT",6,0); row.name:SetWidth(410); row.name:SetJustifyH("LEFT")
        row.count=row:CreateFontString(nil,"ARTWORK","GameFontHighlight"); row.count:SetPoint("LEFT",430,0); row.count:SetWidth(70); row.count:SetJustifyH("RIGHT")
        row.type=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); row.type:SetPoint("LEFT",515,0); row.type:SetWidth(105); row.type:SetJustifyH("LEFT")
        row.last=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); row.last:SetPoint("LEFT",630,0); row.last:SetWidth(85); row.last:SetJustifyH("LEFT")
        row:EnableMouse(true)
        row:SetScript("OnEnter",function(self)
            if not self.data or not GameTooltip then return end
            local r=self.data.record
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(r.name or "Unknown",1,0.82,0)
            GameTooltip:AddDoubleLine("NPC ID",tostring(r.npcID or "—"),1,1,1,1,1,1)
            GameTooltip:AddDoubleLine("Account",tostring(r.total or 0),1,1,1,0.2,1,0.2)
            if r.levelMin then GameTooltip:AddDoubleLine("Level",r.levelMin==r.levelMax and tostring(r.levelMin) or (tostring(r.levelMin).."–"..tostring(r.levelMax)),1,1,1,1,1,1) end
            if r.averageXP then GameTooltip:AddDoubleLine(A:T("TOOLTIP_AVG_XP"),string.format("%.1f",r.averageXP),1,1,1,1,0.82,0) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        self.browserRows[i]=row
    end
end

function A:RefreshBrowser()
    if not self.browser or not self.browser:IsShown() then return end
    local records=self:GetBrowserRecords()
    for i,row in ipairs(self.browserRows) do
        local item=records[i]
        if item then
            row.data=item; row.name:SetText(item.record.name or item.key); row.count:SetText(tostring(item.count))
            row.type:SetText(item.record.creatureType or item.record.classification or "—")
            row.last:SetText(RelativeTime(item.record.lastKill)); row:Show()
        else row.data=nil; row:Hide() end
    end
end

function A:ShowBrowser()
    self:CreateBrowser(); self.browser:Show(); self.browser:Raise(); self:RefreshBrowser()
end

function A:RefreshFeature() self:RefreshFeatureOptions(); self:RefreshBrowser() end

function A:InitializeFeature()
    self:HookTooltips()
    self.lastXP=type(UnitXP)=="function" and tonumber(UnitXP("player")) or 0
    local f=CreateFrame("Frame"); self.eventFrame=f
    local events={"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_XP_UPDATE","PLAYER_DEAD","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","PLAYER_ENTERING_WORLD"}
    for _,ev in ipairs(events) do pcall(f.RegisterEvent,f,ev) end
    f:SetScript("OnEvent",function(_,ev,arg)
        if ev=="COMBAT_LOG_EVENT_UNFILTERED" then A:HandleCombatLog()
        elseif ev=="PLAYER_XP_UPDATE" then A:HandleXPUpdate()
        elseif ev=="PLAYER_DEAD" and A.db and A.db.kills.trackDeaths and type(ComfyData)=="table" then ComfyData:RecordDeath({time=Epoch()}); A:RefreshFeature()
        elseif ev=="PLAYER_TARGET_CHANGED" then A:CaptureUnit("target")
        elseif ev=="UPDATE_MOUSEOVER_UNIT" then A:CaptureUnit("mouseover")
        elseif ev=="NAME_PLATE_UNIT_ADDED" and arg then A:CaptureUnit(arg)
        elseif ev=="PLAYER_ENTERING_WORLD" then A:CaptureUnit("target") end
    end)
end

function A:BuildGeneralOptions(page,ui)
    ui.CreateCheck(page,self:T("SHOW_TOOLTIP"),20,-95,function() return A.db.kills.showTooltip end,function(v) A.db.kills.showTooltip=v end)
    ui.CreateCheck(page,self:T("TRACK_DEATHS"),20,-130,function() return A.db.kills.trackDeaths end,function(v) A.db.kills.trackDeaths=v end)
    ui.CreateCheck(page,self:T("COUNT_PET"),20,-165,function() return A.db.kills.countPetKills end,function(v) A.db.kills.countPetKills=v end)
    ui.CreateCheck(page,self:T("MILESTONES"),20,-200,function() return A.db.kills.milestoneNotifications end,function(v) A.db.kills.milestoneNotifications=v end)
    ui.CreateButton(page,self:T("OPEN_DATABASE"),20,-255,180,function() A:ShowBrowser() end)
    local h=page:CreateFontString(nil,"ARTWORK","GameFontNormal"); h:SetPoint("TOPLEFT",20,-325); h:SetText(self:T("DATABASE"))
    self.summaryText=page:CreateFontString(nil,"ARTWORK","GameFontHighlight"); self.summaryText:SetPoint("TOPLEFT",20,-355); self.summaryText:SetWidth(650); self.summaryText:SetJustifyH("LEFT")
    local n=page:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); n:SetPoint("TOPLEFT",20,-415); n:SetWidth(680); n:SetJustifyH("LEFT"); n:SetText(self:T("FOREVER_NOTE"))
end
