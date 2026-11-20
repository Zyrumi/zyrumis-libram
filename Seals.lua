-- Zyrumi's Libram: seal and judgement timers
-- A small strip shown during fights:
--   your seal and how long it has left, or "No seal" when none is up
--   your judgement on the target and how long it has left
-- In combat the game hides most aura details from addons, so the times come
-- from your own casts (cast events stay readable): a seal lasts 30 seconds
-- and is only replaced by casting a seal (judging doesn't end it on
-- Forever). Out of combat the real times are read from your buffs, and a
-- judgement's real length is learned whenever the game shows it.

local ADDON_NAME, root = ...

local Seals = {}
root.Seals = Seals

local IsSecret, Safe = root.IsSecret, root.Safe

local SEAL_TIME = 30
local JUDGEMENT_TIME = 10 -- until the real length has been seen once
local JUDGEMENT = { 20271, "Judgement" }

-- Seals (rank 1 IDs). debuff: the judgement it leaves on the target.
local SEALS = {
    { 21084, "Seal of Righteousness", short = "Right." },
    { 21082, "Seal of the Crusader", short = "Crus.", debuff = { 21183, "Judgement of the Crusader" } },
    { 20375, "Seal of Command", short = "Comm." },
    { 20164, "Seal of Justice", short = "Just.", debuff = { 20184, "Judgement of Justice" } },
    { 20165, "Seal of Light", short = "Light", debuff = { 20185, "Judgement of Light" } },
    { 20166, "Seal of Wisdom", short = "Wisd.", debuff = { 20186, "Judgement of Wisdom" } },
}
Seals.SEALS = SEALS

local seal      -- { s = SEALS entry, name, ends }
local judged    -- { debuffName, icon, ends, guid }
local frame
local elapsed = 0

local function SealName(s)
    return root.SpellName(s[1]) or s[2]
end

local function SealByName(name)
    if type(name) ~= "string" then
        return nil
    end
    for _, s in ipairs(SEALS) do
        if SealName(s) == name then
            return s
        end
    end
    return nil
end

local function Learned()
    root.db.learned = type(root.db.learned) == "table" and root.db.learned or {}
    return root.db.learned
end

local function TargetGUID()
    local g = Safe(UnitGUID, "target")
    return type(g) == "string" and g or nil
end

-------------------------------------------------------------------------------
-- What the casts tell us
-------------------------------------------------------------------------------

function Seals.OnCast(spellID)
    if IsSecret(spellID) or type(spellID) ~= "number" then
        return
    end
    local name = root.SpellName(spellID)
    if not name then
        return
    end
    local s = SealByName(name)
    -- Seal of Command's hits use a spell of the same name that isn't in
    -- your spell book; only real casts start the timer.
    if s and root.IsPlayerSpell(spellID) then
        seal = { s = s, name = name, ends = GetTime() + SEAL_TIME }
        return
    end
    if name == (root.SpellName(JUDGEMENT[1]) or JUDGEMENT[2]) then
        local current = seal and seal.ends > GetTime() and seal.s
        if current and current.debuff then
            local dName = root.SpellName(current.debuff[1]) or current.debuff[2]
            local len = Learned()[dName] or JUDGEMENT_TIME
            judged = { debuffName = dName, icon = root.SpellIcon(dName), ends = GetTime() + len, guid = TargetGUID() }
        end
    end
end

-- Out of combat (or whenever the game allows), read the real times.
local function ReadAuras()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return
    end
    -- your seal
    local found
    for _, s in ipairs(SEALS) do
        local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", SealName(s), "HELPFUL")
        if not ok or IsSecret(a) then
            return -- hidden: keep what the casts said
        end
        if type(a) == "table" then
            local exp = a.expirationTime
            if not IsSecret(exp) and type(exp) == "number" then
                found = { s = s, name = SealName(s), ends = exp > 0 and exp or (GetTime() + SEAL_TIME) }
            end
        end
    end
    seal = found
    -- your judgement on the target: learn its real length
    if judged then
        local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, "target", judged.debuffName, "HARMFUL")
        if ok and type(a) == "table" and not IsSecret(a) then
            local dur, exp, src = a.duration, a.expirationTime, a.sourceUnit
            if not IsSecret(dur) and not IsSecret(exp) and not IsSecret(src) and src == "player"
                and type(dur) == "number" and dur > 0 then
                Learned()[judged.debuffName] = dur
                judged.ends = exp
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Display
-------------------------------------------------------------------------------

