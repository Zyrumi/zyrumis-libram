-- Zyrumi's Libram: settings pages (Esc > Options > AddOns > Zyrumi's Libram)
--   Zyrumi's Libram   parts on/off, frames, minimap button, help
--   Blessings         which reminders, who gets what, greater blessings
--   Tank and combat   Tank / DPS buttons, seal and judgement timers
--   Class quests      the class quest checklist (ClassQuests.lua)

local ADDON_NAME, root = ...

local UI

local BLESSING_TEXT = { might = "Might", wisdom = "Wisdom", kings = "Kings" }
local CLASS_TEXT = {
    WARRIOR = "Warriors", ROGUE = "Rogues", HUNTER = "Hunters", MAGE = "Mages", WARLOCK = "Warlocks",
    PRIEST = "Priests", DRUID = "Druids", SHAMAN = "Shamans", PALADIN = "Paladins",
}
local ROLE_CLASSES = { DRUID = true, SHAMAN = true, PALADIN = true }

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(meta, ADDON_NAME, "Version")
    return ok and type(v) == "string" and v or ""
end

local function NewPanel(name)
    local panel = CreateFrame("Frame", name, UIParent)
    panel:Hide()
    panel:SetScript("OnShow", function() UI.RefreshAll() end)
    return panel, UI.ScrollArea(panel)
end

-------------------------------------------------------------------------------
-- Main page
-------------------------------------------------------------------------------

local PARTS = {
    { key = "buffs", label = "Buff reminders",
        tip = "Out of combat, an icon for each missing or fading aura, blessing or Righteous Fury. Click to cast.",
        note = "Icons for your aura, your own blessing and your group's blessings. Details on the Blessings page." },
    { key = "tank", label = "Tank / DPS buttons",
        tip = "Two buttons above your action bar that swap your gear set, action bar page and Righteous Fury in one click.",
        note = "One click to switch roles. Set names and bar pages on the Tank and combat page." },
    { key = "seals", label = "Seal and judgement timers",
        tip = "During fights: your seal with its time left (or \"No seal\") and your judgement on the target.",
        note = "Shown in fights only, unless you change that on the Tank and combat page." },
    { key = "threat", label = "Threat for tanks",
        tip = "In combat: an icon above each enemy nameplate and your target showing if the mob is yours, slipping, or on someone else (and who).",
        note = "Shield = yours, half shield = slipping, warning sign = on someone else (name beside it). Needs enemy nameplates (V)." },
    { key = "healerMana", label = "Healer mana after combat",
        tip = "When a fight ends and you are tanking, a warning in the middle of the screen if a healer is under 20% mana.",
        note = "Only players with the healer group role count. /libram healers shows what it sees." },
    { key = "cleanse", label = "Cleanse buttons",
        tip = "A small button beside your own frame and each party member's frame. Click it to Cleanse that person.",
        note = "A coloured edge and a letter (M, P, D) show what you can remove, when the game lets addons see it." },
    { key = "quests", label = "Class quest checklist",
        tip = "Every paladin class quest chain for your faction: what is done, what is next and who gives it. Ticks itself off.",
        note = "On its own page (Class quests), or /libram quests. A line in chat when a new one becomes available." },
}

local function BuildMain()
    local panel, page = NewPanel("ZyrumisLibramOptions")
    local x, y = 16, -16
    UI.PageTitle(page, root.TITLE, "Version " .. Version() .. ". Your paladin helper: reminders, one-key buffing, tank tools.", x, y)
    y = y - 52

    if not root.IsPaladin() then
        local warn = UI.Note(page, "|cffff8080This character is not a paladin, so nothing here does anything on it.|r", x, y)
        warn:SetFontObject("GameFontHighlight")
        y = y - 26
    end

    UI.Heading(page, "Parts", x, y)
    y = y - 26
    for _, p in ipairs(PARTS) do
        UI.Check(page, p.label, p.tip, x, y,
            function() return root.db.features[p.key] end,
            function(v) root.SetFeature(p.key, v) end)
        y = y - 24
        UI.Note(page, p.note, x + 30, y, 520)
        y = y - 30
    end

    UI.Heading(page, "Frames", x, y - 4)
    y = y - 32
    local move = UI.Button(page, "Move frames", "Shows a handle on every frame of this addon. Drag them where you like, then click again to lock.",
        x, y, 160, function() root.SetUnlocked(not root.unlocked) end)
    UI.AddRefresher(function() move:SetText(root.unlocked and "Lock frames" or "Move frames") end)
    UI.Button(page, "Reset positions", "Puts every frame of this addon back where it started.", x + 170, y, 160,
        function() root.ResetPositions() end)
    y = y - 34
    UI.Slider(page, "Size", "How big the buff icons, Tank / DPS buttons and seal timers are.", x, y, 0.6, 1.6, 0.05,
        function() return root.db.scale end,
        function(v) root.db.scale = v end,
        { format = function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end, after = root.ApplyScale })
    y = y - 50
    UI.Check(page, "Minimap button", "The libram on the edge of the minimap. Click for settings, right-click to move frames, drag to move it.", x, y,
        function() return root.MinimapButton and root.MinimapButton.IsShown() end,
        function(v) root.MinimapButton.SetShown(v) end)
    y = y - 24
    UI.Note(page, "Hidden or not, the addon is always in the minimap's addon menu too.", x + 30, y)
    y = y - 34

    UI.Heading(page, "Getting started", x, y)
    y = y - 26
    UI.Note(page, "1. Buff icons appear above your character when something is missing. Click them, or bind \"Cast the next buff\" "
        .. "under Options > Keybindings > AddOns and press it until they are gone.\n"
        .. "2. Right-click a blessing icon to choose another blessing for that person.\n"
        .. "3. Name your gear sets \"Tank\" and \"DPS\" in the character window to swap gear with the Tank / DPS buttons.\n"
        .. "4. Type /libram help for the chat commands.", x, y, 540)
    y = y - 82
    UI.Button(page, "Show the welcome again", "The window you saw on your first login.", x, y, 200, function() root.ShowWelcome() end)
    y = y - 40

    page:SetHeight(-y + 16)
    root.SetMainPage(panel)
