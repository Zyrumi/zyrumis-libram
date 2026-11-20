-- Zyrumi's Libram: Symbol of Kings restock
-- Greater blessings use a Symbol of Kings each. When you talk to a vendor
-- who sells them, this buys enough to bring your bags up to the number set
-- on the settings page (0 = never buy). It only ever buys Symbols of Kings,
-- and says in chat how many it bought.

local ADDON_NAME, root = ...

local Reagents = {}
root.Reagents = Reagents

local Safe = root.Safe

local SYMBOL_OF_KINGS = 21177

function Reagents.Have()
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    local n = Safe(count, SYMBOL_OF_KINGS)
    return type(n) == "number" and n or 0
end

-- How many to buy and in which steps: list of counts no bigger than a stack.
function Reagents.Plan(want, have, maxStack)
    local need = math.max(0, (want or 0) - (have or 0))
    local steps = {}
    maxStack = math.max(1, maxStack or 20)
    while need > 0 do
        local n = math.min(need, maxStack)
        steps[#steps + 1] = n
        need = need - n
    end
    return steps
end

local function MerchantIndex()
    local n = Safe(GetMerchantNumItems)
    if type(n) ~= "number" then
        return nil
    end
    for i = 1, n do
        local id = Safe(GetMerchantItemID, i)
        if id == SYMBOL_OF_KINGS then
            return i
        end
    end
    return nil
end

function Reagents.Restock()
    local want = root.db and root.db.restock or 0
    if want <= 0 or not root.IsPaladin() then
        return
    end
    local index = MerchantIndex()
    if not index then
        return
    end
    local have = Reagents.Have()
    -- Never more than you can pay for.
    local ok, _, _, price, quantity = pcall(GetMerchantItemInfo, index)
    local money = Safe(GetMoney)
    if ok and type(price) == "number" and price > 0 and type(money) == "number" then
        local each = price / math.max(1, tonumber(quantity) or 1)
        want = math.min(want, have + math.floor(money / each))
    end
    local steps = Reagents.Plan(want, have, Safe(GetMerchantItemMaxStack, index))
    local bought = 0
    for _, n in ipairs(steps) do
        local ok = pcall(BuyMerchantItem, index, n)
        if not ok then
            break
        end
        bought = bought + n
    end
    if bought > 0 then
        root.Print(("bought %d Symbol%s of Kings, you now carry %d."):format(bought, bought == 1 and "" or "s", have + bought))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:SetScript("OnEvent", function()
    -- The vendor's list fills a moment after the window opens.
    C_Timer.After(0.5, function()
        local ok, err = pcall(Reagents.Restock)
        if not ok then
            root.Print("restock: " .. tostring(err))
        end
    end)
end)
