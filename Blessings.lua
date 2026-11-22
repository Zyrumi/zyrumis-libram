-- Zyrumi's Libram: blessing, aura and Righteous Fury reminders
-- Out of combat, a row of icons shows what is missing or about to run out:
--   your aura, your own blessing, the next group member's blessing and
--   Righteous Fury (only while you tank). Click an icon to cast it, or press
--   the "Cast the next buff" key until the row is empty.
-- Each group member gets the blessing that suits their class and group role.
-- Right-click a blessing icon to pick another for that person.
-- Nothing is guessed: if the game won't say what someone has, no icon.

local ADDON_NAME, root = ...

local Blessings = {}
root.Blessings = Blessings

local IsSecret, Safe = root.IsSecret, root.Safe

local SIZE, GAP = 36, 8
local TICK = 1
local QUIET_AFTER_LOAD = 3 -- the aura list can be empty right after a loading screen
local SYMBOL_OF_KINGS = 21177

-- Each blessing: rank 1 spell ID and English name, then the greater version.
-- Forever has these three only (no Light, Sanctuary or Salvation). All of
-- them, greater ones too, last an hour there; greater ones still use a
-- Symbol of Kings each.
local BLESSINGS = {
    might = { 19740, "Blessing of Might", 25782, "Greater Blessing of Might" },
    wisdom = { 19742, "Blessing of Wisdom", 25894, "Greater Blessing of Wisdom" },
    kings = { 20217, "Blessing of Kings", 25898, "Greater Blessing of Kings" },
}
Blessings.BLESSINGS = BLESSINGS

-- Forever campfires: sitting at a camp gives one "Camp Benefits" buff with
-- a tooltip line per camp item. Three of them can't stack with a blessing
-- (Fish Bowl / Kings, Mana Well / Wisdom, Lodestone / Might), so the line
-- counts as someone else's blessing of that kind. English text only.
local CAMP_BENEFITS = 1229741
local CAMP_LINES = {
    kings = "all stats increased",
    wisdom = "mana every 5 seconds",
    might = "melee attack power increased",
}
Blessings.CAMP_LINES = CAMP_LINES
-- The order used when stepping through picks with right-click.
local OTHERS_ORDER = { "might", "wisdom", "kings" }
local SELF_ORDER = { "might", "wisdom", "kings" }
Blessings.OTHERS_ORDER = OTHERS_ORDER

-- Forever's auras (no Sanctity or Crusader Aura there).
local AURAS = {
    { 465, "Devotion Aura" }, { 7294, "Retribution Aura" }, { 19746, "Concentration Aura" },
    { 19876, "Shadow Resistance Aura" }, { 19888, "Frost Resistance Aura" }, { 19891, "Fire Resistance Aura" },
}
local RIGHTEOUS_FURY = { 25780, "Righteous Fury" }

-- The reminders, in the order their icons show. off: starts switched off.
local GROUPS = {
    { key = "aura", label = "Your aura",
        tip = "When none of your auras is on. The icon casts the aura you used last." },
    { key = "self", label = "Your own blessing",
        tip = "When your own blessing on yourself is missing or running low." },
    { key = "group", label = "Blessings on your group",
        tip = "One icon for the next group member who needs a blessing (your target when you are not in a group)." },
    { key = "fury", label = "Righteous Fury while tanking",
        tip = "Only while you tank: Tank mode from the Tank / DPS buttons, or the tank group role." },
}
Blessings.GROUPS = GROUPS

-------------------------------------------------------------------------------
-- Which blessing suits whom
-------------------------------------------------------------------------------

-- Might is melee attack power only, so hunters never get it.
local CLASS_DEFAULT = {
    WARRIOR = { "might", "kings" }, ROGUE = { "might", "kings" },
    HUNTER = { "kings", "wisdom" },
    MAGE = { "wisdom", "kings" }, WARLOCK = { "wisdom", "kings" }, PRIEST = { "wisdom", "kings" },
}
-- Druids, shamans and paladins go by their group role.
local ROLE_DEFAULT = { DAMAGER = { "might", "kings" }, HEALER = { "wisdom", "kings" }, TANK = { "kings", "might" } }

