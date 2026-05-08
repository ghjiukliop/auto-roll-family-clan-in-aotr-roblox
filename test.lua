-- === CONFIGURATION ===
-- Các biến có thể được set từ global scope (_G), hoặc sử dụng default values
local SLOT = _G.SLOT or "A"
local WEBHOOK_URL = _G.WEBHOOK_URL or ""
local TARGET_CLANS = _G.TARGET_CLANS or {"Fritz", "Helos"}
local DELAY_BETWEEN_ROLLS = _G.DELAY_BETWEEN_ROLLS or 0.5 -- Thời gian chờ giữa mỗi lần roll (giây)

-- === SERVICES ===
local player = game:GetService("Players").LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")

-- === HELPER FUNCTIONS ===

-- Kiểm tra object có visible không (kiểm tra cả ancestors)
local function isVisible(obj)
    if not obj or not obj:IsA("GuiObject") then return false end
    
    local current = obj
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        if current:IsA("ScrollingFrame") or current:IsA("TextBox") or current:IsA("TextButton") then
            if current.Active == false then return false end
        end
        current = current.Parent
    end
    
    -- Kiểm tra ScreenGui
    local screenGui = obj:FindFirstAncestorOfClass("ScreenGui")
    if screenGui and not screenGui.Enabled then return false end
    
    -- Kiểm tra size hợp lệ
    return obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end

-- Click thông thường (đơn giản)
local function click(obj)
    if obj and isVisible(obj) then
        local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
        local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + 58 -- Offset cho Roblox Topbar
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

-- Smart Click với retry mechanism
local function smartClick(obj, maxRetries, delayBetweenRetries)
    maxRetries = maxRetries or 5
    delayBetweenRetries = delayBetweenRetries or 0.3
    
    for attempt = 1, maxRetries do
        if click(obj) then
            print("✅ SmartClick thành công (lần " .. attempt .. ")")
            return true
        end
        
        print("⏳ SmartClick lần " .. attempt .. " thất bại, thử lại...")
        task.wait(delayBetweenRetries)
    end
    
    print("❌ SmartClick thất bại sau " .. maxRetries .. " lần thử")
    return false
end

-- Đợi object visible với timeout
local function waitForElementVisible(obj, maxWaitTime)
    maxWaitTime = maxWaitTime or 10
    local startTime = tick()
    
    while tick() - startTime < maxWaitTime do
        if obj and isVisible(obj) then
            print("✅ Element visible")
            return obj
        end
        task.wait(0.2)
    end
    
    print("❌ Timeout: Element không visible sau " .. maxWaitTime .. "s")
    return nil
end

-- Lấy element từ path và đợi visible
local function waitAndGetElement(parent, pathArray, maxWaitTime)
    maxWaitTime = maxWaitTime or 10
    local startTime = tick()
    local current = parent
    
    -- Lấy element từ path
    for _, name in ipairs(pathArray) do
        local childWaitTime = maxWaitTime - (tick() - startTime)
        if childWaitTime <= 0 then
            print("❌ Timeout: Không tìm thấy " .. name)
            return nil
        end
        
        current = current:WaitForChild(name, childWaitTime)
        if not current then
            print("❌ Timeout: Không tìm thấy " .. name)
            return nil
        end
    end
    
    -- Đợi element visible
    return waitForElementVisible(current, maxWaitTime - (tick() - startTime))
end

-- Click element từ path với retry
local function clickWithRetry(parent, pathArray, maxWaitTime, maxRetries, delayBetweenRetries)
    maxWaitTime = maxWaitTime or 10
    maxRetries = maxRetries or 3
    delayBetweenRetries = delayBetweenRetries or 0.5
    
    print("🔍 Đang tìm element từ path...")
    local element = waitAndGetElement(parent, pathArray, maxWaitTime)
    
    if not element then
        print("❌ Không tìm thấy element")
        return false
    end
    
    print("🖱️ Đang click element...")
    return smartClick(element, maxRetries, delayBetweenRetries)
end

local function sendWebhook(clanFound, rollsLeft)
    -- Kiểm tra webhook URL có hợp lệ không
    if not WEBHOOK_URL or WEBHOOK_URL == "" then
        print("⚠️ Webhook URL chưa được cấu hình!")
        return
    end
    
    local data = {
        ["content"] = "🎉 **Auto Roll Success!**",
        ["embeds"] = {{
            ["title"] = "Clan Found: " .. clanFound,
            ["description"] = "Slot: " .. SLOT .. "\nRemaining Rolls: " .. rollsLeft,
            ["color"] = 65280 -- Green
        }}
    }
    pcall(function()
        http:PostAsync(WEBHOOK_URL, http:JSONEncode(data))
    end)
