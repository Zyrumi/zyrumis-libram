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
    local spellKnown = m.spell and root.IsPlayerSpell(m.spell)
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
-- Settings page: the checklist
-------------------------------------------------------------------------------

local STATE_TEXT = {
    done = "|cff7fd17fDone|r",
    progress = "|cfff5c542In progress|r",
    ready = "|cfff5c542Ready|r",
    later = "|cffa0a0a0Level %d|r",
}

local rows = {}
local emptyNote

local function Row(parent, i)
    local r = rows[i]
    if r then
        return r
    end
    r = {}
    local y = -100 - (i - 1) * 58
    r.state = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    r.state:SetPoint("TOPLEFT", 16, y)
    r.state:SetWidth(90)
    r.state:SetJustifyH("LEFT")
    r.title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    r.title:SetPoint("TOPLEFT", 110, y)
    r.title:SetWidth(470)
    r.title:SetJustifyH("LEFT")
    r.line1 = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    r.line1:SetPoint("TOPLEFT", 110, y - 17)
    r.line1:SetWidth(470)
    r.line1:SetJustifyH("LEFT")
    r.line2 = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    r.line2:SetPoint("TOPLEFT", 110, y - 31)
    r.line2:SetWidth(470)
    r.line2:SetJustifyH("LEFT")
    rows[i] = r
    return r
end

local function Fill(page)
    local list = ClassQuests.Mine()
    local level = Safe(UnitLevel, "player") or 1
    for i, m in ipairs(list) do
        local r = Row(page, i)
        local st = ClassQuests.Status(m, level)
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
        if m.side then
            local left = {}
            for _, s in ipairs(m.side) do
                if not StepDone(s) then
                    left[#left + 1] = QuestName(s)
                end
            end
            if #left > 0 and st.state ~= "done" then
                r.line2:SetText(r.line2:GetText() .. "   Also part of it: " .. table.concat(left, ", "))
            end
        end
        for _, fs in ipairs({ r.state, r.title, r.line1, r.line2 }) do
            fs:Show()
        end
    end
    for i = #list + 1, #rows do
        for _, fs in ipairs({ rows[i].state, rows[i].title, rows[i].line1, rows[i].line2 }) do
            fs:Hide()
        end
    end
    emptyNote:SetShown(#list == 0)
    page:SetHeight(100 + #list * 58 + 40)
end

function ClassQuests.BuildPage()
    local UI = root.UI
    local panel = CreateFrame("Frame", "ZyrumisLibramQuestsOptions", UIParent)
    panel:Hide()
    local page = UI.ScrollArea(panel)
    UI.PageTitle(page, "Class quests", "Every paladin class quest chain for this character. Steps tick themselves off as you finish them.", 16, -16)
    UI.Check(page, "Tell me in chat when a class quest becomes available", "When you reach the level for the next class quest, a line in chat says what it is and who gives it.",
        16, -60,
        function() return root.db.questNotes ~= false end,
        function(v) root.db.questNotes = v end,
        function() return root.FeatureOn("quests") end)
    emptyNote = UI.Note(page, "Only paladins have class quests here.", 16, -96)
    panel:SetScript("OnShow", function()
        UI.RefreshAll()
        local ok, err = pcall(Fill, page)
        if not ok then
            root.Print("class quests: " .. tostring(err))
        end
    end)
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
