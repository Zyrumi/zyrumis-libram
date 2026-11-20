-- Zyrumi's Libram: class quest checklist
-- Every paladin class quest chain for your faction (and race, where the
-- chain differs), with what is done, what is next and who gives it.
-- Everything ticks itself off: the game tells addons which quests you have
-- completed, and which spells (Redemption, your mounts) you know.
-- The data is in QuestData.lua.

local ADDON_NAME, root = ...

local ClassQuests = {}
root.ClassQuests = ClassQuests

local Safe = root.Safe

local function Completed(id)
    local fn = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    return Safe(fn, id) == true
end

local function InLog(id)
    local fn = C_QuestLog and C_QuestLog.GetLogIndexForQuestID
    local index = Safe(fn, id)
    return type(index) == "number" and index > 0
end

local function QuestName(step)
    local fn = C_QuestLog and C_QuestLog.GetTitleForQuestID
    local title = Safe(fn, step.ids[1])
    return type(title) == "string" and title ~= "" and title or step.name
end

local function ZoneName(zone)
    if not zone then
        return nil
    end
    local fn = C_Map and C_Map.GetAreaInfo
    local name = Safe(fn, zone)
    return type(name) == "string" and name ~= "" and name or nil
end

-- "Duthorian Rall, Stormwind City 50.5, 47.5"
function ClassQuests.Where(step)
    if not step.giver then
        return nil
    end
    local zone = ZoneName(step.zone)
    if zone and step.x then
        return ("%s, %s %.1f, %.1f"):format(step.giver, zone, step.x, step.y)
    elseif zone then
        return ("%s, %s"):format(step.giver, zone)
    end
    return step.giver
end

local function StepDone(step)
    for _, id in ipairs(step.ids) do
        if Completed(id) then
            return true
        end
    end
    return false
end

local function StepInLog(step)
    for _, id in ipairs(step.ids) do
        if InLog(id) then
            return true
        end
    end
    return false
end

local function RaceBit()
    -- (Safe passes on two results; the race ID is the third.)
    local ok, _, _, raceID = pcall(UnitRace, "player")
    if not ok or root.IsSecret(raceID) or type(raceID) ~= "number" or raceID < 1 then
        return nil
    end
    return 2 ^ (raceID - 1)
end

