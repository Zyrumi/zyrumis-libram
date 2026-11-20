-- Zyrumi's Libram: Tank / DPS buttons
-- Two stance-style buttons above the action bar.
--   Tank: puts on the equipment set named "Tank" (the name can be changed),
--         turns the main action bar to the tank page and casts Righteous
--         Fury if it is off. Clicking it again while tanking goes back to
--         DPS, so one key toggles.
--   DPS:  puts on the "DPS" set, turns the bar to the DPS page and cancels
--         Righteous Fury.
-- The clicks run the game's own /equipset and /changeactionbar through a
-- secure button, so the bar swap works in combat too. Gear can't change in
-- combat: the button shows "!" until you click again afterwards.

local ADDON_NAME, root = ...

local TankMode = {}
root.TankMode = TankMode

local IsSecret, Safe = root.IsSecret, root.Safe

local TANK_ICON = "Interface\\Icons\\INV_Shield_06"
local DPS_ICON = "Interface\\Icons\\INV_Sword_27"
local SIZE, GAP = 30, 4
local FURY_ID, FURY_NAME = 25780, "Righteous Fury"

local holder, tankButton, dpsButton
local dirty -- macro text waits for the end of combat

local function Opt()
    return root.db.tank
end

-- The separate Tank Swap addon does the same job: leave it to that one.
function TankMode.Blocked()
    return root.AddonLoaded("TankSwap")
end

local function Active()
    return root.FeatureOn("tank") and not TankMode.Blocked()
end

local function CurrentPage()
    local fn = (C_ActionBar and C_ActionBar.GetActionBarPage) or GetActionBarPage
    local page = Safe(fn)
    return type(page) == "number" and page or nil
end

-- An equipment set by name: { id, icon, equipped } or nil.
local function SetInfo(name)
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID) then
        return nil
    end
    local id = Safe(C_EquipmentSet.GetEquipmentSetID, name)
    if type(id) ~= "number" then
        return nil
    end
    local ok, setName, icon, _, equipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, id)
    if not ok or not setName or IsSecret(setName) then
        return nil
    end
    return { id = id, icon = icon, equipped = equipped == true }
end
TankMode.SetInfo = SetInfo

local function FuryName()
    return root.SpellName(FURY_ID) or FURY_NAME
end

local function KnowsFury()
    return root.KnownSpell(FURY_ID, FURY_NAME) ~= nil
end

-- true / false, or nil when the game won't say (combat).
local function HasFury()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return nil
    end
    local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", FuryName(), "HELPFUL")
    if not ok or IsSecret(a) then
        return nil
    end
    return a ~= nil
end

-- true in tank mode, false in DPS mode, nil when off or on another page.
function TankMode.IsTank()
    if not holder or not Active() then
        return nil
    end
    local page = CurrentPage()
    if page == Opt().tankPage then
        return true
    elseif page == Opt().dpsPage then
        return false
    end
    return nil
end