local function Slot(parent, x)
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(30, 30)
    s:SetPoint("LEFT", x, 0)
    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetAllPoints()
    s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    s.edge = s:CreateTexture(nil, "BACKGROUND")
    s.edge:SetPoint("TOPLEFT", -2, 2)
    s.edge:SetPoint("BOTTOMRIGHT", 2, -2)
    s.edge:SetColorTexture(0, 0, 0, 0.8)
    s.text = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    s.text:SetPoint("LEFT", s, "RIGHT", 6, 0)
    s.text:SetJustifyH("LEFT")
    return s
end

local function Create()
    frame = CreateFrame("Frame", "ZyrumisLibramSeals", UIParent)
    frame:SetSize(210, 30)
    frame:EnableMouse(false)
    frame.seal = Slot(frame, 0)
    frame.judge = Slot(frame, 110)
    frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.1 then
            elapsed = 0
            Seals.Draw()
        end
    end)
    root.RegisterMover(frame, "seals", "Seal and judgement", { "CENTER", UIParent, "CENTER", 0, -170 })
    frame:Hide()
end

local function ShowWanted()
    if not root.FeatureOn("seals") then
        return false
    end
    return root.unlocked or root.db.sealsAlways == true or root.InCombat()
end

function Seals.Draw()
    if not frame then
        return
    end
    local now = GetTime()
    -- seal
    local s = frame.seal
    if seal and seal.ends > now then
        s.icon:SetTexture(root.SpellIcon(seal.name))
        s.icon:SetDesaturated(false)
        s.edge:SetColorTexture(0, 0, 0, 0.8)
        local left = seal.ends - now
        s.text:SetText(("%s %d"):format(seal.s.short, math.ceil(left)))
        if left <= 5 then
            s.text:SetTextColor(1, 0.82, 0) -- about to drop (the number says so too)
        else
            s.text:SetTextColor(1, 1, 1)
        end
    else
        s.icon:SetTexture(seal and root.SpellIcon(seal.name) or root.SpellIcon(SealName(SEALS[1])))
        s.icon:SetDesaturated(true)
        s.edge:SetColorTexture(0.9, 0.1, 0.1, 1)
        s.text:SetText("No seal")
        s.text:SetTextColor(1, 0.35, 0.35)
    end
    -- judgement
    local j = frame.judge
    local show = root.db.sealsJudgement ~= false
    j:SetShown(show)
    if show then
        local g = TargetGUID()
        if judged and judged.ends > now and (not judged.guid or not g or g == judged.guid) then
            j.icon:SetTexture(judged.icon)
            j.icon:SetDesaturated(false)
            j.text:SetText(("Judged %d"):format(math.ceil(judged.ends - now)))
            j.text:SetTextColor(1, 1, 1)
        else
            j.icon:SetTexture(root.SpellIcon(root.SpellName(JUDGEMENT[1]) or JUDGEMENT[2]))
            j.icon:SetDesaturated(true)
            j.text:SetText("Not judged")
            j.text:SetTextColor(0.75, 0.75, 0.75)
        end
    end
end

function Seals.Update()
    if not root.IsPaladin() then
        return
    end
    if not frame then
        if not root.FeatureOn("seals") then
            return
        end
        Create()
    end
    if ShowWanted() then
        frame:Show()
        Seals.Draw()
    else
        frame:Hide()
    end
end

root.OnFeatureChanged("seals", function()
    Seals.Update()
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if not root.db or not root.IsPaladin() then
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        pcall(Seals.OnCast, spellID)
        return
    end
    if event == "UNIT_AURA" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_ENABLED" then
        if not root.InCombat() then
            pcall(ReadAuras)
        end
    end
    local ok, err = pcall(Seals.Update)
    if not ok and not Seals.warned then
        Seals.warned = true
        root.Print("seal timer: " .. tostring(err))
    end
end)
