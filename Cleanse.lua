-- Zyrumi's Libram: cleanse buttons
-- A small button beside your own frame and each party member's frame.
-- Clicking it casts Cleanse (or Purify before you learn Cleanse) on that
-- person, no targeting needed. A coloured edge and a letter show what kind
-- of debuff they have that you can remove.
--
-- During combat the game hides what debuffs people have from addons, so the
-- buttons can't always light up. Clicking still works: the game casts the
-- spell, and if there is nothing to remove it just says so.

local ADDON_NAME, root = ...

local Cleanse = {}
root.Cleanse = Cleanse

local UNITS = { "player", "party1", "party2", "party3", "party4" }
local UNIT_OK = { player = true, party1 = true, party2 = true, party3 = true, party4 = true }
local TYPE_ORDER = { "Magic", "Curse", "Poison", "Disease" }
local MOUSE = { "Left click", "Right click", "Middle click" }

-- The game's own debuff colors. A word is always shown too, never color alone.
local TYPE_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
}

-- Cleanse spells by class. ids are the classic spell IDs; the English name is
-- a fallback in case Forever numbers a spell differently. Spells with the
-- same name (Cure Poison, Cure Disease) cast the same way for every class.
-- When two spells remove the same types, the higher "better" wins.
local SPELLS = {
    { ids = { 4987 }, name = "Cleanse", types = { Magic = true, Poison = true, Disease = true } },
    { ids = { 1152 }, name = "Purify",  types = { Poison = true, Disease = true } },
}

local IsSecret = root.IsSecret

local buttons = {}    -- [Blizzard unit frame] = our secure button beside it
local chosen = {}     -- spells on mouse buttons: { name = cast name, types = {...} }
local covered = {}    -- [type] = true for every type the player can remove
local needsSetup = false -- spells or visibility changed during combat

-------------------------------------------------------------------------------
-- Which spells the player knows
-------------------------------------------------------------------------------

