-- Zyrumi's Libram: minimap button and the minimap's addon menu
--   Left-click:  settings
--   Right-click: unlock or lock the frames
--   Drag:        move the button around the minimap's edge
-- The button can be hidden on the settings page; the entry in the minimap's
-- addon menu (the TOC's AddonCompartmentFunc) is always there.

local ADDON_NAME, root = ...

local MinimapButton = {}
root.MinimapButton = MinimapButton

local GAP = 5 -- how far outside the minimap's edge
local button

local function Settings()
    return root.db.minimap
end

-- x, y from the minimap's center for an angle in degrees.
function MinimapButton.Offset(angle, radius)
    local r = math.rad(angle)
    return math.cos(r) * radius, math.sin(r) * radius
end

-- Angle in degrees (0..360) of a point seen from the minimap's center.
function MinimapButton.Angle(dx, dy)
    local a = math.deg(math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx))
    if a < 0 then
        a = a + 360
    end
    return a
end

local function Place()
    if not button then
        return
    end
    local radius = (Minimap:GetWidth() or 140) / 2 + GAP
    local x, y = MinimapButton.Offset(Settings().angle or 210, radius)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale() or 1
    if not (mx and my and cx and cy) then
        return
    end
    Settings().angle = MinimapButton.Angle(cx / scale - mx, cy / scale - my)
    Place()
end

local function Click(mouse)
    if mouse == "RightButton" then
        root.SetUnlocked(not root.unlocked)
    else
        root.OpenOptions()
    end
end

local function Tooltip(owner, anchor)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_LEFT")
    GameTooltip:SetText(root.TITLE, 1, 1, 1)
    if not root.IsPaladin() then
        GameTooltip:AddLine("Only does something on a paladin.", 1, 0.5, 0.5, true)
    end
    GameTooltip:AddLine("Click: settings", nil, nil, nil, true)
    GameTooltip:AddLine(root.unlocked and "Right-click: lock the frames" or "Right-click: move the frames", nil, nil, nil, true)
    GameTooltip:Show()
end

local function Create()
    button = CreateFrame("Button", "ZyrumisLibramMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(22, 22)
    bg:SetPoint("CENTER", 0, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(root.ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- round it off like other minimap buttons
    if icon.SetMask then
        pcall(icon.SetMask, icon, "Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse) Click(mouse) end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self) Tooltip(self) end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MinimapButton.Refresh()
    if not Minimap or not root.db then
        return
    end
    if Settings().hide then
        if button then
            button:Hide()
        end
        return
    end
    if not button then
        Create()
    end
    Place()
    button:Show()
end

function MinimapButton.IsShown()
    return root.db and not Settings().hide
end

function MinimapButton.SetShown(on)
    Settings().hide = not on
    MinimapButton.Refresh()
end

-- The minimap's addon menu calls these by name (see the .toc file).
function ZyrumisLibram_OnAddonCompartmentClick(_, mouse)
    Click(mouse)
end

function ZyrumisLibram_OnAddonCompartmentEnter(_, menuButton)
    Tooltip(menuButton, "ANCHOR_LEFT")
end

function ZyrumisLibram_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    local ok, err = pcall(MinimapButton.Refresh)
    if not ok then
        root.Print("minimap button: " .. tostring(err))
    end
end)