-- The classes that can be set on the Blessings settings page, in order.
Blessings.CLASSES = { "WARRIOR", "ROGUE", "HUNTER", "MAGE", "WARLOCK", "PRIEST", "DRUID", "SHAMAN", "PALADIN" }

-- What a class and group role want, best first. Blessings you haven't
-- learned are passed over, so "kings" first means "Kings if you have it".
-- melee: a druid in cat or bear form (when there is no role to go by).
function Blessings.DefaultFor(class, role, melee)
    if role == "TANK" then
        return ROLE_DEFAULT.TANK
    end
    if CLASS_DEFAULT[class] then
        return CLASS_DEFAULT[class]
    end
    if ROLE_DEFAULT[role] then
        return ROLE_DEFAULT[role]
    end
    -- No role: a shaman's or paladin's spec can't be seen from outside.
    return melee and { "kings", "might" } or { "kings", "wisdom" }
end

-- With the player's own choices from the settings page on top.
function Blessings.ListFor(class, role, melee)
    local set = root.db and root.db.blessFor or {}
    local default = Blessings.DefaultFor(class, role, melee)
    local pick = (role == "TANK" and set.TANK) or set[class]
    if pick and BLESSINGS[pick] then
        local list = { pick }
        for _, k in ipairs(default) do
            if k ~= pick then
                list[#list + 1] = k
            end
        end
        return list
    end
    return default
end

-------------------------------------------------------------------------------
-- Reading the game
-------------------------------------------------------------------------------

local function KnownBlessings(book)
    local known, greater = {}, {}
    for key, b in pairs(BLESSINGS) do
        known[key] = root.KnownSpell(b[1], b[2], book)
        greater[key] = root.KnownSpell(b[3], b[4], book)
    end
    return known, greater
end

local function HasSymbols()
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    local n = Safe(count, SYMBOL_OF_KINGS)
    return type(n) == "number" and n > 0
end

-- Your own buffs: [lower case name] = { expires, duration, mine }. nil when
-- the game won't say.
local function PlayerBuffs()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
        return nil
    end
    local ok, result = pcall(function()
        local out = {}
        for i = 1, 40 do
            local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if IsSecret(a) then
                return nil
            end
            if a == nil then
                return out
            end
            local n, exp, dur, src = a.name, a.expirationTime, a.duration, a.sourceUnit
            if IsSecret(n) or IsSecret(exp) or IsSecret(dur) or n == "<restricted>" then
                return nil
            end
            if type(n) == "string" then
                exp, dur = tonumber(exp) or 0, tonumber(dur) or 0
                local mine = not IsSecret(src) and src == "player"
                local key, old = n:lower(), out[n:lower()]
                -- Two of the same (from two people): keep the longer one.
                if not old or old.expires ~= 0 and (exp == 0 or exp > old.expires) then
                    out[key] = { expires = exp, duration = dur, mine = mine or (old and old.mine) or false }
                elseif mine then
                    old.mine = true
                end
            end
        end
        return out
    end)
    if ok then
        return result
    end
    return nil
end

-- Camp Benefits on a unit: { left, lines } (lines false when its tooltip
-- can't be read), false when not there, nil when the game won't say.
-- Tooltips are read again only when the buff changes.
local campCache = {}
local function CampOn(unit)
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return nil
    end
    local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, root.SpellName(CAMP_BENEFITS) or "Camp Benefits", "HELPFUL")
    if not ok or IsSecret(a) then
        return nil
    end
    if type(a) ~= "table" then
        return false
    end
    local id, exp = a.auraInstanceID, a.expirationTime
    if IsSecret(id) or IsSecret(exp) then
        return nil
    end
    exp = tonumber(exp) or 0
    local left = exp == 0 and math.huge or exp - GetTime()
    local cached = campCache[unit]
    if cached and cached.id == id and cached.exp == exp then
        return { left = left, lines = cached.lines }
    end
    local lines = false
    if id and C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID then
        local okT, data = pcall(C_TooltipInfo.GetUnitBuffByAuraInstanceID, unit, id)
        if okT and type(data) == "table" and not IsSecret(data) and type(data.lines) == "table" then
            lines = {}
            for _, line in ipairs(data.lines) do
                local t = line.leftText
                if type(t) == "string" and not IsSecret(t) then
                    lines[#lines + 1] = t:lower()
                end
            end
            if #lines == 0 then
                lines = false
            end
        end
    end
    campCache[unit] = { id = id, exp = exp, lines = lines }
    return { left = left, lines = lines }
end

-- Does the camp on a unit stand in for this blessing? Time left, or nil.
-- A tooltip that can't be read counts (better quiet than asking for a
-- blessing that won't stick).
local function CampBlessing(unit, key)
    local want = CAMP_LINES[key]
    local camp = want and CampOn(unit)
    if not camp then
        return nil
    end
    if not camp.lines then
        return camp.left
    end
    for _, t in ipairs(camp.lines) do
        if t:find(want, 1, true) then
            return camp.left
        end
    end
    return nil
end
Blessings.CampBlessing = CampBlessing

-- A blessing (or its greater version) on a unit: { left, mine } or false
-- when it isn't there; nil when the game won't say. A camp item that
-- stands in for it counts as someone else's (camp = true).
local function BlessingOn(unit, key)
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return nil
    end
    local b = BLESSINGS[key]
    for _, s in ipairs({ { b[1], b[2] }, { b[3], b[4] } }) do
        local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, root.SpellName(s[1]) or s[2], "HELPFUL")
        if not ok or IsSecret(a) then
            return nil
        end
        if type(a) == "table" then
            -- Only the caster says whose it is.
            local exp, src = a.expirationTime, a.sourceUnit
            if IsSecret(exp) or IsSecret(src) then
                return nil
            end
            local mine = type(src) == "string" and Safe(UnitIsUnit, src, "player") or false
            exp = tonumber(exp) or 0
            return { left = exp == 0 and math.huge or exp - GetTime(), mine = mine and true or false }
        end
    end
    local campLeft = CampBlessing(unit, key)
    if campLeft then
        return { left = campLeft, mine = false, camp = true }
    end
    return false
end

local function RefreshAt()
    return (root.db and root.db.refreshMinutes or 3) * 60
end

-- "Runs out soon" for buffs without a setting: the last tenth, 30 s to 5 min.
local function WarnAt(duration)
    return math.max(30, math.min(300, duration * 0.1))
end

-- True while you tank: Tank mode on the Tank / DPS buttons, else the tank role.
function Blessings.Tanking()
    if root.TankMode and root.FeatureOn("tank") then
        local v = root.TankMode.IsTank()
        if v ~= nil then
            return v
        end
    end
    return Safe(UnitGroupRolesAssigned, "player") == "TANK"
end

-------------------------------------------------------------------------------
-- Each reminder's state
-------------------------------------------------------------------------------
-- state: "ok", "missing", "soon", "unknown", "unlearned" or "off"
-- cast: spell to cast; unit: who on; name: what is (or was) there; left: time
-- who: the person's name (group); more: how many after them

local function ReminderOn(g, c)
    c = c or root.CharData()
    local v = c and c.on[g.key]
    if v == nil then
        return not g.off
    end
    return v == true
end
Blessings.ReminderOn = ReminderOn

local function SetReminder(key, on)
    local c = root.CharData()
    if c then
        c.on[key] = on and true or false
    end
    Blessings.Update()
end
Blessings.SetReminder = SetReminder

-- A plain "one of these buffs on you" reminder (aura, Righteous Fury).
local function SelfBuffState(spells, buffs, c, rememberKey)
    local book = root.Book()
    local known, knownList = {}, {}
    for _, s in ipairs(spells) do
        local n = root.KnownSpell(s[1], s[2], book)
        if n and not known[n:lower()] then
            known[n:lower()] = n
            knownList[#knownList + 1] = n
        end
    end
    if #knownList == 0 then
        return { state = "unlearned" }
    end
    if not buffs then
        return { state = "unknown" }
    end
    for _, n in ipairs(knownList) do
        local b = buffs[n:lower()]
        if b then
            -- Remember only what you cast yourself (not another paladin's aura).
            if b.mine and c and rememberKey then
                c.last[rememberKey] = n
            end
            if b.expires ~= 0 and b.duration >= 60 then
                local left = b.expires - GetTime()
                if left <= WarnAt(b.duration) then
                    return { state = "soon", left = left, name = n, cast = n, unit = "player" }
                end
            end
            return { state = "ok", name = n }
        end
    end
    local last = c and rememberKey and type(c.last[rememberKey]) == "string" and known[c.last[rememberKey]:lower()]
    local cast = last or knownList[1]
    return { state = "missing", cast = cast, name = cast, unit = "player" }
end

-- Your own blessing on yourself.
local function SelfBlessingState(buffs, c)
    local known = KnownBlessings(root.Book())
    if not next(known) then
        return { state = "unlearned" }
    end
    if not buffs then
        return { state = "unknown" }
    end
    -- Remember the blessing you last put on yourself (yours only: another
    -- paladin's blessing is their pick, not yours).
    for key, b in pairs(BLESSINGS) do
        local a = buffs[(root.SpellName(b[1]) or b[2]):lower()]
        if a and a.mine and known[key] and c then
            c.last.self = key
        end
    end
    -- What to cast: your pick, else the last one you put on yourself, else
    -- what your role suits.
    local pick = c and c.selfPick
    local castKey = pick and known[pick] and pick
    if not castKey and c and known[c.last.self] then
        castKey = c.last.self
    end
    if not castKey then
        local role = Safe(UnitGroupRolesAssigned, "player")
        if (role == nil or role == "NONE") and Blessings.Tanking() then
            role = "TANK"
        end
        for _, key in ipairs(Blessings.ListFor("PALADIN", role)) do
            if known[key] then
                castKey = key
                break
            end
        end
        if not castKey then
            for _, key in ipairs(SELF_ORDER) do
                if known[key] then
                    castKey = key
                    break
                end
            end
        end
    end
    local cast = known[castKey]
    -- Counts: any blessing you cast on yourself, or the one you want from
    -- someone else (yours would only replace it). Another paladin's other
    -- blessing doesn't: yours goes on top of it.
    local best, bestName
    for key, b in pairs(BLESSINGS) do
        for _, s in ipairs({ { b[1], b[2] }, { b[3], b[4] } }) do
            local n = root.SpellName(s[1]) or s[2]
            local a = buffs[n:lower()]
            if a and (a.mine or key == castKey) then
                local left = a.expires == 0 and math.huge or a.expires - GetTime()
                if not best or left > best then
                    best, bestName = left, n
                end
            end
        end
    end
    -- A camp item that can't stack with the blessing you want counts too.
    local campLeft = castKey and CampBlessing("player", castKey)
    if campLeft and (not best or campLeft > best) then
        best, bestName = campLeft, "Camp Benefits"
    end
    if best then
        if best <= RefreshAt() then
            return { state = "soon", left = best, name = bestName, cast = cast, unit = "player", picked = pick ~= nil }
        end
        return { state = "ok", left = best, name = bestName }
    end
    return { state = "missing", cast = cast, name = cast, unit = "player", picked = pick ~= nil }
end

-- Who to look at: the others in your group, else a friendly player you
-- have targeted.
local function GroupUnits()
    local list = {}
    if Safe(IsInRaid) then
        for i = 1, 40 do
            local u = "raid" .. i
            if Safe(UnitExists, u) and not Safe(UnitIsUnit, u, "player") then
                list[#list + 1] = u
            end
        end
    elseif Safe(IsInGroup) then
        for i = 1, 4 do
            if Safe(UnitExists, "party" .. i) then
                list[#list + 1] = "party" .. i
            end
        end
    elseif Safe(UnitExists, "target") and Safe(UnitIsPlayer, "target") and Safe(UnitIsFriend, "player", "target")
        and not Safe(UnitIsUnit, "target", "player") then
        list[1] = "target"
    end
    return list
end

-- Can a blessing reach them right now?
local function Reachable(unit, spell)
    if not Safe(UnitIsConnected, unit) or Safe(UnitIsDeadOrGhost, unit) or not Safe(UnitIsVisible, unit) then
        return false
    end
    if C_Spell and C_Spell.IsSpellInRange then
        local inRange = Safe(C_Spell.IsSpellInRange, spell, unit)
        if inRange == false then
            return false
        end
        if inRange == true then
            return true
        end
    end
    if type(UnitInRange) == "function" then
        local inRange, checked = Safe(UnitInRange, unit)
        if checked and not inRange then
            return false
        end
    end
    return true
end

local function FullUnitName(unit)
    local name, realm = Safe(UnitName, unit)
    if type(name) ~= "string" then
        return nil
    end
    if type(realm) == "string" and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

local function ShortUnitName(unit)
    local name = Safe(UnitName, unit)
    return type(name) == "string" and name or nil
end

local function PickFor(unit)
    local c, name = root.CharData(), FullUnitName(unit)
    local p = c and name and c.picks[name]
    return BLESSINGS[p] and p or nil
end

-- Greater blessings: allowed here, and you carry Symbols of Kings.
local function UseGreater()
    local mode = root.db and root.db.greater or "raid"
    if mode == "never" then
        return false
    end
    if mode == "raid" and not Safe(IsInRaid) then
        return false
    end
    if mode == "group" and not (Safe(IsInGroup) or Safe(IsInRaid)) then
        return false
    end
    return HasSymbols()
end

-- For one unit: what to cast and how it stands, or nil (nothing to do or
-- the game won't say). A blessing another paladin gave them is skipped for
-- the next one on their list.
local function UnitBlessing(unit, known, greater, useGreater)
    local _, class = Safe(UnitClass, unit)
    local role = Safe(UnitGroupRolesAssigned, unit)
    local power = Safe(UnitPowerType, unit)
    local melee = class == "DRUID" and (power == 1 or power == 3) -- rage or energy: bear or cat
    local pick = PickFor(unit)
    -- You can keep one blessing on each person: if yours is on them, they
    -- are done (until it fades), unless you picked another one for them.
    local mineKey, mineLeft
    for key in pairs(BLESSINGS) do
        local on = BlessingOn(unit, key)
        if on == nil then
            return nil
        end
        if on and on.mine then
            mineKey, mineLeft = key, on.left
        end
    end
    if mineKey and known[mineKey] and (not pick or pick == mineKey) then
        local cast = useGreater and greater[mineKey] or known[mineKey]
        if mineLeft <= RefreshAt() then
            return cast, "soon", mineLeft, class
        end
        return cast, "ok", nil, class
    end
    local list = pick and known[pick] and { pick } or Blessings.ListFor(class, role, melee)
    for _, key in ipairs(list) do
        local cast = known[key]
        if cast then
            if useGreater and greater[key] then
                cast = greater[key]
            end
            local on = BlessingOn(unit, key)
            if on == nil then
                return nil
            end
            if not on then
                return cast, "missing", nil, class
            end
            if on.mine then
                if on.left <= RefreshAt() then
                    return cast, "soon", on.left, class
                end
                return cast, "ok", nil, class
            end
            -- someone else's: try the next one
        end
    end
    return nil
end

local CLASS_NAMES = (LOCALIZED_CLASS_NAMES_MALE) or {}

local function GroupState()
    -- Raids are PallyPower's: it shares out blessings between all paladins.
    if Safe(IsInRaid) and root.AddonLoaded("PallyPower") then
        return { state = "ok", pallyPower = true }
    end
    local known, greater = KnownBlessings(root.Book())
    if not next(known) then
        return { state = "unlearned" }
    end
    local useGreater = UseGreater()
    local isGreater = {}
    for _, n in pairs(greater) do
        isGreater[n] = true
    end
    local first, waiting = nil, 0
    local coveredClass = {} -- one greater blessing covers the whole class
    for _, unit in ipairs(GroupUnits()) do
        local cast, state, left, class = UnitBlessing(unit, known, greater, useGreater)
        if cast and state ~= "ok" and Reachable(unit, cast) then
            local g = isGreater[cast] and class
            if not (g and coveredClass[class]) then
                waiting = waiting + 1
                if g then
                    coveredClass[class] = true
                end
                if not first then
                    first = { state = state, cast = cast, name = cast, unit = unit, left = left,
                        who = ShortUnitName(unit) or unit, picked = PickFor(unit) ~= nil,
                        greater = g and true or false, className = class and (CLASS_NAMES[class] or class) }
                end
            end
        end
    end
    if not first then
        return { state = "ok" }
    end
    first.more = waiting - 1
    return first
end
Blessings.GroupState = GroupState

function Blessings.State(g, buffs, c)
    if g.key == "aura" then
        return SelfBuffState(AURAS, buffs, c, "aura")
    elseif g.key == "self" then
        return SelfBlessingState(buffs, c)
    elseif g.key == "group" then
        return GroupState()
    elseif g.key == "fury" then
        if not Blessings.Tanking() then
            return { state = "off" }
        end
        return SelfBuffState({ RIGHTEOUS_FURY }, buffs, c)
    end
    return { state = "unknown" }
end

-- Right-click: the next blessing for that person (or yourself), then back
-- to automatic. Returns the new pick (nil = automatic).
function Blessings.CyclePick(item)
    local c = root.CharData()
    if not c or not item then
        return nil
    end
    local known = KnownBlessings(root.Book())
    local order = item.group.key == "self" and SELF_ORDER or OTHERS_ORDER
    local cycle = {}
    for _, key in ipairs(order) do
        if known[key] then
            cycle[#cycle + 1] = key
        end
    end
    local current, name
    if item.group.key == "self" then
        current = c.selfPick
    else
        name = item.st.unit and FullUnitName(item.st.unit)
        if not name then
            return nil
        end
        current = c.picks[name]
    end
    local nextKey = cycle[1]
    if current then
        nextKey = nil -- after the last one: automatic again
        for i, key in ipairs(cycle) do
            if key == current then
                nextKey = cycle[i + 1]
            end
        end
    end
    if item.group.key == "self" then
        c.selfPick = nextKey
        root.Print(("your own blessing: %s from now on."):format(nextKey and known[nextKey] or "automatic"))
    else
        c.picks[name] = nextKey
        root.Print(("%s: %s from now on."):format(item.st.who or name, nextKey and known[nextKey] or "automatic"))
    end
    return nextKey
end

-- True when reminders make no sense right now.
local quietUntil = 0
local function Busy()
    if InCombatLockdown() or Safe(UnitIsDeadOrGhost, "player") or Safe(UnitOnTaxi, "player")
        or Safe(UnitInVehicle, "player") or Safe(UnitHasVehicleUI, "player") then
        return true
    end
    if root.db and root.db.hideMounted ~= false and Safe(IsMounted) then
        return true
    end
    return GetTime() < quietUntil
end

-- What needs a reminder right now: list of { group, st }.
function Blessings.Needed()
    local c = root.CharData()
    if not c then
        return {}
    end
    local buffs = PlayerBuffs()
    local out = {}
    for _, g in ipairs(GROUPS) do
        if ReminderOn(g, c) then
            local st = Blessings.State(g, buffs, c)
            if st.state == "missing" or st.state == "soon" then
                out[#out + 1] = { group = g, st = st }
            end
        end
    end
    return out
end

-------------------------------------------------------------------------------
-- The icons
-------------------------------------------------------------------------------

local container, nextButton
local buttons = {}
local needsLayout = false
local ticking = false

local function ShowTooltip(self)
    local item = self.item
    if not item then
        return
    end
    local st = item.st
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(st.cast or item.group.label, 1, 1, 1)
    if st.who then
        local whom = st.greater and st.className and ("every " .. st.className .. " (with " .. st.who .. ")") or st.who
        GameTooltip:AddLine(("For %s%s."):format(whom,
            st.state == "soon" and (", runs out in " .. root.Clock(st.left)) or ""), nil, nil, nil, true)
        if (st.more or 0) > 0 then
            GameTooltip:AddLine(("%d more after them."):format(st.more), nil, nil, nil, true)
        end
        GameTooltip:AddLine(st.picked and "Your pick for them. Right-click for another, or back to automatic."
            or "Picked by their class and role. Right-click to pick another for them.", 0.8, 0.8, 0.8, true)
    elseif st.state == "soon" then
        GameTooltip:AddLine((st.name or st.cast) .. " runs out in " .. root.Clock(st.left) .. ".", nil, nil, nil, true)
    else
        GameTooltip:AddLine("Not on you.", nil, nil, nil, true)
    end
    if item.group.key == "self" then
        GameTooltip:AddLine(st.picked and "Your pick. Right-click for another, or back to automatic."
            or "Right-click to pick which blessing you want on yourself.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:AddLine("Click to cast it.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

local function CreateButton(i)
    local b = CreateFrame("Button", "ZyrumisLibramBuff" .. i, container, "SecureActionButtonTemplate")
    b:SetSize(SIZE, SIZE)
    -- Both halves of a click: the game casts on the press when "cast on key
    -- down" is on and on the release when it is off.
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("checkselfcast", false)
    b:SetAttribute("checkfocuscast", false)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("CENTER")
    border:SetSize(SIZE * 1.85, SIZE * 1.85)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    -- Always a word or a time under the icon, never colour alone.
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("TOP", b, "BOTTOM", 0, -2)

    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:HookScript("PostClick", function(self, mouse, down)
        local item = self.item
        if down or not item or InCombatLockdown() then
            return
        end
        if mouse == "RightButton" and (item.group.key == "group" or item.group.key == "self") then
            Blessings.CyclePick(item)
            Blessings.Update()
        end
    end)
    buttons[i] = b
    return b
end

-- "Cast the next buff" key: a hidden button that casts the first icon.
local function CreateNextButton()
    nextButton = CreateFrame("Button", "ZyrumisLibramNextBuff", UIParent, "SecureActionButtonTemplate")
    nextButton:RegisterForClicks("AnyUp", "AnyDown")
    nextButton:SetAttribute("checkselfcast", false)
    nextButton:SetAttribute("checkfocuscast", false)
    nextButton:HookScript("PostClick", function(self, _, down)
        if down then
            return
        end
        if not self:GetAttribute("macrotext") or self:GetAttribute("macrotext") == "" then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(InCombatLockdown() and "Zyrumi's Libram: buffs wait until the fight is over"
                    or "Zyrumi's Libram: nothing to buff right now", 1, 0.82, 0)
            end
        end
    end)
end

-- The macro the key runs. [nocombat] so a stale one never fires in a fight.
function Blessings.NextMacro(st)
    if not st or not st.cast then
        return ""
    end
    return ("/cast [nocombat,@%s] %s"):format(st.unit or "player", st.cast)
end

local function CreateContainer()
    container = CreateFrame("Frame", "ZyrumisLibramBuffs", UIParent, "SecureHandlerStateTemplate")
    container:SetSize(SIZE, SIZE)
    container:SetClampedToScreen(true)
    -- The game hides it in combat by itself (these buttons cast spells,
    -- which addons may not show or hide during a fight).
    RegisterStateDriver(container, "visibility", "[combat] hide; show")
    root.RegisterMover(container, "buffs", "Buff icons", { "CENTER", UIParent, "CENTER", 0, 150 }, { 140, SIZE })
end

local function HideFrom(first)
    for i = first, #buttons do
        local b = buttons[i]
        if b.item or b.sig then
            b.item, b.sig = nil, nil
            b:SetAttribute("type1", nil)
            b:SetAttribute("spell1", nil)
            b:SetAttribute("unit", nil)
            b:Hide()
        end
    end
end

-- Lays out the icons. Out of combat only: they cast spells.
local function Layout()
    if InCombatLockdown() then
        needsLayout = true
        return
    end
    needsLayout = false
    local on = root.FeatureOn("buffs")
    if not container then
        if not on then
            return
        end
        CreateContainer()
        CreateNextButton()
    end
    local list = (on and not Busy()) and Blessings.Needed() or {}
    local width = math.max(SIZE, #list * SIZE + math.max(0, #list - 1) * GAP)
    if container.width ~= width then
        container.width = width
        container:SetWidth(width)
    end
    for i, item in ipairs(list) do
        local b = buttons[i] or CreateButton(i)
        b.item = item
        local st = item.st
        -- This runs every second: set the button up again only when what it
        -- casts changed. The text under it is all that ticks.
        local sig = item.group.key .. "|" .. tostring(st.cast) .. "|" .. (st.unit or "player")
        if b.sig ~= sig then
            b.sig = sig
            b:SetAttribute("unit", st.unit or "player")
            b:SetAttribute("type1", "spell")
            b:SetAttribute("spell1", st.cast)
            b:SetAttribute("type2", nil) -- right-click picks, it doesn't cast
            b.icon:SetTexture(root.SpellIcon(st.cast))
            b:ClearAllPoints()
            b:SetPoint("LEFT", container, "LEFT", (i - 1) * (SIZE + GAP), 0)
            b:Show()
        elseif b.icon:GetTexture() == "Interface\\Icons\\INV_Misc_QuestionMark" then
            b.icon:SetTexture(root.SpellIcon(st.cast)) -- missing right after login
        end
        if st.who then
            b.label:SetText(st.greater and st.className or st.who:sub(1, 12))
        else
            b.label:SetText(st.state == "soon" and root.Clock(st.left) or "missing")
        end
    end
    HideFrom(#list + 1)
    local macro = Blessings.NextMacro(list[1] and list[1].st)
    if nextButton:GetAttribute("macrotext") ~= macro then
        nextButton:SetAttribute("type", macro ~= "" and "macro" or nil)
        nextButton:SetAttribute("macrotext", macro)
    end
end

function Blessings.Update()
    local ok, err = pcall(Layout)
    if not ok and not Blessings.warned then
        Blessings.warned = true
        root.Print("buff icons: " .. tostring(err))
    end
end

-- Once a second while on: counts down, and catches buffs running out.
local function Tick()
    if not root.FeatureOn("buffs") then
        ticking = false
        Blessings.Update()
        return
    end
    if not InCombatLockdown() then
        Blessings.Update()
    end
    C_Timer.After(TICK, Tick)
end

local function StartTicking()
    if not ticking and root.FeatureOn("buffs") then
        ticking = true
        C_Timer.After(TICK, Tick)
    end
end

root.OnFeatureChanged("buffs", function(on)
    Blessings.Update()
    if on then
        StartTicking()
    end
end)

-------------------------------------------------------------------------------
-- /libram status
-------------------------------------------------------------------------------

function Blessings.Report()
    if not root.IsPaladin() then
        root.Print("only does something on a paladin.")
        return
    end
    local c = root.CharData()
    local buffs = PlayerBuffs()
    root.Print("buff reminders right now:")
    if not root.FeatureOn("buffs") then
        root.Print("  (switched off in the settings)")
    end
    if not buffs then
        root.Print("  (the game won't say what buffs you have right now)")
    end
    for _, g in ipairs(GROUPS) do
        local st = Blessings.State(g, buffs, c)
        local text
        if not ReminderOn(g, c) then
            text = "switched off"
        elseif st.state == "unlearned" then
            text = "not learned yet"
        elseif st.state == "off" then
            text = "not tanking right now"
        elseif st.state == "unknown" then
            text = "can't tell right now"
        elseif st.state == "missing" then
            text = "missing, a click casts " .. tostring(st.cast) .. (st.who and (" on " .. st.who) or "")
        elseif st.state == "soon" then
            text = tostring(st.name) .. (st.who and (" on " .. st.who) or "") .. " runs out in " .. root.Clock(st.left)
        elseif g.key == "group" then
            text = st.pallyPower and "left to PallyPower in raids" or "ok, everyone in reach has theirs"
        else
            text = "ok: " .. tostring(st.name) .. (st.left and st.left ~= math.huge and (", " .. root.Clock(st.left) .. " left") or "")
        end
        root.Print("  " .. g.label .. ": " .. text)
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")

local updateQueued = false
local function QueueUpdate()
    if not updateQueued then
        updateQueued = true
        C_Timer.After(0.2, function()
            updateQueued = false
            Blessings.Update()
        end)
    end
end

events:SetScript("OnEvent", function(_, event)
    if not root.db then
        return
    end
    if event == "PLAYER_LOGIN" then
        StartTicking()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        quietUntil = GetTime() + QUIET_AFTER_LOAD
        C_Timer.After(QUIET_AFTER_LOAD + 0.1, function() Blessings.Update() end)
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and needsLayout then
        Blessings.Update()
        return
    end
    if root.FeatureOn("buffs") then
        QueueUpdate()
    end
end)