-- The milestones for this character, in level order.
function ClassQuests.Mine()
    local faction = Safe(UnitFactionGroup, "player")
    local bit = RaceBit()
    local out = {}
    for _, m in ipairs(root.QUEST_DATA or {}) do
        local raceOk = not m.races or not bit or math.floor(m.races / bit) % 2 == 1
        if m.faction == faction and raceOk then
            out[#out + 1] = m
        end
    end
    return out
end

-- How a milestone stands: { state, next, nextIndex, inLog, doneCount }
-- state: "done", "progress" (begun), "ready" (your level is high enough) or "later".
function ClassQuests.Status(m, level)
    level = level or Safe(UnitLevel, "player") or 1
    -- A later step done means the earlier ones are done too (some can't be
    -- seen as completed, like breadcrumbs from another trainer).
    local lastDone = 0
    for i, step in ipairs(m.steps) do
        if StepDone(step) then
            lastDone = i
        end
    end
    local spellKnown = false
    for _, id in ipairs(type(m.spell) == "table" and m.spell or { m.spell }) do
        if root.IsPlayerSpell(id) then
            spellKnown = true
        end
    end
    if lastDone == #m.steps or spellKnown then
        return { state = "done", doneCount = #m.steps }
    end
    local nextIndex = lastDone + 1
    local step = m.steps[nextIndex]
    local inLog = StepInLog(step)
    local state
    if lastDone > 0 or inLog then
        state = "progress"
    elseif level >= step.level then
        state = "ready"
    else
        state = "later"
    end
    return { state = state, next = step, nextIndex = nextIndex, inLog = inLog, doneCount = lastDone }
end

-------------------------------------------------------------------------------
-- Chat note when a class quest becomes available
-------------------------------------------------------------------------------

function ClassQuests.AnnounceFor(level)
    if not root.FeatureOn("quests") or root.db.questNotes == false then
        return
    end
    for _, m in ipairs(ClassQuests.Mine()) do
        local st = ClassQuests.Status(m, level)
        if st.state == "ready" and st.next and st.next.level == level then
            local where = ClassQuests.Where(st.next)
            root.Print(("class quest ready: |cfff5c542%s|r (%s). Start with \"%s\"%s. /libram quests for the list.")
                :format(m.title, m.reward, QuestName(st.next), where and (" from " .. where) or ""))
        end
    end
end

-------------------------------------------------------------------------------
-- The Libram window: the checklist (minimap button, /libram quests, key)
-------------------------------------------------------------------------------

local STATE_TEXT = {
    done = "|cff7fd17fDone|r",
    progress = "|cfff5c542In progress|r",
    ready = "|cfff5c542Ready|r",
    later = "|cffa0a0a0Level %d|r",
}
local ROW_H = 60

local Window = {}
root.Window = Window

local win, content, summary, emptyNote
local rows = {}

-- Hovering a chain lists all its steps.
local function RowTooltip(self)
    local m = self.milestone
    if not m then
        return
    end
    local st = ClassQuests.Status(m)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(m.title, 1, 1, 1)
    GameTooltip:AddLine(m.reward, 0.8, 0.8, 0.8, true)
    for i, step in ipairs(m.steps) do
        local mark
        if st.state == "done" or i <= st.doneCount then
            mark = "|cff7fd17fdone|r"
        elseif i == st.nextIndex then
            mark = "|cfff5c542next|r"
        else
            mark = "|cffa0a0a0level " .. step.level .. "|r"
        end
        GameTooltip:AddDoubleLine(("%d. %s"):format(i, QuestName(step)), mark, 1, 1, 1)
    end
    if m.side then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Also part of it:", 0.8, 0.8, 0.8)
        for _, sq in ipairs(m.side) do
            GameTooltip:AddDoubleLine(QuestName(sq), StepDone(sq) and "|cff7fd17fdone|r" or "", 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

local function Row(i)
    local r = rows[i]
    if r then
        return r
    end
    r = CreateFrame("Frame", nil, content)
    r:SetHeight(ROW_H - 4)
    r:SetPoint("TOPLEFT", 4, -(i - 1) * ROW_H)
    r:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    r:EnableMouse(true)
    r:SetScript("OnEnter", RowTooltip)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0.08)
    r.state = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    r.state:SetPoint("TOPLEFT", 8, -6)
    r.state:SetWidth(92)
    r.state:SetJustifyH("LEFT")
    r.title = r:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    r.title:SetPoint("TOPLEFT", 104, -6)
    r.title:SetPoint("RIGHT", -8, 0)
    r.title:SetJustifyH("LEFT")
    r.line1 = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    r.line1:SetPoint("TOPLEFT", 104, -23)
    r.line1:SetPoint("RIGHT", -8, 0)
    r.line1:SetJustifyH("LEFT")
    r.line2 = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    r.line2:SetPoint("TOPLEFT", 104, -38)
    r.line2:SetPoint("RIGHT", -8, 0)
    r.line2:SetJustifyH("LEFT")
    r.line2:SetWordWrap(false)
    rows[i] = r
    return r
end

function Window.Fill()
    if not win then
        return
    end
    local list = ClassQuests.Mine()
    local level = Safe(UnitLevel, "player") or 1
    local done = 0
    for i, m in ipairs(list) do
        local r = Row(i)
        r.milestone = m
        local st = ClassQuests.Status(m, level)
        if st.state == "done" then
            done = done + 1
        end
        local first = m.steps[1]
        r.state:SetText(st.state == "later" and STATE_TEXT.later:format(st.next.level) or STATE_TEXT[st.state])
        r.title:SetText(("%s  |cffa0a0a0level %d, %s|r"):format(m.title, m.level, m.reward))
        if st.state == "done" then
            r.line1:SetText(("All %d steps done."):format(#m.steps))
            r.line2:SetText("")
        else
            local where = ClassQuests.Where(st.next)
            r.line1:SetText(("Step %d of %d: %s%s"):format(st.nextIndex, #m.steps, QuestName(st.next),
                st.inLog and " (in your quest log)" or ""))
            if st.doneCount == 0 and first.giver then
                r.line2:SetText("Starts with " .. (ClassQuests.Where(first) or first.giver))
            elseif where then
                r.line2:SetText("From " .. where)
            else
                r.line2:SetText("Handed out when you finish the step before.")
            end
        end
        r:SetAlpha(st.state == "done" and 0.6 or 1)
        r:Show()
    end
    for i = #list + 1, #rows do
        rows[i]:Hide()
    end
    emptyNote:SetShown(#list == 0)
    summary:SetText(#list > 0 and ("%d of %d chains done. Hover a chain to see all its steps."):format(done, #list) or "")
    content:SetHeight(math.max(1, #list * ROW_H))
end

local function SavePosition()
    local point, _, relPoint, x, y = win:GetPoint()
    if point then
        root.db.windowPos = { point, relPoint, x, y }
    end
end

local function Create()
    win = CreateFrame("Frame", "ZyrumisLibramWindow", UIParent, "BackdropTemplate")
    win:SetSize(600, 520)
    win:SetFrameStrata("HIGH")
    win:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    local p = root.db.windowPos
    if type(p) == "table" and p[1] then
        win:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        win:SetPoint("CENTER", 0, 40)
    end
    if UISpecialFrames then
        table.insert(UISpecialFrames, "ZyrumisLibramWindow") -- Esc closes it
    end

    local icon = win:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("TOPLEFT", 22, -20)
    icon:SetTexture(root.ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local title = win:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
    title:SetText(root.TITLE .. ": class quests")
    summary = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local inset = CreateFrame("Frame", nil, win)
    inset:SetPoint("TOPLEFT", 18, -66)
    inset:SetPoint("BOTTOMRIGHT", -18, 48)
    content = root.UI.ScrollArea(inset)
    emptyNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    emptyNote:SetPoint("TOPLEFT", 8, -8)
    emptyNote:SetText("Only paladins have class quests.")

    local settings = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    settings:SetSize(120, 24)
    settings:SetPoint("BOTTOMRIGHT", -22, 18)
    settings:SetText("Settings")
    settings:SetScript("OnClick", function()
        win:Hide()
        root.OpenOptions()
    end)
    local hint = win:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 24, 24)
    hint:SetText("Steps tick themselves off as you finish them.")

    win:SetScript("OnShow", function()
        local ok, err = pcall(Window.Fill)
        if not ok then
            root.Print("class quests: " .. tostring(err))
        end
    end)
    -- Keep it current while it is open.
    win:RegisterEvent("QUEST_TURNED_IN")
    win:RegisterEvent("QUEST_ACCEPTED")
    win:RegisterEvent("QUEST_REMOVED")
    win:RegisterEvent("PLAYER_LEVEL_UP")
    win:RegisterEvent("LEARNED_SPELL_IN_TAB")
    win:SetScript("OnEvent", function(self)
        if self:IsShown() then
            C_Timer.After(0.5, function() pcall(Window.Fill) end)
        end
    end)
    win:Hide()
end

function Window.Show()
    if not win then
        Create()
    end
    win:Show()
end

function Window.Toggle()
    if win and win:IsShown() then
        win:Hide()
    else
        Window.Show()
    end
end

-- Options > Keybindings > AddOns
function ZyrumisLibram_ToggleWindow()
    Window.Toggle()
end

-------------------------------------------------------------------------------
-- Settings page: only the setting, and a way to the list
-------------------------------------------------------------------------------

function ClassQuests.BuildPage()
    local UI = root.UI
    local panel = CreateFrame("Frame", "ZyrumisLibramQuestsOptions", UIParent)
    panel:Hide()
    local page = UI.ScrollArea(panel)
    UI.PageTitle(page, "Class quests", "The checklist itself opens from the minimap button, /libram quests or a key binding.", 16, -16)
    UI.Check(page, "Tell me in chat when a class quest becomes available", "When you reach the level for the next class quest, a line in chat says what it is and who gives it.",
        16, -60,
        function() return root.db.questNotes ~= false end,
        function(v) root.db.questNotes = v end,
        function() return root.FeatureOn("quests") end)
    UI.Button(page, "Open the class quests", "Every paladin class quest chain for this character, with the next step and who gives it.",
        16, -96, 200, function() Window.Show() end)
    UI.Note(page, "Key binding: Options > Keybindings > AddOns > \"Open the class quests\".", 16, -128)
    page:SetHeight(180)
    panel:SetScript("OnShow", function() UI.RefreshAll() end)
    root.RegisterSubPage(panel, "Class quests")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:SetScript("OnEvent", function(_, _, level)
    if not root.db or not root.IsPaladin() then
        return
    end
    -- The new level's quests can need a moment to show as available.
    C_Timer.After(2, function()
        local ok, err = pcall(ClassQuests.AnnounceFor, tonumber(level))
        if not ok then
            root.Print("class quests: " .. tostring(err))
        end
    end)
end)
