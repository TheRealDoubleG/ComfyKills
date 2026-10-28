-- Standalone tests for modern WoW Forever PARTY_KILL events (Lua 5.1+).
local root = arg[1] or "."
local now = 100
time=function() return now end
GetTime=function() return now end
UnitGUID=function(unit)
    if unit=="player" then return "Player-123-456" end
    if unit=="pet" then return "Pet-123-789" end
end
UnitXP=function() return 20 end
local frames={}
CreateFrame=function()
    local f={events={},scripts={}}
    function f:RegisterEvent(e)
        if e=="COMBAT_LOG_EVENT_UNFILTERED" then error("restricted event used") end
        self.events[e]=true
    end
    function f:SetScript(e,fn) self.scripts[e]=fn end
    frames[#frames+1]=f
    return f
end
local kills={}
local nDeaths=0
ComfyData={
    RecordKill=function(_,record)
        local k="npc:"..tostring(record.npcID or "unknown")
        local r=kills[k] or {total=0,name=record.name}
        r.total=r.total+1
        kills[k]=r
        return k,r
    end,
    RecordDeath=function()
        nDeaths=nDeaths+1
    end,
}
ComfyKills={unitCache={}}
local A=ComfyKills
A.db={enabled=true,kills={countPetKills=true,milestoneNotifications=false,trackDeaths=true}}
A.Print=function() end
assert(loadfile(root.."/Kills.lua"))()
A:InitializeFeature()
local f=assert(A.eventFrame)
local checked=0
local function check(pred,reason)
    checked=checked+1
    assert(pred,"Check "..checked..": "..reason)
end
local function emit(e,...)
    check(f.events[e]==true,"event registered: "..e)
    f.scripts.OnEvent(f,e,...)
end
check(not f.events.COMBAT_LOG_EVENT_UNFILTERED,"no forbidden combat log")
local g1="Creature-0-1-2-3-1234-00000001"
local g2="Creature-0-1-2-3-5678-00000002"
A.unitCache[g1]={name="Kobold",level=10}
A.unitCache[g2]={name="Gnoll",level=11}
emit("PARTY_KILL","Player-123-456",g1)
check(kills["npc:1234"].total==1,"player kill counted once")
now=101
emit("PARTY_KILL","Player-123-456",g1)
check(kills["npc:1234"].total==1,"duplicate GUID suppressed")
now=102
emit("PARTY_KILL","Pet-123-789",g2)
check(kills["npc:5678"].total==1,"pet kill counted")
now=103
emit("PARTY_KILL","Player-OTHER",g2)
check(kills["npc:5678"].total==1,"other attacker excluded")
emit("PLAYER_DEAD")
check(nDeaths==0,"ComfyKills does not double-count ComfyData deaths")
A.db.kills.countPetKills=false
now=104
local g3="Creature-0-1-2-3-9999-00000003"
emit("PARTY_KILL","Pet-123-789",g3)
check(kills["npc:9999"]==nil,"pet optout respected")
now=135
emit("PARTY_KILL","Player-123-456",g1)
check(kills["npc:1234"].total==2,"expired dedupe window permits event")
check(#A.recentKillOrder==3,"bounded dedupe ledger records accepted kills")
-- When player/pet GUIDs cannot be resolved, missing attacker GUID must
-- NOT compare equal to a missing player GUID (nil == nil).
local oldUnitGUID=UnitGUID
local ghost="Creature-0-1-2-3-7777-00000077"
UnitGUID=function() return nil end
check(not A:RecordKill(nil,ghost,"Ghost"),"unresolved GUID cannot authorize unknown killer")
check(kills["npc:7777"]==nil,"no ghost kill written")
check(not A:RecordKill("",ghost,"Ghost"),"empty attacker excluded")
check(kills["npc:7777"]==nil,"empty attacker did not mutate counters")
UnitGUID=oldUnitGUID
check(not A:RecordKill(nil,ghost,"Ghost"),"nil attacker rejected even with valid player GUID")
check(not A:RecordKill("Other-999",ghost,"Ghost"),"other attacker rejected")
check(A:RecordKill("Player-123-456",ghost,"Ghost"),"valid attacker still accepted")
check(kills["npc:7777"].total==1,"authorized kill stored once")
print("PASS: "..checked.." direct kill and death interoperability checks")
