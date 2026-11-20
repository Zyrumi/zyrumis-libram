-- Zyrumi's Libram: core
-- Shared helpers, saved settings, spell book reading, the settings page
-- building blocks, movable frames, the welcome window and /libram.
--
-- Every part lives in its own file and registers itself here:
--   Blessings.lua  blessing, aura and Righteous Fury reminders, one-key buffing
--   TankMode.lua   Tank / DPS buttons (gear set + action bar page)
--   Seals.lua      seal and judgement timers in combat
--   Threat.lua     threat icons for tanks
--   HealerMana.lua low healer mana warning after combat
--   Cleanse.lua    cleanse buttons beside your party frames
--   Reagents.lua   Symbol of Kings restock at vendors
--   Options.lua    the settings pages
--   Minimap.lua    minimap button and the minimap's addon menu

local ADDON_NAME, root = ...

-- Options > Keybindings > AddOns
BINDING_HEADER_ZYRUMISLIBRAM = "Zyrumi's Libram"
_G["BINDING_NAME_CLICK ZyrumisLibramNextBuff:LeftButton"] = "Cast the next buff"
_G["BINDING_NAME_CLICK ZyrumisLibramTankButton:LeftButton"] = "Toggle tank / DPS"
_G["BINDING_NAME_CLICK ZyrumisLibramDPSButton:LeftButton"] = "Switch to DPS"

root.TITLE = "Zyrumi's Libram"
root.ICON = "Interface\\Icons\\INV_Relics_LibramofHope"
local PREFIX = "|cfff5c542Zyrumi's Libram:|r "

local DEFAULTS = {
    features = {
        buffs = true,
        tank = true,
        seals = true,
        threat = true,
        healerMana = true,
        cleanse = true,
    },
    minimap = { angle = 210, hide = false },
    positions = {},
    scale = 1,
    blessFor = {},        -- [class or "TANK"] = "might" / "wisdom" / "kings"
    greater = "raid",     -- "raid", "group" or "never"
    refreshMinutes = 3,   -- blessings with less time left get a reminder
    restock = 0,          -- Symbols of Kings to keep in your bags (0 = off)
    tank = { tankSet = "Tank", dpsSet = "DPS", tankPage = 2, dpsPage = 1 },
    welcomed = false,
    chars = {},
}

function root.Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
    end
end

-- The Forever client can hand addons "secret" values that may not be read
-- or even compared. Older builds offer issecretvalue, newer canaccessvalue.
function root.IsSecret(v)
    if issecretvalue ~= nil and issecretvalue(v) == true then
        return true
    end
    if canaccessvalue ~= nil and canaccessvalue(v) == false then
        return true
    end
    return false
end
local IsSecret = root.IsSecret

