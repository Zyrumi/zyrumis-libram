-- Zyrumi's Libram: threat
-- Small icons for tanks, only while you are in combat:
--   green shield       the mob is yours
--   half shield        yours, but someone is about to take it
--   red warning + name not yours: who it is on
-- One above the name of each enemy nameplate in the fight, and one on the
-- corner of your target's portrait. Hover the target's icon for the
-- numbers (your lead over the next person, or your share of the holder's
-- threat). Bosses: the game hides their threat numbers, icons still work.
--
-- Solo, a mob on you is no news, so nothing shows then.
-- When you are not the tank, the warning marks mobs that are on you (in a
-- group), and the half shield your target when you are close to pulling it.

local ADDON_NAME, root = ...

local Threat = {}
root.Threat = Threat

local IsSecret = root.IsSecret
local TICK = 0.25
local MEDIA = "Interface\\AddOns\\ZyrumisLibram\\Media\\"
local ICONS = {
    mine = MEDIA .. "ThreatMine",
    slipping = MEDIA .. "ThreatSlipping",
    loose = MEDIA .. "ThreatLoose",
}
local CLOSE = 90 -- not the tank: warn at this share of the tank's threat

local plates = {}   -- [nameplate unit] = true while shown
local markers = {}  -- [plate frame] = our marker on it
local badge         -- the icon on the target's portrait
local ticker

-------------------------------------------------------------------------------
-- Reading the game
-------------------------------------------------------------------------------

local function Num(v)
    if type(v) == "number" and not IsSecret(v) then
        return v
    end
    return nil
end

local function Bool(fn, ...)
    if type(fn) ~= "function" then
        return false
    end
    local ok, v = pcall(fn, ...)
    return ok and not IsSecret(v) and v == true
end

-- 0..3 (3 = you hold it securely, 2 = you hold it but are about to lose
-- it, 1 = not yours but above the holder, 0 = not yours), or nil when the
-- unit is not on the mob's threat list or the game hides it.
local function State(unit, mob)
    if type(UnitThreatSituation) ~= "function" then
        return nil
    end
    local ok, s = pcall(UnitThreatSituation, unit, mob)
    return ok and Num(s) or nil
end

-- Your threat as a percentage of the next person's, while you hold it.
local function LeadPercent(mob)
    if type(UnitThreatPercentageOfLead) ~= "function" then
        return nil
    end
    local ok, v = pcall(UnitThreatPercentageOfLead, "player", mob)
    v = ok and Num(v) or nil
    if v and v > 0 then
        return v
    end
    return nil
end

-- Your threat as a percentage of the holder's.
local function SharePercent(mob)
    if type(UnitDetailedThreatSituation) ~= "function" then
        return nil
    end
    local ok, _, _, _, rawPct = pcall(UnitDetailedThreatSituation, "player", mob)
    return ok and Num(rawPct) or nil
end