end

local function getCleanClanName(text)
    -- Xóa phần (Common), (Rare),... và khoảng trắng dư thừa
    local name = text:gsub("%s*%b()", ""):upper():gsub("%s+", "")
    return name
end

-- === MAIN WORKFLOW ===
print("🚀 Bắt đầu Auto Roll Script")

-- 1. Chọn Slot
print("--- Bước 1: Chọn Slot " .. SLOT .. " ---")
local slotPath = {"Interface", "Title_Screen", "Slots", SLOT, "Select_" .. SLOT}
if not clickWithRetry(pGui, slotPath, 15, 3, 0.5) then
    warn("❌ Không thể click Slot " .. SLOT)
    return
end
task.wait(1.5)

-- 2. Click Customisation
print("--- Bước 2: Click Customisation ---")
if not clickWithRetry(pGui, {"Interface", "Title_Screen", "Buttons", "Customisation"}, 15, 3, 0.5) then
    warn("❌ Không thể click Customisation")
    return
end
task.wait(1)

-- 3. Click Family tab
print("--- Bước 3: Click Family Tab ---")
if not clickWithRetry(pGui, {"Interface", "Customisation", "Family"}, 15, 3, 0.5) then
    warn("❌ Không thể click Family Tab")
    return
end
task.wait(1)

-- 4. Lấy references cho Roll button và Family name
print("--- Bước 4: Lấy elements cho Roll Loop ---")
local rollElement = waitAndGetElement(pGui, {"Interface", "Customisation", "Family", "Buttons_2", "Roll"}, 10)
local rollTitle = rollElement and rollElement:FindFirstChild("Title")
local familyElement = waitAndGetElement(pGui, {"Interface", "Customisation", "Family", "Family"}, 10)
local familyTitle = familyElement and familyElement:FindFirstChild("Title")

if not rollTitle or not familyTitle then
    warn("❌ Không tìm thấy Roll hoặc Family elements")
    return
end

print("--- Bước 5: Bắt đầu Roll Loop ---")

-- Roll Loop với Event-driven polling
local rollAttempt = 0
local maxRollAttempts = 500
local lastFamilyName = ""
local pollInterval = 0.15 -- Interval check UI (không cố định, tối ưu)

while rollAttempt < maxRollAttempts do
    -- Kiểm tra hiện trạng UI
    if not isVisible(rollTitle) or not isVisible(familyTitle) then
        print("⚠️ Roll elements không còn visible, dừng")
        break
    end
    
    -- Lấy text hiện tại
    local currentText = familyTitle.Text or "" -- Ví dụ: "FRITZ (Rare)"
    local rollsText = rollTitle.Text or "" -- Ví dụ: "ROLL (3,967)"
    
    -- Parse clan name (xóa rarity)
    local clanName = getCleanClanName(currentText)
    local rollsRemaining = rollsText:match("%(([%d,]+)%)") or "0"
    
    -- Chỉ log khi family thay đổi (tối ưu console spam)
    if clanName ~= lastFamilyName then
        print("👨‍👩‍👧 Family: " .. clanName .. " | Rolls: " .. rollsRemaining .. " | Attempt: " .. rollAttempt)
        lastFamilyName = clanName
    end
    
    -- Kiểm tra xem có trùng target clan không
    local found = false
    for _, target in ipairs(TARGET_CLANS) do
        if clanName == target:upper() then
            found = true
            break
        end
    end
    
    if found then
        print("🎉 🎉 ĐÃ TÌM THẤY CLAN: " .. clanName .. " 🎉 🎉")
        sendWebhook(clanName, rollsRemaining)
        break
    end
    
    -- Kiểm tra hết roll
    if rollsRemaining == "0" then
        warn("⚠️ ⚠️ ĐÃ HẾT LƯỢT ROLL ⚠️ ⚠️")
        break
    end
    
    -- Smart Click Roll button
    if isVisible(rollElement) then
        smartClick(rollElement, 2, 0.2) -- 2 retries nếu click thất bại
        rollAttempt = rollAttempt + 1
        
        -- Polling thông minh: đợi theo delay config
        task.wait(DELAY_BETWEEN_ROLLS)
    else
        print("⚠️ Roll element không visible, thử lại...")
        task.wait(0.5)
    end
end

if rollAttempt >= maxRollAttempts then
    warn("⚠️ ⚠️ ĐẠT GIỚI HẠN ROLL (" .. maxRollAttempts .. ") ⚠️ ⚠️")
end

print("--- Script kết thúc ---")
print("📊 Tổng cộng: " .. rollAttempt .. " lần roll")  

