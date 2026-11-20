-- Zyrumi's Libram: healer mana after combat
-- When a fight ends and you are tanking in a group, a warning in the middle
-- of the screen if a healer is under 20% mana, so you wait before the next
-- pull: "Healer low on mana: Holly 14%".
-- Healers are the people with the healer group role; nobody is guessed.
--
-- The game can hide other players' mana from addons (a secret value) while
-- still drawing it on screen. Then the addon can't tell who is low, so it
-- gives each healer a line on screen and lets the game decide: a step colour
-- curve makes the line fully see-through at 20% mana or more, so only low
-- healers show. Nothing is guessed either way.

local ADDON_NAME, root = ...

local HealerMana = {}
root.HealerMana = HealerMana

local IsSecret = root.IsSecret

local LOW = 0.20
local MANA = 0 -- Enum.PowerType.Mana
local SETTLE = 0.5 -- seconds after combat before reading: values can still be hidden right at the end
local SHOW_FOR = 6 -- seconds the on-screen lines stay up
local MAX_LINES = 5
local WARN = { 1, 0.28, 0 } -- raid warning orange

local function Get(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, v = pcall(fn, ...)
    if not ok or IsSecret(v) then
        return nil
    end
    return v
end

local function Units()
    local list = {}
    if Get(IsInRaid) then
        for i = 1, 40 do
            list[#list + 1] = "raid" .. i
        end
    elseif Get(IsInGroup) then
        for i = 1, 4 do
            list[#list + 1] = "party" .. i
        end
    end
    return list
end

-- Mana as 0-1, or nil when the game hides it (or they have none).
local function PlainMana(unit)
    local cur, max = Get(UnitPower, unit, MANA), Get(UnitPowerMax, unit, MANA)
    if type(cur) == "number" and type(max) == "number" and max > 0 then
        return cur / max
    end
    return nil
end

-- Healers you can see: list of { unit, name, mana (0-1 or nil when hidden) }.
local function Healers()
    local list = {}
    for _, unit in ipairs(Units()) do
        if Get(UnitExists, unit) and not Get(UnitIsUnit, unit, "player")
            and Get(UnitGroupRolesAssigned, unit) == "HEALER"
            and Get(UnitIsConnected, unit) and not Get(UnitIsDeadOrGhost, unit) then
            local name = Get(UnitName, unit)
            if type(name) == "string" then
                list[#list + 1] = { unit = unit, name = name, mana = PlainMana(unit) }
            end
        end
    end
    return list
end

-- Healers under 20% mana whose mana can be read: list of { name, percent },
-- lowest first.
function HealerMana.LowHealers()
    local low = {}
    for _, h in ipairs(Healers()) do
        if h.mana and h.mana < LOW then
            low[#low + 1] = { name = h.name, percent = math.floor(h.mana * 100) }
        end
    end
    table.sort(low, function(a, b) return a.percent < b.percent end)
    return low
end

function HealerMana.Text(low)
    local parts = {}
    for _, h in ipairs(low) do
        parts[#parts + 1] = ("%s %d%%"):format(h.name, h.percent)
    end
    return (#low == 1 and "Healer low on mana: " or "Healers low on mana: ") .. table.concat(parts, ", ")
end

local function Show(text)
    if RaidNotice_AddMessage and RaidWarningFrame then
        local color = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] or { r = WARN[1], g = WARN[2], b = WARN[3] }
        RaidNotice_AddMessage(RaidWarningFrame, text, color)
    elseif UIErrorsFrame then
        UIErrorsFrame:AddMessage(text, WARN[1], WARN[2], WARN[3])
    end
end

-------------------------------------------------------------------------------
-- Lines the game fills in when mana is hidden
-------------------------------------------------------------------------------

local curves -- { low = shows only under 20%, always = always shows }

local function Curves()
    if curves ~= nil then
        return curves or nil
    end
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor and Enum and Enum.LuaCurveType
        and CurveConstants and CurveConstants.ScaleTo100 and type(UnitPowerPercent) == "function") then
        return nil
    end
    curves = false
    local ok, made = pcall(function()
        local low = C_CurveUtil.CreateColorCurve()
        low:SetType(Enum.LuaCurveType.Step)
        low:AddPoint(0, CreateColor(WARN[1], WARN[2], WARN[3], 1))
        low:AddPoint(LOW, CreateColor(WARN[1], WARN[2], WARN[3], 0))
        local always = C_CurveUtil.CreateColorCurve()
        always:SetType(Enum.LuaCurveType.Step)
        always:AddPoint(0, CreateColor(1, 0.82, 0, 1))
        return { low = low, always = always }
    end)
    if ok then
        curves = made
    end
    return curves or nil
end

local frame, lines, hideAt

local function HideLines()
    hideAt = nil
    if frame then
        frame:Hide()
    end
end

local function CreateLines()
    frame = CreateFrame("Frame", "ZyrumisLibramHealerMana", UIParent)
    frame:SetSize(500, MAX_LINES * 26)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -190) -- where raid warnings show
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(false)
    lines = {}
    for i = 1, MAX_LINES do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        fs:SetPoint("TOP", frame, "TOP", 0, -(i - 1) * 26)
        fs:SetShadowOffset(1, -1)
        lines[i] = fs
    end
    frame:Hide()
end

-- One line per healer whose mana is hidden. test: show every line, not
-- just the low ones. Returns how many lines went up.
function HealerMana.ShowHidden(healers, test)
    local c = Curves()
    if not c then
        return 0
    end
    if not frame then
        CreateLines()
    end
    local n = 0
    for _, h in ipairs(healers) do
        if not h.mana and n < MAX_LINES then
            local fs = lines[n + 1]
            local ok = pcall(function()
                local pct = UnitPowerPercent(h.unit, MANA, false, CurveConstants.ScaleTo100)
                local color = UnitPowerPercent(h.unit, MANA, false, test and c.always or c.low)
                fs:SetFormattedText(test and "%s: %.0f%% mana" or "Healer low on mana: %s %.0f%%", h.name, pct)
                fs:SetTextColor(color:GetRGBA())
            end)
            if ok then
                n = n + 1
            end
        end
    end
    for i = n + 1, MAX_LINES do
        lines[i]:SetText("")
    end
    if n > 0 then
        frame:Show()
        local token = {}
        hideAt = token
        C_Timer.After(SHOW_FOR, function()
            if hideAt == token then
                HideLines()
            end
        end)
    else
        HideLines()
    end
    return n
end

function HealerMana.Check()
    if not root.FeatureOn("healerMana") or InCombatLockdown() then
        return
    end
    if not (root.Threat and root.Threat.IsTank()) then
        return
    end
    local low = HealerMana.LowHealers()
    if #low > 0 then
        Show(HealerMana.Text(low))
    end
    HealerMana.ShowHidden(Healers())
end

-- /libram healers: why the warning would or would not show right now, and each
-- healer's mana on screen for a few seconds.
function HealerMana.Report()
    root.Print("Healer mana after combat:")
    if not root.FeatureOn("healerMana") then
        root.Print("  switched off in the options")
    end
    local tank = root.Threat and root.Threat.IsTank()
    root.Print(tank and "  you count as a tank" or
        "  you don't count as a tank right now (needs Tank mode, the tank role or Righteous Fury)")
    local list = Units()
    if #list == 0 then
        root.Print("  not in a group")
        return
    end
    local healers, hidden = 0, 0
    for _, unit in ipairs(list) do
        if Get(UnitExists, unit) and not Get(UnitIsUnit, unit, "player") then
            local name = Get(UnitName, unit) or unit
            local role = Get(UnitGroupRolesAssigned, unit)
            local mana = PlainMana(unit)
            if role == "HEALER" then
                healers = healers + 1
                if not mana then
                    hidden = hidden + 1
                end
            end
            root.Print(("  %s: role %s, %s"):format(name,
                role == "HEALER" and "healer" or role == "TANK" and "tank" or role == "DAMAGER" and "damage"
                    or role == nil and "hidden" or "not set",
                mana and ("%d%% mana"):format(math.floor(mana * 100)) or "mana hidden or none"))
        end
    end
    if healers == 0 then
        root.Print("  nobody has the healer role set, so nothing is checked.")
    elseif hidden > 0 then
        local shown = HealerMana.ShowHidden(Healers(), true)
        if shown > 0 then
            root.Print("  the game hides healer mana from addons, so the warning is drawn by the game itself. Their mana is on screen for a few seconds now; after a fight only healers under 20% show.")
        else
            root.Print("  the game hides healer mana from addons, and this game version can't draw it either, so no warning is possible.")
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function(_, event)
    if not root.db then
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        HideLines()
        return
    end
    C_Timer.After(SETTLE, function()
        local ok, err = pcall(HealerMana.Check)
        if not ok then
            root.Print("healer mana: " .. tostring(err))
        end
    end)
end)