end

-------------------------------------------------------------------------------
-- Blessings page
-------------------------------------------------------------------------------

local function BlessingChoices(withAuto, autoText, list)
    local out = {}
    if withAuto then
        out[#out + 1] = { false, autoText or "Automatic" }
    end
    for _, key in ipairs(list) do
        out[#out + 1] = { key, BLESSING_TEXT[key] }
    end
    return out
end

local function AutoText(class)
    local B = root.Blessings
    if class == "TANK" then
        return "Auto: Kings, else Might"
    end
    if ROLE_CLASSES[class] then
        return "Auto: by role"
    end
    local first = B.DefaultFor(class, nil)[1]
    return "Auto: " .. BLESSING_TEXT[first]
end

local function BuildBlessings()
    local B = root.Blessings
    local panel, page = NewPanel("ZyrumisLibramBlessingsOptions")
    local x, y = 16, -16
    UI.PageTitle(page, "Blessings", "Which reminders you get and who gets which blessing.", x, y)
    y = y - 52

    UI.Heading(page, "Reminders on this character", x, y)
    y = y - 26
    for _, g in ipairs(B.GROUPS) do
        UI.Check(page, g.label, g.tip, x, y,
            function() return B.ReminderOn(g) end,
            function(v) B.SetReminder(g.key, v) end,
            function() return root.FeatureOn("buffs") end)
        y = y - 26
    end
    UI.Check(page, "Hide the icons while mounted", "Casting would pull you off your mount, so the icons wait until you are on foot.", x, y,
        function() return root.db.hideMounted ~= false end,
        function(v) root.db.hideMounted = v; B.Update() end)
    y = y - 34
    UI.Slider(page, "Remind me when a blessing has less than", "Blessings (yours and your group's) get an icon this long before they run out.",
        x, y, 1, 10, 1,
        function() return root.db.refreshMinutes end,
        function(v) root.db.refreshMinutes = v end,
        { format = function(v) return v .. (v == 1 and " minute left" or " minutes left") end, after = B.Update })
    y = y - 52

    UI.Heading(page, "Your own blessing", x, y)
    y = y - 28
    UI.Choice(page, "Blessing on yourself", "Automatic uses the one you put on yourself last, or what your role suits.",
        x, y, 190,
        BlessingChoices(true, "Automatic", { "might", "wisdom", "kings" }),
        function() local c = root.CharData(); return c and c.selfPick or false end,
        function(v) local c = root.CharData(); if c then c.selfPick = v or nil end; B.Update() end)
    y = y - 36

    UI.Heading(page, "Blessings for others", x, y)
    y = y - 22
    UI.Note(page, "What each class gets from you. If someone already has it from another paladin, they get their next best. "
        .. "Right-click a blessing icon to choose for one person only.", x, y, 540)
    y = y - 34
    local rows = { "TANK" }
    for _, class in ipairs(B.CLASSES) do
        rows[#rows + 1] = class
    end
    for _, class in ipairs(rows) do
        local label = class == "TANK" and "Tanks (any class)" or CLASS_TEXT[class]
        local tip = class == "TANK" and "Anyone with the tank group role."
            or ROLE_CLASSES[class] and "Automatic goes by their group role: healers Wisdom, damage Might, tanks Kings."
            or nil
        UI.Choice(page, label, tip, x, y, 190,
            BlessingChoices(true, AutoText(class), B.OTHERS_ORDER),
            function() return root.db.blessFor[class] or false end,
            function(v) root.db.blessFor[class] = v or nil; B.Update() end)
        y = y - 28
    end
    y = y - 6
    UI.Button(page, "Forget my picks for people", "Clears every right-click pick you made for single players on this character.",
        x, y, 220, function()
            local c = root.CharData()
            if c then
                c.picks = {}
            end
            B.Update()
            root.Print("your picks for single players are cleared.")
        end)
    y = y - 40

    UI.Heading(page, "Greater blessings", x, y)
    y = y - 28
    UI.Choice(page, "Use greater blessings", "A greater blessing covers every player of that class in your group and uses a Symbol of Kings.",
        x, y, 190,
        { { "raid", "In raids" }, { "group", "In any group" }, { "never", "Never" } },
        function() return root.db.greater end,
        function(v) root.db.greater = v; B.Update() end)
    y = y - 30
    UI.Note(page, "Only when you carry Symbols of Kings and have learned the greater blessing.", x, y)
    y = y - 26
    UI.Slider(page, "Keep Symbols of Kings in your bags", "When you open a vendor who sells them, the addon buys enough to have this many. 0 = never buy.",
        x, y, 0, 200, 10,
        function() return root.db.restock end,
        function(v) root.db.restock = v end,
        { format = function(v) return v == 0 and "off" or tostring(v) end })
    y = y - 56

    page:SetHeight(-y + 16)
    root.RegisterSubPage(panel, "Blessings")
end

-------------------------------------------------------------------------------
-- Tank and combat page
-------------------------------------------------------------------------------

local function BuildCombat()
    local T = root.TankMode
    local panel, page = NewPanel("ZyrumisLibramCombatOptions")
    local x, y = 16, -16
    UI.PageTitle(page, "Tank and combat", "The Tank / DPS buttons and the seal and judgement timers.", x, y)
    y = y - 52

    UI.Heading(page, "Tank / DPS buttons", x, y)
    y = y - 24
    local blocked = UI.Note(page, "", x, y)
    UI.AddRefresher(function()
        blocked:SetText(T.Blocked() and "|cffff8080The separate Tank Swap addon is installed, so these buttons are left to it.|r"
            or "The Tank button toggles: click it again while tanking to go back to DPS.")
    end)
    y = y - 26
    local function Apply()
        T.ApplyMacros()
        T.Refresh()
        root.Blessings.Update()
    end
    UI.TextBox(page, "Tank gear set", "The name of your tank equipment set (character window, Equipment Manager).", x, y, 150,
        function() return root.db.tank.tankSet end,
        function(v) root.db.tank.tankSet = v; Apply() end)
    y = y - 28
    UI.TextBox(page, "DPS gear set", "The name of your damage equipment set.", x, y, 150,
        function() return root.db.tank.dpsSet end,
        function(v) root.db.tank.dpsSet = v; Apply() end)
    y = y - 36
    local function Pages(label, tip, key, other)
        UI.Slider(page, label, tip, x, y, 1, 6, 1,
            function() return root.db.tank[key] end,
            function(v)
                if v == root.db.tank[other] then
                    root.db.tank[other] = root.db.tank[key] -- swap so they never match
                end
                root.db.tank[key] = v
            end,
            { format = function(v) return "page " .. v end, after = Apply })
        y = y - 50
    end
    Pages("Tank action bar", "The main action bar page that Tank mode turns to (Shift + 1 to 6 in game).", "tankPage", "dpsPage")
    Pages("DPS action bar", "The main action bar page that DPS mode turns to.", "dpsPage", "tankPage")
    UI.Check(page, "Righteous Fury with Tank mode", "Tank casts Righteous Fury if it is off; DPS cancels it.", x, y,
        function() return root.db.tank.fury ~= false end,
        function(v) root.db.tank.fury = v; Apply() end)
    y = y - 36

    UI.Heading(page, "Seal and judgement timers", x, y)
    y = y - 26
    UI.Check(page, "Show the judgement timer", "Your judgement on your target and how long it has left.", x, y,
        function() return root.db.sealsJudgement ~= false end,
        function(v) root.db.sealsJudgement = v; root.Seals.Update() end)
    y = y - 26
    UI.Check(page, "Show them out of combat too", "Normally they only show during fights.", x, y,
        function() return root.db.sealsAlways == true end,
        function(v) root.db.sealsAlways = v; root.Seals.Update() end)
    y = y - 30
    UI.Note(page, "In fights the game hides most buff details from addons, so the times come from your own casts. "
        .. "A judgement's real length is learned the first time the game shows it.", x, y, 540)
    y = y - 40

    page:SetHeight(-y + 16)
    root.RegisterSubPage(panel, "Tank and combat")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    UI = root.UI
    for _, build in ipairs({ BuildMain, BuildBlessings, BuildCombat, root.ClassQuests.BuildPage }) do
        local ok, err = pcall(build)
        if not ok then
            root.Print("settings page: " .. tostring(err))
        end
    end
    pcall(root.MainCategory)
end)