-- Calls fn safely. Returns its first two results, or nil when it failed or
-- the game hid the answer.
function root.Safe(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(fn, ...)
    if not ok or IsSecret(a) or IsSecret(b) then
        return nil
    end
    return a, b
end
local Safe = root.Safe

-- "Zyrumi Lightforge": the character's name (and surname, on Forever).
function root.CharKey()
    local ok, name, second = pcall(UnitName, "player")
    if not ok or IsSecret(name) or type(name) ~= "string" then
        return nil
    end
    if type(second) == "string" and second ~= "" and not IsSecret(second) then
        return name .. " " .. second
    end
    return name
end

-- 0:42, 12:30, 1:05:00
function root.Clock(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
    if h > 0 then
        return ("%d:%02d:%02d"):format(h, m, s)
    end
    return ("%d:%02d"):format(m, s)
end

-- 42s, 3m, 1h
function root.Short(seconds)
    seconds = math.max(0, seconds)
    if seconds >= 3600 then
        return ("%dh"):format(math.floor(seconds / 3600 + 0.5))
    elseif seconds >= 60 then
        return ("%dm"):format(math.floor(seconds / 60 + 0.5))
    end
    return ("%ds"):format(math.floor(seconds + 0.5))
end

function root.AddonLoaded(folder)
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if loaded then
        local ok, on = pcall(loaded, folder)
        return ok and on == true
    end
    return false
end

function root.PlayerClass()
    local _, class = Safe(UnitClass, "player")
    return type(class) == "string" and class or nil
end

function root.IsPaladin()
    return root.PlayerClass() == "PALADIN"
end

function root.InCombat()
    if InCombatLockdown() then
        return true
    end
    local ok, v = pcall(UnitAffectingCombat, "player")
    if not ok or IsSecret(v) then
        return true -- the game won't say: assume the worst
    end
    return v == true
end

-------------------------------------------------------------------------------
-- Saved settings
-------------------------------------------------------------------------------

local function MergeDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            MergeDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

root.DEFAULTS = DEFAULTS

function root.FeatureOn(key)
    local db = root.db
    if not db then
        return false
    end
    return db.features[key] == true and root.IsPaladin()
end

root.featureListeners = {}
function root.OnFeatureChanged(key, fn)
    local list = root.featureListeners[key] or {}
    list[#list + 1] = fn
    root.featureListeners[key] = list
end

function root.Changed(key)
    for _, fn in ipairs(root.featureListeners[key] or {}) do
        local ok, err = pcall(fn, root.FeatureOn(key))
        if not ok then
            root.Print("something went wrong: " .. tostring(err))
        end
    end
end

function root.SetFeature(key, on)
    root.db.features[key] = on and true or false
    root.Changed(key)
end

-- This character's own settings.
function root.CharData()
    local db, key = root.db, root.CharKey()
    if not db or not key then
        return nil
    end
    local c = db.chars[key]
    if type(c) ~= "table" then
        c = {}
        db.chars[key] = c
    end
    c.on = type(c.on) == "table" and c.on or {}
    c.last = type(c.last) == "table" and c.last or {}
    c.picks = type(c.picks) == "table" and c.picks or {}
    return c
end

-------------------------------------------------------------------------------
-- Spell book
-------------------------------------------------------------------------------

local PLAYER_BANK = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
local SPELL_ITEM = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) or 1

-- The spell's name in the player's language, or nil.
function root.SpellName(id)
    local get = (C_Spell and C_Spell.GetSpellName) or GetSpellInfo
    if not get or not id then
        return nil
    end
    local ok, name = pcall(get, id)
    if ok and type(name) == "string" and name ~= "" and not IsSecret(name) then
        return name
    end
    return nil
end

function root.IsPlayerSpell(id)
    if not IsPlayerSpell then
        return false
    end
    local ok, known = pcall(IsPlayerSpell, id)
    return ok and known == true
end

-- Some icons are missing for a moment right after login: callers ask again.
function root.SpellIcon(name)
    local get = C_Spell and C_Spell.GetSpellTexture
    if get and name then
        local ok, icon = pcall(get, name)
        if ok and icon and not IsSecret(icon) and icon ~= 134400 then
            return icon
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function ForEachBookSpell(fn)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
        return
    end
    local ok, count = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if not ok or type(count) ~= "number" then
        return
    end
    for line = 1, count do
        local okLine, li = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if okLine and type(li) == "table" and li.itemIndexOffset and li.numSpellBookItems then
            for slot = li.itemIndexOffset + 1, li.itemIndexOffset + li.numSpellBookItems do
                local okItem, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, PLAYER_BANK)
                if okItem and type(info) == "table" and info.itemType == SPELL_ITEM
                    and type(info.spellID) == "number" then
                    fn(info)
                end
            end
        end
    end
end

-- Every spell in the spell book: [lower case name] = name as written there.
-- Read again only when the spell book changes.
local bookCache
function root.Book()
    if bookCache then
        return bookCache
    end
    local book = {}
    ForEachBookSpell(function(info)
        local n = info.name
        if type(n) ~= "string" or IsSecret(n) then
            n = root.SpellName(info.spellID)
        end
        if type(n) == "string" then
            book[n:lower()] = n
        end
    end)
    if next(book) then -- empty right at login: don't keep that
        bookCache = book
    end
    return book
end

function root.ForgetBook()
    bookCache = nil
end

-- The name to cast when the player knows the spell, else nil. id is the
-- rank 1 spell ID (the name comes from the game, so any language works);
-- fallback is the English name for a client that numbers it differently.
-- Casting by name uses the highest rank.
function root.KnownSpell(id, fallback, book)
    book = book or root.Book()
    local n = root.SpellName(id)
    if n and book[n:lower()] then
        return book[n:lower()]
    end
    if n and root.IsPlayerSpell(id) then
        return n
    end
    if fallback and book[fallback:lower()] then
        return book[fallback:lower()]
    end
    return nil
end

-------------------------------------------------------------------------------
-- Settings page building blocks
-------------------------------------------------------------------------------

local refreshers = {}

local function RefreshAll()
    for _, fn in ipairs(refreshers) do
        pcall(fn)
    end
end

local function AddTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then
            GameTooltip:AddLine(text, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function Note(parent, text, x, y, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(width or 540)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function Heading(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", x, y - 16)
    line:SetWidth(560)
    return fs
end

-- get() returns the value; set(v) stores it. enabled() (optional) greys the
-- box out when it returns false.
local function Check(parent, label, tip, x, y, get, set, enabled)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", x, y)
    for _, key in ipairs({ "Text", "text" }) do
        if type(cb[key]) == "table" and cb[key].SetText then
            cb[key]:SetText("")
        end
    end
    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        RefreshAll()
    end)
    AddTooltip(cb, label, tip)
    refreshers[#refreshers + 1] = function()
        cb:SetChecked(get() and true or false)
        local on = (not enabled) or enabled()
        cb:SetEnabled(on)
        fs:SetFontObject(on and "GameFontHighlight" or "GameFontDisable")
    end
    return cb
end

-- A button that steps through choices on each click: { { value, text }, ... }.
local function Choice(parent, label, tip, x, y, width, choices, get, set)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", x, y - 4)
    title:SetText(label)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 160, 22)
    b:SetPoint("TOPLEFT", x + 190, y)
    local function Index()
        local v = get()
        for i, c in ipairs(choices) do
            if c[1] == v then
                return i
            end
        end
        return 1
    end
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, button)
        local i = Index() + (button == "RightButton" and -1 or 1)
        if i > #choices then
            i = 1
        elseif i < 1 then
            i = #choices
        end
        set(choices[i][1])
        RefreshAll()
    end)
    AddTooltip(b, label, (tip and (tip .. "\n\n") or "") .. "Click for the next choice, right-click for the one before.")
    refreshers[#refreshers + 1] = function()
        b:SetText(choices[Index()][2])
    end
    return b, title
end

local SCROLL_TEMPLATES = { "ScrollFrameTemplate", "UIPanelScrollFrameTemplate" }

-- A settings page in a scroll frame, so it fits however long it gets.
local function ScrollArea(panel)
    local scroll
    for _, template in ipairs(SCROLL_TEMPLATES) do
        local ok, frame = pcall(CreateFrame, "ScrollFrame", nil, panel, template)
        if ok and frame then
            scroll = frame
            break
        end
    end
    local hasBar = scroll ~= nil
    if not scroll then
        scroll = CreateFrame("ScrollFrame", nil, panel)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            local v = (self:GetVerticalScroll() or 0) - delta * 40
            self:SetVerticalScroll(math.max(0, math.min(range, v)))
        end)
    end
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", hasBar and -28 or 0, 4)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(600, 1)
    scroll:SetScrollChild(content)
    scroll:HookScript("OnSizeChanged", function(_, width)
        if type(width) == "number" and width > 0 then
            content:SetWidth(width)
        end
    end)
    return content
end

-- Plain slider built from game textures (no template needed).
-- opts: format(v) for the value text, unit after the value, after() after set.
local function Slider(parent, label, tip, x, y, minV, maxV, step, get, set, opts)
    opts = opts or {}
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", x + 4, y)
    local s = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    s:SetOrientation("HORIZONTAL")
    s:SetSize(280, 17)
    s:SetPoint("TOPLEFT", x + 4, y - 18)
    s:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then
        s:SetObeyStepOnDrag(true)
    end
    s:EnableMouseWheel(true)
    local loading = false
    local function ShowValue(v)
        local text = opts.format and opts.format(v) or (tostring(v) .. (opts.unit or ""))
        title:SetText(label .. ": " .. text)
    end
    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        ShowValue(v)
        if not loading and get() ~= v then
            set(v)
            if opts.after then
                opts.after()
            end
        end
    end)
    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * step)
    end)
    AddTooltip(s, label, tip)
    refreshers[#refreshers + 1] = function()
        local v = get()
        if type(v) ~= "number" then
            return
        end
        loading = true
        s:SetValue(v)
        ShowValue(v)
        loading = false
    end
    return s, title
end

-- A one-line text box. set(text) runs on Enter or when it loses focus.
local function TextBox(parent, label, tip, x, y, width, get, set)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", x, y - 4)
    title:SetText(label)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(width or 140, 20)
    e:SetPoint("TOPLEFT", x + 196, y)
    e:SetAutoFocus(false)
    e:SetMaxLetters(40)
    local function Save(self)
        local text = strtrim(self:GetText() or "")
        if text ~= "" and text ~= get() then
            set(text)
        end
        self:SetText(get() or "")
        self:ClearFocus()
        RefreshAll()
    end
    e:SetScript("OnEnterPressed", Save)
    e:SetScript("OnEditFocusLost", Save)
    e:SetScript("OnEscapePressed", function(self)
        self:SetText(get() or "")
        self:ClearFocus()
    end)
    AddTooltip(e, label, tip)
    refreshers[#refreshers + 1] = function()
        if not e:HasFocus() then
            e:SetText(get() or "")
        end
    end
    return e
end

local function Button(parent, text, tip, x, y, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 160, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", function()
        onClick()
        RefreshAll()
    end)
    AddTooltip(b, text, tip)
    return b
end

-- A page's title with the addon's icon and a line under it.
local function PageTitle(parent, text, sub, x, y)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", x, y + 4)
    icon:SetTexture(root.ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", x + 40, y)
    title:SetText(text)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x + 40, y - 20)
    fs:SetWidth(500)
    fs:SetJustifyH("LEFT")
    fs:SetText(sub or "")
    return title, fs
end

root.UI = {
    Check = Check, Choice = Choice, Note = Note, Heading = Heading, ScrollArea = ScrollArea,
    Slider = Slider, TextBox = TextBox, Button = Button, PageTitle = PageTitle,
    AddTooltip = AddTooltip, RefreshAll = RefreshAll,
    AddRefresher = function(fn) refreshers[#refreshers + 1] = fn end,
}

-------------------------------------------------------------------------------
-- Settings categories (Esc > Options > AddOns)
-------------------------------------------------------------------------------

local mainCategory, mainPanel
local pending = {} -- sub pages registered before the main page exists

function root.SetMainPage(panel)
    mainPanel = panel
end

function root.MainCategory()
    if mainCategory then
        return mainCategory
    end
    if not (mainPanel and Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return nil
    end
    mainCategory = Settings.RegisterCanvasLayoutCategory(mainPanel, root.TITLE)
    Settings.RegisterAddOnCategory(mainCategory)
    for _, p in ipairs(pending) do
        root.RegisterSubPage(p[1], p[2])
    end
    pending = {}
    return mainCategory
end

root.subCategories = {}

function root.RegisterSubPage(panel, name)
    local parent = root.MainCategory()
    if not parent then
        pending[#pending + 1] = { panel, name }
        return nil
    end
    if Settings.RegisterCanvasLayoutSubcategory then
        local ok, sub = pcall(Settings.RegisterCanvasLayoutSubcategory, parent, panel, name)
        if ok and sub then
            root.subCategories[name] = sub
            return sub
        end
    end
    return nil
end

local openAfterCombat

function root.OpenOptions(subName)
    local category = root.MainCategory()
    if subName and root.subCategories[subName] then
        category = root.subCategories[subName]
    end
    if not category or not (Settings and Settings.OpenToCategory) then
        root.Print("the settings page could not be opened")
        return false
    end
    if InCombatLockdown() then
        openAfterCombat = subName or true
        root.Print("the settings open when this fight is over")
        return true
    end
    Settings.OpenToCategory(category:GetID())
    return true
end

-------------------------------------------------------------------------------
-- Movable frames
-------------------------------------------------------------------------------
-- Each part registers its frames here. "Move frames" (settings or /libram
-- move) puts a labelled handle over each one; drag the handle, then lock.

local movers = {}
root.unlocked = false

-- frame: the frame to place. key: where its position is saved.
-- default: { point, relativeTo, relativePoint, x, y }. label: shown on the
-- handle. size: { w, h } for the handle when the frame has no size yet.
function root.RegisterMover(frame, key, label, default, size)
    local m = { frame = frame, key = key, label = label, default = default, size = size }
    movers[key] = m
    root.PlaceFrame(key)
    if root.unlocked then
        root.ShowMover(m)
    end
    return m
end

function root.PlaceFrame(key)
    local m = movers[key]
    if not m or InCombatLockdown() then
        return
    end
    local p = root.db and root.db.positions[key]
    m.frame:ClearAllPoints()
    if type(p) == "table" and p[1] then
        m.frame:SetPoint(p[1], UIParent, p[2] or p[1], tonumber(p[3]) or 0, tonumber(p[4]) or 0)
    else
        local d = m.default
        m.frame:SetPoint(d[1], d[2] or UIParent, d[3] or d[1], d[4] or 0, d[5] or 0)
    end
    m.frame:SetScale(root.db and root.db.scale or 1)
end

function root.ShowMover(m)
    if not m.handle then
        local h = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        h:SetFrameStrata("DIALOG")
        h:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        h:SetBackdropColor(0.1, 0.3, 0.6, 0.75)
        h:SetBackdropBorderColor(0.96, 0.77, 0.26, 1)
        h:EnableMouse(true)
        h:SetMovable(true)
        h:RegisterForDrag("LeftButton")
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        h.text:SetPoint("CENTER")
        h.text:SetText(m.label)
        h:SetScript("OnDragStart", function(self)
            if not InCombatLockdown() then
                self:StartMoving()
            end
        end)
        h:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save the handle's centre and put the frame there.
            local scale = m.frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local x, y = self:GetCenter()
            local ux, uy = UIParent:GetCenter()
            if x and ux then
                root.db.positions[m.key] = { "CENTER", "CENTER", (x - ux) / scale, (y - uy) / scale }
                root.PlaceFrame(m.key)
                root.ShowMover(m)
            end
        end)
        h:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(m.label, 1, 1, 1)
            GameTooltip:AddLine("Drag to move. Lock frames again on the settings page or with /libram lock.", nil, nil, nil, true)
            GameTooltip:Show()
        end)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
        m.handle = h
    end
    local h = m.handle
    local scale = m.frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local w, hgt = m.frame:GetWidth(), m.frame:GetHeight()
    if (not w or w < 20) and m.size then
        w, hgt = m.size[1], m.size[2]
    end
    h:SetSize(math.max(90, (w or 90) * scale), math.max(24, (hgt or 24) * scale))
    h:ClearAllPoints()
    local x, y = m.frame:GetCenter()
    if x then
        h:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale)
    else
        h:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    h:Show()
end

function root.SetUnlocked(on)
    if on and InCombatLockdown() then
        root.Print("frames can be moved once this fight is over")
        return
    end
    root.unlocked = on and true or false
    for _, m in pairs(movers) do
        if root.unlocked then
            root.ShowMover(m)
        elseif m.handle then
            m.handle:Hide()
        end
    end
    for key in pairs(root.featureListeners) do
        root.Changed(key)
    end
    if root.unlocked then
        root.Print("frames unlocked: drag the gold-edged handles, then lock them with /libram lock or on the settings page.")
    end
end

function root.ResetPositions()
    if InCombatLockdown() then
        root.Print("not during a fight")
        return
    end
    root.db.positions = {}
    for key, m in pairs(movers) do
        root.PlaceFrame(key)
        if root.unlocked then
            root.ShowMover(m)
        end
    end
    root.Print("all frames are back in their starting places")
end

function root.ApplyScale()
    for key in pairs(movers) do
        root.PlaceFrame(key)
    end
    if root.unlocked then
        for _, m in pairs(movers) do
            root.ShowMover(m)
        end
    end
end

-------------------------------------------------------------------------------
-- Welcome window (first login on a paladin)
-------------------------------------------------------------------------------

local welcome

function root.ShowWelcome()
    if not welcome then
        local f = CreateFrame("Frame", "ZyrumisLibramWelcome", UIParent, "BackdropTemplate")
        f:SetSize(440, 300)
        f:SetPoint("CENTER", 0, 80)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        if UISpecialFrames then
            table.insert(UISpecialFrames, "ZyrumisLibramWelcome") -- Esc closes it
        end

        local icon = f:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("TOPLEFT", 24, -24)
        icon:SetTexture(root.ICON)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        title:SetText("Welcome to " .. root.TITLE)
        local sub = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        sub:SetText("Your paladin helper. It works right away, no setup needed.")

        local body = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        body:SetPoint("TOPLEFT", 24, -80)
        body:SetWidth(392)
        body:SetJustifyH("LEFT")
        body:SetSpacing(3)
        body:SetText(
            "|cfff5c542Buff icons|r appear above your character when your aura, your own blessing "
            .. "or a group member's blessing is missing or running low. Click one to cast it.\n\n"
            .. "|cfff5c542One key for all of it:|r bind \"Cast the next buff\" in Options > Keybindings > "
            .. "AddOns and press it until the icons are gone.\n\n"
            .. "|cfff5c542Tank and DPS buttons|r sit above your action bar. Name your gear sets \"Tank\" "
            .. "and \"DPS\" in the character window to swap gear too.\n\n"
            .. "Everything can be moved, switched off or changed in the settings.")

        local open = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        open:SetSize(150, 24)
        open:SetPoint("BOTTOMLEFT", 24, 20)
        open:SetText("Open settings")
        open:SetScript("OnClick", function()
            f:Hide()
            root.OpenOptions()
        end)
        local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        ok:SetSize(110, 24)
        ok:SetPoint("BOTTOMRIGHT", -24, 20)
        ok:SetText("Got it")
        ok:SetScript("OnClick", function() f:Hide() end)
        f:SetScript("OnHide", function()
            if root.db then
                root.db.welcomed = true
            end
        end)
        welcome = f
    end
    welcome:Show()
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("SPELLS_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            if type(ZyrumisLibramDB) ~= "table" then
                ZyrumisLibramDB = {}
            end
            root.db = MergeDefaults(DEFAULTS, ZyrumisLibramDB)
        end
    elseif event == "PLAYER_LOGIN" then
        pcall(root.MainCategory)
        if root.IsPaladin() and not root.db.welcomed then
            C_Timer.After(4, function()
                local ok, err = pcall(root.ShowWelcome)
                if not ok then
                    root.Print("welcome window: " .. tostring(err))
                end
            end)
        end
    elseif event == "SPELLS_CHANGED" then
        root.ForgetBook()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if root.unlocked then
            root.SetUnlocked(false) -- secure frames can't move in a fight
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if openAfterCombat then
            local sub = openAfterCombat
            openAfterCombat = nil
            root.OpenOptions(type(sub) == "string" and sub or nil)
        end
    end
end)

-------------------------------------------------------------------------------
-- /libram
-------------------------------------------------------------------------------

local HELP = {
    "/libram  open the settings",
    "/libram move  unlock the frames to move them (/libram lock to lock)",
    "/libram reset  put every frame back where it started",
    "/libram status  what the buff reminders see right now",
    "/libram healers  why the healer mana warning shows or not",
    "/libram welcome  show the welcome window again",
}

SLASH_ZYRUMISLIBRAM1 = "/libram"
SLASH_ZYRUMISLIBRAM2 = "/zl"
SlashCmdList.ZYRUMISLIBRAM = function(input)
    local cmd = strtrim(input or ""):lower()
    if cmd == "help" or cmd == "?" then
        root.Print("commands:")
        for _, line in ipairs(HELP) do
            root.Print("  " .. line)
        end
    elseif cmd == "move" or cmd == "unlock" then
        root.SetUnlocked(true)
    elseif cmd == "lock" then
        root.SetUnlocked(false)
    elseif cmd == "reset" then
        root.ResetPositions()
    elseif cmd == "status" and root.Blessings then
        root.Blessings.Report()
    elseif cmd == "healers" and root.HealerMana then
        root.HealerMana.Report()
    elseif cmd == "welcome" then
        root.ShowWelcome()
    elseif cmd == "" then
        root.OpenOptions()
    else
        root.Print("unknown command. /libram help lists them.")
    end
end