-- The two macros. The Tank one toggles: on the tank page it goes back to DPS.
-- fury: the spell name when known; furyUp: whether it is on right now (only
-- cast it when missing: casting it again costs mana). Fury goes before
-- /changeactionbar so [bar:N] still means the old page.
function TankMode.Macros(tankSet, dpsSet, tankPage, dpsPage, fury, furyUp)
    local tank = { ("/equipset [bar:%d] %s; %s"):format(tankPage, dpsSet, tankSet) }
    local dps = { "/equipset " .. dpsSet }
    if fury then
        tank[#tank + 1] = ("/cancelaura [bar:%d] %s"):format(tankPage, fury)
        if not furyUp then
            tank[#tank + 1] = ("/cast [nobar:%d] %s"):format(tankPage, fury)
        end
        dps[#dps + 1] = "/cancelaura " .. fury
    end
    tank[#tank + 1] = ("/changeactionbar [bar:%d] %d; %d"):format(tankPage, dpsPage, tankPage)
    dps[#dps + 1] = "/changeactionbar " .. dpsPage
    return table.concat(tank, "\n"), table.concat(dps, "\n")
end

local function ApplyMacros()
    if not holder then
        return
    end
    if InCombatLockdown() then
        dirty = true
        return
    end
    dirty = false
    local o = Opt()
    local fury = (o.fury ~= false and KnowsFury()) and FuryName() or nil
    local tank, dps = TankMode.Macros(o.tankSet, o.dpsSet, o.tankPage, o.dpsPage, fury, HasFury())
    if tankButton:GetAttribute("macrotext") ~= tank then
        tankButton:SetAttribute("macrotext", tank)
    end
    if dpsButton:GetAttribute("macrotext") ~= dps then
        dpsButton:SetAttribute("macrotext", dps)
    end
end
TankMode.ApplyMacros = ApplyMacros

-- Which mode you are in follows the action bar page; the gear may lag
-- behind (after a click in combat), which the "!" shows.
local function Refresh()
    if not holder then
        return
    end
    local page = CurrentPage()
    for _, b in ipairs({ tankButton, dpsButton }) do
        local on = page == (b == tankButton and Opt().tankPage or Opt().dpsPage)
        local set = SetInfo(b == tankButton and Opt().tankSet or Opt().dpsSet)
        b.icon:SetTexture((set and set.icon) or b.fallbackIcon)
        b.active:SetShown(on)
        b.icon:SetDesaturated(not on)
        b.warn:SetShown(on and set ~= nil and not set.equipped)
    end
end
TankMode.Refresh = Refresh

local function Tooltip(self)
    local o = Opt()
    local tank = self == tankButton
    local setName = tank and o.tankSet or o.dpsSet
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(tank and "Tank" or "DPS", 1, 1, 1)
    GameTooltip:AddLine(("Puts on your \"%s\" gear and turns the action bar to page %d."):format(setName,
        tank and o.tankPage or o.dpsPage), nil, nil, nil, true)
    if o.fury ~= false and KnowsFury() then
        GameTooltip:AddLine(tank and "Casts Righteous Fury if it is off." or "Cancels Righteous Fury.", nil, nil, nil, true)
    end
    if tank then
        GameTooltip:AddLine("Click again while tanking to go back to DPS.", nil, nil, nil, true)
    end
    local set = SetInfo(setName)
    if not set then
        GameTooltip:AddLine(("No gear set named \"%s\" yet. Make one in the character window (C) under Equipment Manager and the gear swaps too."):format(setName), 1, 0.5, 0.5, true)
    elseif self.warn:IsShown() then
        GameTooltip:AddLine("! This gear isn't fully on (changed during a fight?). Click again now.", 1, 0.82, 0, true)
    end
    GameTooltip:AddLine("Key bindings: Options > Keybindings > AddOns.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

local function MakeButton(name, icon, x)
    local b = CreateFrame("Button", name, holder, "SecureActionButtonTemplate")
    b:SetSize(SIZE, SIZE)
    b:SetPoint("LEFT", x, 0)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")
    b.fallbackIcon = icon

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("CENTER")
    border:SetSize(SIZE * 1.85, SIZE * 1.85)
    -- the "this one is on" frame, like a stance button
    b.active = b:CreateTexture(nil, "OVERLAY", nil, 2)
    b.active:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    b.active:SetBlendMode("ADD")
    b.active:SetAllPoints()
    b.active:Hide()
    b.warn = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    b.warn:SetPoint("TOPRIGHT", -1, -1)
    b.warn:SetText("!")
    b.warn:SetTextColor(1, 0.82, 0)
    b.warn:Hide()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    b:SetScript("OnEnter", Tooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:HookScript("PostClick", function() C_Timer.After(0.2, Refresh) end)
    return b
end

local function Create()
    holder = CreateFrame("Frame", "ZyrumisLibramTankFrame", UIParent)
    holder:SetSize(SIZE * 2 + GAP, SIZE)
    holder:SetClampedToScreen(true)
    tankButton = MakeButton("ZyrumisLibramTankButton", TANK_ICON, 0)
    dpsButton = MakeButton("ZyrumisLibramDPSButton", DPS_ICON, SIZE + GAP)
    local bar = MainActionBar or MainMenuBar
    local default = bar and { "BOTTOMLEFT", bar, "TOPLEFT", 0, 8 } or { "BOTTOM", UIParent, "BOTTOM", -250, 120 }
    root.RegisterMover(holder, "tank", "Tank / DPS", default)
end

-- Shows or hides the buttons to match the setting. Out of combat only.
function TankMode.Update()
    if InCombatLockdown() then
        dirty = true
        return
    end
    if Active() then
        if not holder then
            Create()
        end
        holder:Show()
        ApplyMacros()
        Refresh()
    elseif holder then
        holder:Hide()
    end
end

root.OnFeatureChanged("tank", function()
    TankMode.Update()
    if root.Blessings then
        root.Blessings.Update()
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not root.IsPaladin() then
            return
        end
        local ok, err = pcall(TankMode.Update)
        if not ok then
            root.Print("tank buttons: " .. tostring(err))
        end
        for _, e in ipairs({ "ACTIONBAR_PAGE_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
            "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_REGEN_ENABLED",
            "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB" }) do
            pcall(events.RegisterEvent, events, e)
        end
        pcall(events.RegisterUnitEvent, events, "UNIT_AURA", "player")
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and dirty then
        TankMode.Update()
        return
    end
    -- Fury came or went, or a new spell: the Tank macro may need its cast line.
    if event == "UNIT_AURA" or event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        ApplyMacros()
        return
    end
    Refresh()
    if event == "ACTIONBAR_PAGE_CHANGED" and root.Blessings then
        root.Blessings.Update() -- the Righteous Fury reminder follows tank mode
    end
end)