-- Returns the name to cast for each spell the player knows: the name as it
-- is written in their spell book (casting by name uses the highest rank).
local function KnownSpells()
    local book = root.Book()
    local known = {}
    for _, s in ipairs(SPELLS) do
        local castName
        for _, id in ipairs(s.ids) do
            castName = root.KnownSpell(id, nil, book)
            if castName then
                break
            end
        end
        castName = castName or book[s.name:lower()]
        if castName then
            known[#known + 1] = { name = castName, types = s.types, better = s.better or 0 }
        end
    end
    return known
end

local function CountTypes(types)
    local n = 0
    for _ in pairs(types) do
        n = n + 1
    end
    return n
end

-- Picks at most three spells: for each type (Magic, Curse, Poison, Disease)
-- the spell that removes the most types, the better one on a tie.
local function ChooseSpells()
    local known = KnownSpells()
    local list, used = {}, {}
    covered = {}
    for _, t in ipairs(TYPE_ORDER) do
        local best
        for _, s in ipairs(known) do
            if s.types[t] then
                if not best
                    or CountTypes(s.types) > CountTypes(best.types)
                    or (CountTypes(s.types) == CountTypes(best.types) and s.better > best.better) then
                    best = s
                end
            end
        end
        if best then
            covered[t] = true
            if not used[best.name] and #list < 3 then
                used[best.name] = true
                list[#list + 1] = best
            end
        end
    end
    return list
end

-------------------------------------------------------------------------------
-- Reading debuffs
-------------------------------------------------------------------------------

-- Returns "yes", "no" or "unknown", plus the debuff type when it is known.
local function DebuffState(unit)
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
        return "unknown"
    end
    local ok, exists = pcall(UnitExists, unit)
    if not ok or IsSecret(exists) or not exists then
        return "no"
    end

    -- First: every harmful aura, with its type. Works when auras are readable.
    local okScan, state, kind = pcall(function()
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if IsSecret(aura) then
                return "unknown"
            end
            if aura == nil then
                return "no"
            end
            local t = aura.dispelName
            if IsSecret(t) then
                return "unknown"
            end
            if t and covered[t] then
                return "yes", t
            end
        end
        return "no"
    end)
    if okScan and state ~= "unknown" then
        return state, kind
    end

    -- Second: let the game filter for "debuffs I can remove". Even when the
    -- details are hidden, that something was found may still be readable.
    local okProbe, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, "HARMFUL|RAID_PLAYER_DISPELLABLE")
    if okProbe and not IsSecret(aura) then
        if aura == nil then
            return "no"
        end
        local t = aura.dispelName
        if IsSecret(t) or not TYPE_COLORS[t] then
            t = nil
        end
        return "yes", t
    end
    return "unknown"
end

-------------------------------------------------------------------------------
-- Buttons beside the game's unit frames
-------------------------------------------------------------------------------

local SIZE = 22
local DIM = 0.45 -- nothing to remove (when the game lets us know)
local LETTER = { Magic = "M", Curse = "C", Poison = "P", Disease = "D" }

-- The frames we put a button beside: your own frame, the classic-style
-- party frames, and the raid-style party frames.
local function UnitFrames()
    local list = {}
    local function Add(f)
        if type(f) == "table" and f.GetAttribute and not (f.IsForbidden and f:IsForbidden()) then
            list[#list + 1] = f
        end
    end
    Add(PlayerFrame)
    if type(PartyFrame) == "table" then
        for i = 1, 4 do
            Add(PartyFrame["MemberFrame" .. i])
        end
    end
    for i = 1, 4 do
        Add(_G["PartyMemberFrame" .. i])
    end
    for i = 1, 5 do
        Add(_G["CompactPartyFrameMember" .. i])
    end
    return list
end

-- The person a game frame shows, if it is you or a party member.
local function FrameUnit(f)
    local ok, unit = pcall(f.GetAttribute, f, "unit")
    if not ok or IsSecret(unit) or type(unit) ~= "string" then
        unit = f.unit
    end
    if type(unit) == "string" and not IsSecret(unit) and UNIT_OK[unit] then
        return unit
    end
    return nil
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Cleanse", 1, 1, 1)
    for i, s in ipairs(chosen) do
        local types = {}
        for _, t in ipairs(TYPE_ORDER) do
            if s.types[t] then
                types[#types + 1] = t:lower()
            end
        end
        GameTooltip:AddDoubleLine(MOUSE[i] .. ": " .. s.name, table.concat(types, ", "), 1, 1, 1, 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
end

local function UpdateButton(b)
    local unit = b.unit
    if not unit then
        return
    end
    local state, kind = DebuffState(unit)
    if state == "yes" then
        local c = TYPE_COLORS[kind] or { 1, 0.85, 0.3 }
        b.border:SetColorTexture(c[1], c[2], c[3], 1)
        b.border:Show()
        b.letter:SetText(LETTER[kind] or "")
        b:SetAlpha(1)
    else
        b.border:Hide()
        b.letter:SetText("")
        -- Unknown (in combat): stay fully visible, a click still works.
        b:SetAlpha(state == "no" and DIM or 1)
    end
end

local function UpdateAll()
    for _, b in pairs(buttons) do
        if b.unit then
            pcall(UpdateButton, b)
        end
    end
end
Cleanse.UpdateAll = UpdateAll

local count = 0

local function CreateButton(frame)
    count = count + 1
    local b = CreateFrame("Button", "ZyrumisLibramCleanse" .. count, frame, "SecureUnitButtonTemplate")
    b:SetSize(SIZE, SIZE)
    -- Right of the frame: party frames often sit at the screen's left edge,
    -- and the game shows buffs and debuffs below the frame, not beside it.
    b:SetPoint("LEFT", frame, "RIGHT", 3, 0)
    b:SetFrameLevel(frame:GetFrameLevel() + 5)
    b:RegisterForClicks("AnyUp")

    -- Colored frame shown when the person has something you can remove.
    b.border = b:CreateTexture(nil, "BACKGROUND")
    b.border:SetPoint("TOPLEFT", -2, 2)
    b.border:SetPoint("BOTTOMRIGHT", 2, -2)
    b.border:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- The debuff type as a letter too, never color alone.
    b.letter = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.letter:SetPoint("BOTTOMRIGHT", 1, -1)

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.2)

    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons[frame] = b
    return b
end

-- One listener per person; it updates whichever buttons show that person.
for _, unit in ipairs(UNITS) do
    local watcher = CreateFrame("Frame")
    watcher:RegisterUnitEvent("UNIT_AURA", unit)
    watcher:SetScript("OnEvent", function()
        for _, b in pairs(buttons) do
            if b.unit == unit then
                pcall(UpdateButton, b)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- Setup (only possible out of combat: these buttons cast spells)
-------------------------------------------------------------------------------

local SpellIcon = root.SpellIcon

local function Setup()
    if InCombatLockdown() then
        needsSetup = true
        return
    end
    needsSetup = false

    chosen = ChooseSpells()
    local on = root.FeatureOn("cleanse") and #chosen > 0
    for _, frame in ipairs(UnitFrames()) do
        local b = buttons[frame]
        if on and not b then
            b = CreateButton(frame)
        end
        if b then
            local unit = on and FrameUnit(frame) or nil
            b.unit = unit
            b:SetAttribute("unit", unit)
            for i = 1, 3 do
                local s = chosen[i]
                b:SetAttribute("type" .. i, s and "spell" or nil)
                b:SetAttribute("spell" .. i, s and s.name or nil)
            end
            if unit then
                b.icon:SetTexture(SpellIcon(chosen[1].name))
                b:Show() -- hides with the game's frame, which is its parent
            else
                b:Hide()
            end
        end
    end
    UpdateAll()
end

function Cleanse.Refresh()
    local ok, err = pcall(Setup)
    if not ok then
        root.Print("cleanse buttons: " .. tostring(err))
    end
end

root.OnFeatureChanged("cleanse", function()
    Cleanse.Refresh()
end)

local setupQueued = false
local function QueueSetup()
    if not setupQueued then
        setupQueued = true
        C_Timer.After(0.2, function()
            setupQueued = false
            Cleanse.Refresh()
        end)
    end
end

-- Raid-style party frames change who they show when the group changes.
if type(hooksecurefunc) == "function" and type(CompactUnitFrame_SetUnit) == "function" then
    hooksecurefunc("CompactUnitFrame_SetUnit", function()
        if root.db then
            QueueSetup()
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")

events:SetScript("OnEvent", function(_, event)
    if not root.db then
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        UpdateAll()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and not needsSetup then
        UpdateAll() -- debuffs can be read again
        return
    end
    -- Spell book and group changes come in bursts; set up once.
    QueueSetup()
end)