-- Everyone whose threat counts: you, your pet, your party and their pets
-- (in a raid: the raid members, without pets, to keep it light).
function Threat.GroupUnits()
    local list = { "player", "pet" }
    if Bool(IsInRaid) then
        for i = 1, 40 do
            list[#list + 1] = "raid" .. i
        end
    else
        for i = 1, 4 do
            list[#list + 1] = "party" .. i
            list[#list + 1] = "partypet" .. i
        end
    end
    return list
end

local function ShortName(unit)
    local ok, name = pcall(UnitName, unit)
    if ok and type(name) == "string" and not IsSecret(name) then
        return name
    end
    return nil
end

-- The name of whoever in your group holds the mob (not you), or nil.
local function Holder(mob)
    for _, unit in ipairs(Threat.GroupUnits()) do
        if unit ~= "player" and Bool(UnitExists, unit) and not Bool(UnitIsUnit, unit, "player") then
            local s = State(unit, mob)
            if s and s >= 2 then
                return ShortName(unit) or "someone"
            end
        end
    end
    return nil
end

local TANK_FORMS = { [5] = true, [8] = true, [18] = true } -- bear, dire bear, defensive stance
local RIGHTEOUS_FURY = 25780

-- True when you are playing as a tank: the game says so, your group role
-- is tank, or you are in a tanking form or have Righteous Fury up.
function Threat.IsTank()
    if root.TankMode and root.TankMode.IsTank() then
        return true
    end
    if PlayerUtil and Bool(PlayerUtil.IsPlayerEffectivelyTank) then
        return true
    end
    if type(UnitGroupRolesAssigned) == "function" then
        local ok, role = pcall(UnitGroupRolesAssigned, "player")
        if ok and not IsSecret(role) and role == "TANK" then
            return true
        end
    end
    if type(GetShapeshiftFormID) == "function" then
        local ok, form = pcall(GetShapeshiftFormID)
        form = ok and Num(form) or nil
        if form and TANK_FORMS[form] then
            return true
        end
    end
    local get = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if get then
        local ok, aura = pcall(get, RIGHTEOUS_FURY)
        if ok and aura ~= nil and not IsSecret(aura) then
            return true
        end
    end
    return false
end

local function Grouped()
    return Bool(IsInGroup) or Bool(IsInRaid)
end

-- What to show for one enemy: kind ("mine", "slipping", "loose") and the
-- name of who has it (loose only, when known), or nil for nothing.
function Threat.MobState(mob, tank, grouped)
    if not Bool(UnitCanAttack, "player", mob) or Bool(UnitIsDead, mob) then
        return nil
    end
    local mine = State("player", mob)
    if mine and mine >= 2 then
        if not tank then
            return grouped and "loose" or nil
        end
        if mine == 2 then
            return "slipping"
        end
        return grouped and "mine" or nil
    end
    if not tank then
        return nil
    end
    local who = Holder(mob)
    if who then
        return "loose", who
    end
    if mine ~= nil then
        -- you are on its list, but it is on someone outside your group
        return "loose"
    end
    return nil
end

-- The target's icon: kind and the tooltip line, or nil.
function Threat.TargetState(tank, grouped)
    if not Bool(UnitExists, "target") then
        return nil
    end
    local kind, who = Threat.MobState("target", tank, grouped)
    if not tank and not kind and grouped then
        local share = SharePercent("target")
        if share and share >= CLOSE and State("player", "target") then
            return "slipping", ("Your threat: %d%% of the tank's. Close to pulling it."):format(math.floor(share + 0.5))
        end
    end
    if not kind then
        return nil
    end
    local lead = LeadPercent("target")
    if kind == "mine" then
        if lead then
            return kind, ("Yours, %d%% ahead of the next person."):format(math.floor(lead - 100 + 0.5))
        end
        return kind, "Yours."
    elseif kind == "slipping" then
        return kind, "Yours, but someone is about to take it."
    end
    if not tank then
        return kind, "It is attacking you."
    end
    local share = SharePercent("target")
    local text = who and ("On " .. who .. ".") or "Not on you."
    if share then
        text = text .. (" Your threat: %d%% of theirs."):format(math.floor(share + 0.5))
    end
    return kind, text
end

-------------------------------------------------------------------------------
-- Display
-------------------------------------------------------------------------------

local function PlateFrame(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and type(plate) == "table" then
        return plate
    end
    return nil
end

local function Field(t, key)
    if type(t) ~= "table" then
        return nil
    end
    local v = rawget(t, key)
    if type(v) == "table" then
        return v
    end
    return nil
end

-- Above the name when the plate has the usual layout, else above the plate.
local function MarkerFor(plate)
    local m = markers[plate]
    if m then
        return m
    end
    m = CreateFrame("Frame", nil, plate)
    m:SetSize(16, 16)
    m:EnableMouse(false)
    local uf = Field(plate, "UnitFrame")
    local name = Field(uf, "name")
    local bar = Field(uf, "healthBar") or Field(Field(uf, "HealthBarsContainer"), "healthBar")
    if name then
        m:SetPoint("BOTTOM", name, "TOP", 0, 1)
    elseif bar then
        m:SetPoint("BOTTOM", bar, "TOP", 0, 14)
    else
        m:SetPoint("BOTTOM", plate, "TOP", 0, 0)
    end
    m.icon = m:CreateTexture(nil, "OVERLAY")
    m.icon:SetAllPoints()
    m.who = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    m.who:SetPoint("LEFT", m, "RIGHT", 2, 0)
    if m.who.SetFont and STANDARD_TEXT_FONT then
        m.who:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    end
    m.who:SetTextColor(1, 0.45, 0.45)
    markers[plate] = m
    return m
end

local function TargetAnchor()
    local tf = rawget(_G, "TargetFrame")
    if type(tf) ~= "table" then
        return nil
    end
    local portrait = Field(Field(tf, "TargetFrameContainer"), "Portrait") or Field(tf, "portrait")
    return tf, portrait
end

local function CreateBadge()
    local tf, portrait = TargetAnchor()
    badge = CreateFrame("Frame", "ZyrumisLibramTargetThreat", tf or UIParent)
    badge:SetSize(22, 22)
    if tf then
        -- Above the name bar, where the game's own threat percentage goes.
        badge:SetPoint("BOTTOM", tf, "TOP", -28, -33)
    elseif portrait then
        badge:SetPoint("CENTER", portrait, "TOPRIGHT", -4, -4)
    else
        badge:SetPoint("TOP", UIParent, "TOP", 0, -140)
    end
    badge:SetFrameStrata("MEDIUM")
    badge:SetFrameLevel(((tf and tf.GetFrameLevel and tf:GetFrameLevel()) or 1) + 10)
    local bg = badge:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetAllPoints()
    badge.icon = badge:CreateTexture(nil, "ARTWORK")
    badge.icon:SetSize(16, 16)
    badge.icon:SetPoint("CENTER")
    badge:EnableMouse(true)
    badge:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Threat", 1, 1, 1)
        if self.tip then
            GameTooltip:AddLine(self.tip, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    badge:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    badge:Hide()
end

local function HideAll()
    for _, m in pairs(markers) do
        m:Hide()
    end
    if badge then
        badge:Hide()
    end
end

function Threat.Update()
    if not root.FeatureOn("threat") then
        HideAll()
        return
    end
    local tank, grouped = Threat.IsTank(), Grouped()

    -- nameplates
    local used = {}
    for unit in pairs(plates) do
        local plate = PlateFrame(unit)
        if plate then
            local kind, who = Threat.MobState(unit, tank, grouped)
            if kind then
                local m = MarkerFor(plate)
                m.icon:SetTexture(ICONS[kind])
                m.who:SetText(kind == "loose" and who or "")
                m:Show()
                used[plate] = true
            end
        end
    end
    for plate, m in pairs(markers) do
        if not used[plate] then
            m:Hide()
        end
    end

    -- target
    local kind, tip = Threat.TargetState(tank, grouped)
    if kind then
        if not badge then
            CreateBadge()
        end
        badge.icon:SetTexture(ICONS[kind])
        badge.kind, badge.tip = kind, tip
        badge:Show()
    elseif badge then
        badge.kind, badge.tip = nil, nil
        badge:Hide()
    end
end

local function SafeUpdate()
    local ok, err = pcall(Threat.Update)
    if not ok then
        HideAll()
        if not Threat.warned then
            Threat.warned = true
            root.Print("threat: " .. tostring(err))
        end
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

-- Runs only while you are in combat; out of combat everything is hidden.
local function Start()
    if not ticker and C_Timer and C_Timer.NewTicker then
        ticker = C_Timer.NewTicker(TICK, SafeUpdate)
    end
    SafeUpdate()
end

local function Stop()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    HideAll()
end

local function InCombat()
    return Bool(UnitAffectingCombat, "player") or Bool(InCombatLockdown)
end

root.OnFeatureChanged("threat", function(on)
    if on and InCombat() then
        Start()
    else
        Stop()
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" and type(unit) == "string" then
        plates[unit] = true
    elseif event == "NAME_PLATE_UNIT_REMOVED" and type(unit) == "string" then
        plates[unit] = nil
        local plate = PlateFrame(unit)
        if plate and markers[plate] then
            markers[plate]:Hide()
        end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        Stop()
        return
    end
    if not root.FeatureOn("threat") then
        return
    end
    if event == "PLAYER_REGEN_DISABLED" or (event == "PLAYER_LOGIN" and InCombat()) then
        Start()
    elseif ticker then
        SafeUpdate()
    end
end)
