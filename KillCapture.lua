ComfyKills = ComfyKills or {}
local A = ComfyKills

-- WoW Forever playtest fix:
-- PARTY_KILL is not reliable enough on its own in the current client. Keep the
-- normal PARTY_KILL path, but remember damage done by the player/pet and use a
-- short UNIT_DIED fallback while solo. Every creature GUID is de-duplicated so
-- PARTY_KILL + UNIT_DIED can never count the same mob twice.
A.version = "0.5"
A.buildDate = "04.10.2026"
A.recentKillCredit = A.recentKillCredit or {}
A.recentRecordedKills = A.recentRecordedKills or {}

local DAMAGE_EVENTS = {
    SWING_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true,
    SPELL_INSTAKILL = true,
}

local function Now()
    if type(GetTimePreciseSec) == "function" then
        local ok, value = pcall(GetTimePreciseSec)
        if ok and type(value) == "number" then return value end
    end
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and type(value) == "number" then return value end
    end
    return 0
end

local function SafeEqual(a, b)
    if a == nil or b == nil then return false end
    local ok, equal = pcall(function() return a == b end)
    return ok and equal and true or false
end

local function CurrentXP()
    if type(UnitXP) ~= "function" then return nil end
    local ok, value = pcall(UnitXP, "player")
    return ok and tonumber(value) or nil
end

local function CurrentXPMax()
    if type(UnitXPMax) ~= "function" then return nil end
    local ok, value = pcall(UnitXPMax, "player")
    return ok and tonumber(value) or nil
end

local function IsInGroupSafe()
    if type(IsInGroup) == "function" then
        local ok, value = pcall(IsInGroup)
        if ok then return value and true or false end
    end
    if type(GetNumGroupMembers) == "function" then
        local ok, value = pcall(GetNumGroupMembers)
        if ok and tonumber(value) then return tonumber(value) > 0 end
    end
    return false
end

function A:IsOurKillSource(sourceGUID)
    if not sourceGUID or type(UnitGUID) ~= "function" then return false end

    local playerGUID
    local okPlayer, valuePlayer = pcall(UnitGUID, "player")
    if okPlayer then playerGUID = valuePlayer end
    if SafeEqual(sourceGUID, playerGUID) then return true end

    if self.db and self.db.kills and self.db.kills.countPetKills then
        local petGUID
        local okPet, valuePet = pcall(UnitGUID, "pet")
        if okPet then petGUID = valuePet end
        if SafeEqual(sourceGUID, petGUID) then return true end
    end

    return false
end

function A:RememberKillCredit(sourceGUID, destGUID, destName)
    if not destGUID or not self:IsOurKillSource(sourceGUID) then return end
    self.recentKillCredit[destGUID] = {
        at = Now(),
        sourceGUID = sourceGUID,
        name = destName,
    }
end

function A:PruneKillCaptureCache(now)
    now = tonumber(now) or Now()
    for guid, entry in pairs(self.recentKillCredit or {}) do
        if type(entry) ~= "table" or now - (tonumber(entry.at) or 0) > 20 then
            self.recentKillCredit[guid] = nil
        end
    end
    for guid, stamp in pairs(self.recentRecordedKills or {}) do
        if now - (tonumber(stamp) or 0) > 30 then
            self.recentRecordedKills[guid] = nil
        end
    end
end

function A:RecordKillOnce(sourceGUID, destGUID, destName)
    if not destGUID or not self:IsOurKillSource(sourceGUID) then return false end

    local now = Now()
    local previous = self.recentRecordedKills[destGUID]
    if previous and now - previous < 10 then return false end

    self.recentRecordedKills[destGUID] = now
    self.recentKillCredit[destGUID] = nil

    -- RecordKill remains the single database writer. This keeps milestones,
    -- ComfyData account/character/session counters and XP attribution intact.
    self:RecordKill(sourceGUID, destGUID, destName)
    self:PruneKillCaptureCache(now)
    return true
end

function A:HandleCombatLog()
    if type(CombatLogGetCurrentEventInfo) ~= "function" then return end

    local ok, data = pcall(function() return {CombatLogGetCurrentEventInfo()} end)
    if not ok or type(data) ~= "table" then return end

    local event = data[2]
    local sourceGUID = data[4]
    local destGUID = data[8]
    local destName = data[9]

    if DAMAGE_EVENTS[event] then
        self:RememberKillCredit(sourceGUID, destGUID, destName)
        return
    end

    if event == "PARTY_KILL" then
        -- Preferred path: the client explicitly credits the player/pet.
        if self:IsOurKillSource(sourceGUID) then
            self:RecordKillOnce(sourceGUID, destGUID, destName)
        end
        return
    end

    if event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "PARTY_KILL_FALLBACK" then
        -- Forever fallback. Restrict it to solo play so damage assists in a
        -- group cannot inflate the kill database.
        if IsInGroupSafe() then return end
        local credit = destGUID and self.recentKillCredit[destGUID]
        if credit and (Now() - (tonumber(credit.at) or 0)) <= 12 then
            self:RecordKillOnce(credit.sourceGUID, destGUID, destName or credit.name)
        end
    end
end

-- XP attribution is deliberately tolerant of event order. Forever can deliver
-- PLAYER_XP_UPDATE immediately around the combat-log death event, so keep one
-- very recent unassigned XP gain and attach it to the next recorded kill.
local OriginalRecordKill = A.RecordKill
function A:RecordKill(sourceGUID, destGUID, destName)
    if type(OriginalRecordKill) ~= "function" then return end
    OriginalRecordKill(self, sourceGUID, destGUID, destName)

    if self.pendingKillKey and self._unassignedKillXP and self._unassignedKillXPAt
        and Now() - self._unassignedKillXPAt <= 1.5 then
        if type(ComfyData) == "table" and type(ComfyData.RecordKillXP) == "function" then
            ComfyData:RecordKillXP(self.pendingKillKey, self._unassignedKillXP)
        end
        self._unassignedKillXP = nil
        self._unassignedKillXPAt = nil
        self.pendingKillKey = nil
    end
end

function A:HandleXPUpdate()
    local current = CurrentXP()
    local currentMax = CurrentXPMax()
    if current == nil then return end

    local previous = tonumber(self.lastXP)
    local previousMax = tonumber(self.lastXPMax)
    local delta

    if previous ~= nil then
        if current >= previous then
            delta = current - previous
        elseif previousMax and previousMax > previous then
            -- Level-up rollover: remaining XP in the old level + XP already
            -- present in the new level.
            delta = (previousMax - previous) + current
        end
    end

    self.lastXP = current
    self.lastXPMax = currentMax

    if not delta or delta <= 0 then return end

    local now = Now()
    if self.pendingKillKey and now - (tonumber(self.pendingKillAt) or 0) <= 5 then
        if type(ComfyData) == "table" and type(ComfyData.RecordKillXP) == "function" then
            ComfyData:RecordKillXP(self.pendingKillKey, delta)
        end
        self.pendingKillKey = nil
        self._unassignedKillXP = nil
        self._unassignedKillXPAt = nil
    else
        self._unassignedKillXP = delta
        self._unassignedKillXPAt = now
    end
end

-- Initialize the XP baseline after the original feature setup has run.
local OriginalInitializeFeature = A.InitializeFeature
function A:InitializeFeature()
    if type(OriginalInitializeFeature) == "function" then
        OriginalInitializeFeature(self)
    end
    self.lastXP = CurrentXP()
    self.lastXPMax = CurrentXPMax()
end
